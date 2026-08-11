import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_config.dart';
import '../models/child_model.dart';
import '../models/notulen_model.dart';
import '../models/program_model.dart';
import '../models/bunda_model.dart';
import '../models/user_model.dart';
import '../models/log_model.dart';
import 'local_store.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? _client;
  Timer? _autoSyncTimer;

  Future<void> init() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      debugPrint('Supabase Cloud SDK initialized successfully.');

      // Immediate non-blocking cloud fetch & sync queue processing on launch
      unawaited(processAndFetchCloud());

      // Periodic cloud sync & fetch every 5 seconds for real-time parity with web app
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) => processAndFetchCloud());
    } catch (e) {
      debugPrint('Supabase init notice: $e');
      unawaited(processAndFetchCloud());
    }
  }

  SupabaseClient? get client => _client;

  Future<void> processAndFetchCloud() async {
    await processPendingSyncQueue();
    await fetchCloudData();
  }

  // Process offline pending sync items queue
  Future<void> processPendingSyncQueue() async {
    final queue = List<PendingSyncItem>.from(LocalStore.instance.pendingSyncQueue);
    if (queue.isEmpty) return;

    debugPrint('Flushing ${queue.length} pending offline sync items to Supabase Cloud...');

    for (var item in queue) {
      bool success = false;
      if (item.action == 'UPSERT') {
        final onConflict = item.table == 'users' ? 'username' : 'id';
        if (_client != null) {
          try {
            await _client!.from(item.table).upsert(item.payload, onConflict: onConflict);
            success = true;
          } catch (_) {}
        }
        if (!success) {
          success = await _httpUpsertDirect(item.table, item.payload, onConflict);
        }
      } else if (item.action == 'DELETE') {
        final col = item.table == 'users' ? 'username' : 'id';
        if (_client != null) {
          try {
            await _client!.from(item.table).delete().eq(col, item.id);
            success = true;
          } catch (_) {}
        }
        if (!success) {
          success = await _httpDeleteDirect(item.table, item.id, col);
        }
      }

      if (success) {
        LocalStore.instance.removePendingSync(item.id);
      }
    }
  }

  // Direct HTTP REST GET helper for fetching tables from Supabase
  Future<List<dynamic>> _httpGetTable(String table) async {
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/$table?select=*');
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 8);
      final request = await httpClient.getUrl(uri);
      request.headers.set('apikey', AppConfig.supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');

      final response = await request.close();
      if (response.statusCode == 200) {
        final bodyStr = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(bodyStr);
        httpClient.close();
        if (decoded is List) return decoded;
      }
      httpClient.close();
    } catch (e) {
      debugPrint('HTTP GET error for $table: $e');
    }
    return [];
  }

  // Push record addition/update to Supabase Cloud with guaranteed REST fallback
  Future<void> syncToCloud(String table, Map<String, dynamic> payload) async {
    final onConflict = table == 'users' ? 'username' : 'id';

    // 1. Try SDK Upsert
    if (_client != null) {
      try {
        await _client!.from(table).upsert(payload, onConflict: onConflict);
        debugPrint('Cloud SDK sync success for $table');
        unawaited(fetchCloudData());
        return;
      } catch (e) {
        debugPrint('Cloud SDK notice for $table: $e, executing HTTP fallback...');
      }
    }

    // 2. Direct HTTP REST Fallback to Supabase Endpoint
    final success = await _httpUpsertDirect(table, payload, onConflict);
    if (success) {
      final itemId = payload['id']?.toString() ?? payload['username']?.toString() ?? '';
      if (itemId.isNotEmpty) {
        LocalStore.instance.removePendingSync(itemId);
      }
    }
    unawaited(fetchCloudData());
  }

  Future<bool> _httpUpsertDirect(String table, Map<String, dynamic> payload, String onConflict) async {
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/$table?on_conflict=$onConflict');
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 10);
      final request = await httpClient.postUrl(uri);
      request.headers.set('apikey', AppConfig.supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Prefer', 'resolution=merge-duplicates,return=minimal');

      final bodyBytes = utf8.encode(jsonEncode(payload));
      request.headers.set('Content-Length', bodyBytes.length.toString());
      request.add(bodyBytes);

      final response = await request.close();
      final statusCode = response.statusCode;
      debugPrint('Cloud HTTP upsert for $table: status=$statusCode');
      httpClient.close();
      return statusCode < 400;
    } catch (e) {
      debugPrint('Cloud HTTP upsert exception for $table: $e');
    }
    return false;
  }

  // Push record deletion to Supabase Cloud with guaranteed REST fallback
  Future<void> deleteFromCloud(String table, String id) async {
    final col = table == 'users' ? 'username' : 'id';

    if (_client != null) {
      try {
        await _client!.from(table).delete().eq(col, id);
        debugPrint('Cloud SDK delete success for $table: $id');
        unawaited(fetchCloudData());
        return;
      } catch (e) {
        debugPrint('Cloud SDK delete notice for $table: $e');
      }
    }

    final success = await _httpDeleteDirect(table, id, col);
    if (success) {
      LocalStore.instance.removePendingSync(id);
    }
    unawaited(fetchCloudData());
  }

  Future<bool> _httpDeleteDirect(String table, String id, String col) async {
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/$table?$col=eq.$id');
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 10);
      final request = await httpClient.deleteUrl(uri);
      request.headers.set('apikey', AppConfig.supabaseAnonKey);
      request.headers.set('Authorization', 'Bearer ${AppConfig.supabaseAnonKey}');

      final response = await request.close();
      debugPrint('Cloud HTTP delete status for $table: ${response.statusCode}');
      httpClient.close();
      return response.statusCode < 400;
    } catch (e) {
      debugPrint('Cloud HTTP delete notice for $table: $e');
    }
    return false;
  }

  // Sync System Audit Logs to Supabase Cloud
  Future<void> syncLogsToCloud(List<LogModel> logs) async {
    try {
      final payload = {
        'username': 'SYSTEM_AUDIT_TRAIL',
        'password': 'system_logs_store',
        'name': jsonEncode(logs.map((l) => l.toJson()).toList()),
        'role': 'system'
      };
      await syncToCloud('users', payload);
    } catch (e) {
      debugPrint('Notice syncing audit logs to cloud: $e');
    }
  }

  // Fetch all Cloud Tables independently and update Local Store with 100% parity
  Future<void> fetchCloudData() async {
    // 1. Children Table
    try {
      List<dynamic> rawList = [];
      if (_client != null) {
        try {
          final res = await _client!.from('children').select('*');
          if (res is List) rawList = res;
        } catch (_) {}
      }
      if (rawList.isEmpty) {
        rawList = await _httpGetTable('children');
      }

      if (rawList.isNotEmpty) {
        final list = <ChildModel>[];
        for (var item in rawList) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            list.add(ChildModel.fromJson(map));
          } catch (e) {
            debugPrint('Error parsing child row: $e');
          }
        }
        if (list.isNotEmpty) {
          LocalStore.instance.saveCloudChildren(list);
        }
      }
    } catch (e) {
      debugPrint('Notice fetching children: $e');
    }

    // 2. Notulens Table
    try {
      List<dynamic> rawList = [];
      if (_client != null) {
        try {
          final res = await _client!.from('notulens').select('*');
          if (res is List) rawList = res;
        } catch (_) {}
      }
      if (rawList.isEmpty) {
        rawList = await _httpGetTable('notulens');
      }

      if (rawList.isNotEmpty) {
        final list = <NotulenModel>[];
        for (var item in rawList) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            list.add(NotulenModel.fromJson(map));
          } catch (e) {
            debugPrint('Error parsing notulen row: $e');
          }
        }
        if (list.isNotEmpty) {
          LocalStore.instance.saveCloudNotulens(list);
        }
      }
    } catch (e) {
      debugPrint('Notice fetching notulens: $e');
    }

    // 3. Programs Table
    try {
      List<dynamic> rawList = [];
      if (_client != null) {
        try {
          final res = await _client!.from('programs').select('*');
          if (res is List) rawList = res;
        } catch (_) {}
      }
      if (rawList.isEmpty) {
        rawList = await _httpGetTable('programs');
      }

      if (rawList.isNotEmpty) {
        final list = <ProgramModel>[];
        for (var item in rawList) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            list.add(ProgramModel.fromJson(map));
          } catch (e) {
            debugPrint('Error parsing program row: $e');
          }
        }
        if (list.isNotEmpty) {
          LocalStore.instance.saveCloudPrograms(list);
        }
      }
    } catch (e) {
      debugPrint('Notice fetching programs: $e');
    }

    // 4. Bundas Table
    try {
      List<dynamic> rawList = [];
      if (_client != null) {
        try {
          final res = await _client!.from('bundas').select('*');
          if (res is List) rawList = res;
        } catch (_) {}
      }
      if (rawList.isEmpty) {
        rawList = await _httpGetTable('bundas');
      }

      if (rawList.isNotEmpty) {
        final list = <BundaModel>[];
        for (var item in rawList) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            list.add(BundaModel.fromJson(map));
          } catch (e) {
            debugPrint('Error parsing bunda row: $e');
          }
        }
        if (list.isNotEmpty) {
          LocalStore.instance.saveCloudBundas(list);
        }
      }
    } catch (e) {
      debugPrint('Notice fetching bundas: $e');
    }

    // 5. Users & System Audit Logs Table
    try {
      List<dynamic> rawList = [];
      if (_client != null) {
        try {
          final res = await _client!.from('users').select('*');
          if (res is List) rawList = res;
        } catch (_) {}
      }
      if (rawList.isEmpty) {
        rawList = await _httpGetTable('users');
      }

      if (rawList.isNotEmpty) {
        final userList = <UserModel>[];
        for (var item in rawList) {
          try {
            final map = Map<String, dynamic>.from(item as Map);
            final username = map['username']?.toString() ?? '';

            if (username == 'SYSTEM_AUDIT_TRAIL') {
              final nameVal = map['name']?.toString() ?? '';
              if (nameVal.isNotEmpty) {
                try {
                  final decodedLogs = jsonDecode(nameVal);
                  if (decodedLogs is List) {
                    final cloudLogs = <LogModel>[];
                    for (var l in decodedLogs) {
                      if (l is Map) {
                        cloudLogs.add(LogModel.fromJson(Map<String, dynamic>.from(l)));
                      }
                    }
                    if (cloudLogs.isNotEmpty) {
                      LocalStore.instance.saveCloudLogs(cloudLogs);
                    }
                  }
                } catch (e) {
                  debugPrint('Error parsing audit logs: $e');
                }
              }
            } else {
              userList.add(UserModel.fromJson(map));
            }
          } catch (e) {
            debugPrint('Error parsing user row: $e');
          }
        }

        if (userList.isNotEmpty) {
          LocalStore.instance.saveCloudUsers(userList);
        }
      }
    } catch (e) {
      debugPrint('Notice fetching users: $e');
    }
  }
}
