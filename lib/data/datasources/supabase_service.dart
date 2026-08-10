import 'dart:async';
import 'dart:convert';
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

      // Start periodic cloud fetch every 10 seconds
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchCloudData());
      
      // Trigger initial fetch
      fetchCloudData();
    } catch (e) {
      debugPrint('Supabase init notice: $e');
    }
  }

  SupabaseClient? get client => _client;

  // Push record addition/update to Supabase Cloud
  Future<void> syncToCloud(String table, Map<String, dynamic> payload) async {
    if (_client == null) return;
    try {
      final onConflict = table == 'users' ? 'username' : 'id';
      await _client!.from(table).upsert(payload, onConflict: onConflict);
      debugPrint('Cloud sync success for $table');
    } catch (e) {
      debugPrint('Cloud sync notice for $table: $e');
    }
  }

  // Push record deletion to Supabase Cloud
  Future<void> deleteFromCloud(String table, String id) async {
    if (_client == null) return;
    try {
      final col = table == 'users' ? 'username' : 'id';
      await _client!.from(table).delete().eq(col, id);
      debugPrint('Cloud delete success for $table: $id');
    } catch (e) {
      debugPrint('Cloud delete notice for $table: $e');
    }
  }

  // Sync System Audit Logs to Supabase Cloud
  Future<void> syncLogsToCloud(List<LogModel> logs) async {
    if (_client == null) return;
    try {
      final payload = {
        'username': 'SYSTEM_AUDIT_TRAIL',
        'password': 'system_logs_store',
        'name': jsonEncode(logs.map((l) => l.toJson()).toList()),
        'role': 'system'
      };
      await _client!.from('users').upsert(payload, onConflict: 'username');
    } catch (e) {
      debugPrint('Notice syncing audit logs to cloud: $e');
    }
  }

  // Fetch all Cloud Tables and update Local Store
  Future<void> fetchCloudData() async {
    if (_client == null) return;
    try {
      final resChildren = await _client!.from('children').select('*');
      final resNotulens = await _client!.from('notulens').select('*');
      final resPrograms = await _client!.from('programs').select('*');
      final resBundas = await _client!.from('bundas').select('*');
      final resUsers = await _client!.from('users').select('*');

      if (resChildren.isNotEmpty) {
        final list = (resChildren as List).map((e) => ChildModel.fromJson(e)).toList();
        LocalStore.instance.saveChildren(list);
      }

      if (resNotulens.isNotEmpty) {
        final list = (resNotulens as List).map((e) => NotulenModel.fromJson(e)).toList();
        LocalStore.instance.saveNotulens(list);
      }

      if (resPrograms.isNotEmpty) {
        final list = (resPrograms as List).map((e) => ProgramModel.fromJson(e)).toList();
        LocalStore.instance.savePrograms(list);
      }

      if (resBundas.isNotEmpty) {
        final list = (resBundas as List).map((e) => BundaModel.fromJson(e)).toList();
        LocalStore.instance.saveBundas(list);
      }

      if (resUsers.isNotEmpty) {
        final userList = resUsers as List;
        Map<String, dynamic>? auditRow;
        for (var u in userList) {
          if (u['username'] == 'SYSTEM_AUDIT_TRAIL') {
            auditRow = u;
            break;
          }
        }

        if (auditRow != null && auditRow['name'] != null) {
          try {
            final rawList = jsonDecode(auditRow['name']);
            if (rawList is List) {
              final cloudLogs = rawList.map((e) => LogModel.fromJson(e)).toList();
              LocalStore.instance.mergeCloudLogs(cloudLogs);
            }
          } catch (e) {
            debugPrint('Notice parsing audit logs: $e');
          }
        }

        final filteredUsers = userList
            .where((u) => u['username'] != 'SYSTEM_AUDIT_TRAIL')
            .map((e) => UserModel.fromJson(e))
            .toList();
        LocalStore.instance.saveUsers(filteredUsers);
      }
    } catch (e) {
      debugPrint('Auto cloud fetch notice: $e');
    }
  }
}
