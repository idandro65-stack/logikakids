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

      // On FIRST install, do a BLOCKING fetch so cloud data is ready before UI renders.
      // On subsequent launches, do a non-blocking background fetch.
      if (!LocalStore.instance.cloudDataLoaded) {
        debugPrint('First install detected: performing BLOCKING cloud data fetch...');
        await fetchCloudData();
        debugPrint('BLOCKING cloud fetch complete. All data loaded from Supabase.');
      } else {
        unawaited(fetchCloudData());
      }

      // Periodic cloud fetch every 15 seconds
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) => fetchCloudData());
    } catch (e) {
      debugPrint('Supabase init notice: $e');
    }
  }

  SupabaseClient? get client => _client;

  // Push record addition/update to Supabase Cloud with guaranteed REST fallback
  Future<void> syncToCloud(String table, Map<String, dynamic> payload) async {
    final onConflict = table == 'users' ? 'username' : 'id';

    // 1. Try SDK Upsert
    if (_client != null) {
      try {
        await _client!.from(table).upsert(payload, onConflict: onConflict);
        debugPrint('Cloud SDK sync success for $table');
        return;
      } catch (e) {
        debugPrint('Cloud SDK notice for $table: $e, executing HTTP fallback...');
      }
    }

    // 2. Direct HTTP REST Fallback to Supabase Endpoint
    await _httpUpsert(table, payload, onConflict);
  }

  Future<void> _httpUpsert(String table, Map<String, dynamic> payload, String onConflict) async {
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

      if (statusCode >= 400) {
        final body = await response.transform(utf8.decoder).join();
        debugPrint('Cloud HTTP upsert error body: $body');
      }
      httpClient.close();
    } catch (e) {
      debugPrint('Cloud HTTP upsert exception for $table: $e');
    }
  }

  // Push record deletion to Supabase Cloud with guaranteed REST fallback
  Future<void> deleteFromCloud(String table, String id) async {
    final col = table == 'users' ? 'username' : 'id';

    if (_client != null) {
      try {
        await _client!.from(table).delete().eq(col, id);
        debugPrint('Cloud SDK delete success for $table: $id');
        return;
      } catch (e) {
        debugPrint('Cloud SDK delete notice for $table: $e');
      }
    }

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
    } catch (e) {
      debugPrint('Cloud HTTP delete notice for $table: $e');
    }
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

  // Fetch all Cloud Tables independently and update Local Store
  Future<void> fetchCloudData() async {
    if (_client == null) return;

    bool anySuccess = false;

    // 1. Children Table
    try {
      final resChildren = await _client!.from('children').select('*');
      if (resChildren is List && resChildren.isNotEmpty) {
        final list = resChildren
            .map((e) => ChildModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        LocalStore.instance.mergeCloudChildren(list);
        debugPrint('Fetched ${list.length} children from Supabase Cloud');
        anySuccess = true;
      }
    } catch (e) {
      debugPrint('Notice fetching children: $e');
    }

    // 2. Notulens Table
    try {
      final resNotulens = await _client!.from('notulens').select('*');
      if (resNotulens is List && resNotulens.isNotEmpty) {
        final list = resNotulens
            .map((e) => NotulenModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        LocalStore.instance.mergeCloudNotulens(list);
        debugPrint('Fetched ${list.length} notulens from Supabase Cloud');
        anySuccess = true;
      }
    } catch (e) {
      debugPrint('Notice fetching notulens: $e');
    }

    // 3. Programs Table
    try {
      final resPrograms = await _client!.from('programs').select('*');
      if (resPrograms is List && resPrograms.isNotEmpty) {
        final list = resPrograms
            .map((e) => ProgramModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        LocalStore.instance.mergeCloudPrograms(list);
        debugPrint('Fetched ${list.length} programs from Supabase Cloud');
        anySuccess = true;
      }
    } catch (e) {
      debugPrint('Notice fetching programs: $e');
    }

    // 4. Bundas Table
    try {
      final resBundas = await _client!.from('bundas').select('*');
      if (resBundas is List && resBundas.isNotEmpty) {
        final list = resBundas
            .map((e) => BundaModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        LocalStore.instance.mergeCloudBundas(list);
        debugPrint('Fetched ${list.length} bundas from Supabase Cloud');
        anySuccess = true;
      }
    } catch (e) {
      debugPrint('Notice fetching bundas: $e');
    }

    // 5. Users & System Audit Logs Table
    try {
      final resUsers = await _client!.from('users').select('*');
      if (resUsers is List && resUsers.isNotEmpty) {
        final filteredUsers = resUsers
            .where((u) => u['username'] != 'SYSTEM_AUDIT_TRAIL')
            .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        LocalStore.instance.mergeCloudUsers(filteredUsers);
        debugPrint('Fetched ${filteredUsers.length} users from Supabase Cloud');
        anySuccess = true;
      }
    } catch (e) {
      debugPrint('Notice fetching users: $e');
    }

    // Mark cloud as loaded if at least one table was fetched successfully
    if (anySuccess) {
      LocalStore.instance.markCloudLoaded();
    }
  }
}
