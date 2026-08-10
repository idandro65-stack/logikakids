import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/child_model.dart';
import '../models/notulen_model.dart';
import '../models/program_model.dart';
import '../models/bunda_model.dart';
import '../models/user_model.dart';
import '../models/log_model.dart';
import 'supabase_service.dart';

class LocalStore extends ChangeNotifier {
  static final LocalStore instance = LocalStore._internal();
  LocalStore._internal();

  static const String _storeBoxName = 'logika_kids_store_v5';
  Box? _box;

  UserModel? currentUser;

  List<ChildModel> _children = [];
  List<NotulenModel> _notulens = [];
  List<ProgramModel> _programs = [];
  List<BundaModel> _bundas = [];
  List<UserModel> _users = [];
  List<LogModel> _logs = [];

  List<ChildModel> get children => List.unmodifiable(_children);
  List<NotulenModel> get notulens => List.unmodifiable(_notulens);
  List<ProgramModel> get programs => List.unmodifiable(_programs);
  List<BundaModel> get bundas => List.unmodifiable(_bundas);
  List<UserModel> get users => List.unmodifiable(_users);
  List<LogModel> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_storeBoxName);

    _loadLocalCache();
    _ensureDefaultData();
  }

  void _loadLocalCache() {
    if (_box == null) return;

    try {
      final rawChildren = _box!.get('children');
      if (rawChildren != null) {
        final List list = jsonDecode(rawChildren);
        _children = list.map((e) => ChildModel.fromJson(e)).toList();
      }

      final rawNotulens = _box!.get('notulens');
      if (rawNotulens != null) {
        final List list = jsonDecode(rawNotulens);
        _notulens = list.map((e) => NotulenModel.fromJson(e)).toList();
      }

      final rawPrograms = _box!.get('programs');
      if (rawPrograms != null) {
        final List list = jsonDecode(rawPrograms);
        _programs = list.map((e) => ProgramModel.fromJson(e)).toList();
      }

      final rawBundas = _box!.get('bundas');
      if (rawBundas != null) {
        final List list = jsonDecode(rawBundas);
        _bundas = list.map((e) => BundaModel.fromJson(e)).toList();
      }

      final rawUsers = _box!.get('users');
      if (rawUsers != null) {
        final List list = jsonDecode(rawUsers);
        _users = list.map((e) => UserModel.fromJson(e)).toList();
      }

      final rawLogs = _box!.get('logs');
      if (rawLogs != null) {
        final List list = jsonDecode(rawLogs);
        _logs = list.map((e) => LogModel.fromJson(e)).toList();
      }

      final rawAuth = _box!.get('auth_session');
      if (rawAuth != null) {
        currentUser = UserModel.fromJson(jsonDecode(rawAuth));
      }
    } catch (e) {
      debugPrint('Error loading local cache: $e');
    }
  }

  void _persist() {
    if (_box == null) return;
    try {
      _box!.put('children', jsonEncode(_children.map((e) => e.toJson()).toList()));
      _box!.put('notulens', jsonEncode(_notulens.map((e) => e.toJson()).toList()));
      _box!.put('programs', jsonEncode(_programs.map((e) => e.toJson()).toList()));
      _box!.put('bundas', jsonEncode(_bundas.map((e) => e.toJson()).toList()));
      _box!.put('users', jsonEncode(_users.map((e) => e.toJson()).toList()));
      _box!.put('logs', jsonEncode(_logs.map((e) => e.toJson()).toList()));

      if (currentUser != null) {
        _box!.put('auth_session', jsonEncode(currentUser!.toJson()));
      } else {
        _box!.delete('auth_session');
      }
    } catch (e) {
      debugPrint('Error persisting local cache: $e');
    }
    notifyListeners();
  }

  void _ensureDefaultData() {
    if (_users.isEmpty) {
      _users = [
        UserModel(username: 'admin', password: 'admin123', name: 'Kepala Klinik Admin', role: 'admin'),
        UserModel(username: 'bunda.ani', password: '123456', name: 'Ani', role: 'staf'),
        UserModel(username: 'bunda.eka', password: '123456', name: 'Eka', role: 'staf'),
        UserModel(username: 'bunda.lia', password: '123456', name: 'Lia', role: 'staf'),
        UserModel(username: 'bunda.mila', password: '123456', name: 'Mila', role: 'staf'),
        UserModel(username: 'bunda.oza', password: '123456', name: 'Oza', role: 'staf'),
      ];
      _persist();
    }
  }

  // --- AUTHENTICATION ---
  bool login(String username, String password) {
    final cleanUser = username.trim().toLowerCase().replaceAll('bunda.', '').replaceAll(' ', '');
    final cleanPw = password.trim();

    final user = _users.firstWhere(
      (u) {
        final uClean = u.username.toLowerCase().replaceAll('bunda.', '').replaceAll(' ', '');
        return (uClean == cleanUser || u.username.toLowerCase() == username.trim().toLowerCase()) && u.password == cleanPw;
      },
      orElse: () => UserModel(username: '', password: '', name: '', role: ''),
    );

    if (user.username.isNotEmpty) {
      currentUser = user;
      addLog('AUTH_LOGIN', '${user.name} (${user.role.toUpperCase()}) berhasil masuk ke aplikasi');
      _persist();
      return true;
    }
    return false;
  }

  void logout() {
    if (currentUser != null) {
      addLog('AUTH_LOGOUT', '${currentUser!.name} keluar dari aplikasi');
    }
    currentUser = null;
    _persist();
  }

  // --- CRUD ACTIONS ---
  void addChild(String name, String category) {
    final newChild = ChildModel(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      category: category.toLowerCase(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _children.insert(0, newChild);
    addLog('ADD_CHILD', 'Menambahkan data anak baru: \'${name.trim()}\' (${category.toUpperCase()})');
    _persist();
    SupabaseService.instance.syncToCloud('children', newChild.toJson());
  }

  void deleteChild(String id) {
    final target = _children.firstWhere((c) => c.id == id, orElse: () => ChildModel(id: '', name: '', category: ''));
    _children.removeWhere((c) => c.id == id);
    if (target.id.isNotEmpty) {
      addLog('DELETE_CHILD', 'Menghapus data anak: \'${target.name}\'');
    }
    _persist();
    SupabaseService.instance.deleteFromCloud('children', id);
  }

  void addNotulen(NotulenModel notulen) {
    _notulens.insert(0, notulen);
    addLog('ADD_NOTULEN', 'Bunda ${notulen.notulen} menginput notulen harian untuk ${notulen.childName} (${notulen.room})');
    _persist();
    SupabaseService.instance.syncToCloud('notulens', notulen.toJson());
  }

  void deleteNotulen(String id) {
    final target = _notulens.firstWhere((n) => n.id == id, orElse: () => NotulenModel(id: '', date: '', childName: '', notulen: '', room: '', programsSelected: [], pointsAchieved: {}, status: {}, notes: ''));
    _notulens.removeWhere((n) => n.id == id);
    if (target.id.isNotEmpty) {
      addLog('DELETE_NOTULEN', 'Menghapus notulen sesi ${target.childName} (${target.date})');
    }
    _persist();
    SupabaseService.instance.deleteFromCloud('notulens', id);
  }

  void addLog(String action, String description) {
    final newLog = LogModel(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String(),
      userName: currentUser?.name ?? 'Sistem',
      role: currentUser?.role ?? 'staf',
      action: action,
      description: description,
    );
    _logs.insert(0, newLog);
    if (_logs.length > 200) {
      _logs = _logs.sublist(0, 200);
    }
    _persist();
    SupabaseService.instance.syncLogsToCloud(_logs);
  }

  // --- CLOUD SYNC SETTERS ---
  void saveChildren(List<ChildModel> list) {
    _children = list;
    _persist();
  }

  void saveNotulens(List<NotulenModel> list) {
    _notulens = list;
    _persist();
  }

  void savePrograms(List<ProgramModel> list) {
    _programs = list;
    _persist();
  }

  void saveBundas(List<BundaModel> list) {
    _bundas = list;
    _persist();
  }

  void saveUsers(List<UserModel> list) {
    _users = list;
    _persist();
  }

  void mergeCloudLogs(List<LogModel> cloudLogs) {
    final Map<String, LogModel> map = {};
    for (var l in cloudLogs) {
      if (l.id.isNotEmpty) map[l.id] = l;
    }
    for (var l in _logs) {
      if (l.id.isNotEmpty) map[l.id] = l;
    }
    _logs = map.values.toList();
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (_logs.length > 200) _logs = _logs.sublist(0, 200);
    _persist();
  }
}
