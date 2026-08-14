import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../app_config.dart';
import '../models/child_model.dart';
import '../models/notulen_model.dart';
import '../models/program_model.dart';
import '../models/bunda_model.dart';
import '../models/user_model.dart';
import '../models/log_model.dart';
import '../initial_seed_data.dart';
import 'supabase_service.dart';

class PendingSyncItem {
  final String id;
  final String action; // 'UPSERT' or 'DELETE'
  final String table;
  final Map<String, dynamic> payload;

  PendingSyncItem({
    required this.id,
    required this.action,
    required this.table,
    required this.payload,
  });

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) {
    return PendingSyncItem(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? 'UPSERT',
      table: json['table']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'table': table,
      'payload': payload,
    };
  }
}

class LocalStore extends ChangeNotifier {
  static final LocalStore instance = LocalStore._internal();
  LocalStore._internal();

  static const String _storeBoxName = 'logika_kids_store_v9';
  Box? _box;

  UserModel? currentUser;

  List<ChildModel> _children = [];
  List<NotulenModel> _notulens = [];
  List<ProgramModel> _programs = [];
  List<BundaModel> _bundas = [];
  List<UserModel> _users = [];
  List<LogModel> _logs = [];
  List<String> _customRooms = [];
  List<PendingSyncItem> _pendingSyncQueue = [];

  List<ChildModel> get children => List.unmodifiable(_children);
  List<NotulenModel> get notulens => List.unmodifiable(_notulens);
  List<ProgramModel> get programs => List.unmodifiable(_programs);
  List<BundaModel> get bundas => List.unmodifiable(_bundas);
  List<UserModel> get users => List.unmodifiable(_users);
  List<LogModel> get logs => List.unmodifiable(_logs);
  List<PendingSyncItem> get pendingSyncQueue => List.unmodifiable(_pendingSyncQueue);
  int get pendingSyncCount => _pendingSyncQueue.length;

  List<String> get allRooms {
    final set = <String>{...AppConfig.rooms, ..._customRooms};
    return set.toList();
  }

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

      final rawRooms = _box!.get('custom_rooms');
      if (rawRooms != null) {
        final List list = jsonDecode(rawRooms);
        _customRooms = list.map((e) => e.toString()).toList();
      }

      final rawQueue = _box!.get('pending_sync_queue');
      if (rawQueue != null) {
        final List list = jsonDecode(rawQueue);
        _pendingSyncQueue = list.map((e) => PendingSyncItem.fromJson(e)).toList();
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
      _box!.put('custom_rooms', jsonEncode(_customRooms));
      _box!.put('pending_sync_queue', jsonEncode(_pendingSyncQueue.map((e) => e.toJson()).toList()));

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
    if (_children.isEmpty) {
      _children = List.from(InitialSeedData.children);
    }
    if (_notulens.isEmpty) {
      _notulens = List.from(InitialSeedData.notulens);
    }
    if (_programs.isEmpty) {
      _programs = List.from(InitialSeedData.programs);
    }
    if (_bundas.isEmpty) {
      _bundas = List.from(InitialSeedData.bundas);
    }
    if (_users.isEmpty) {
      _users = List.from(InitialSeedData.users);
    }
    _persist();
  }

  // --- OFFLINE SYNC QUEUE MANAGEMENT ---
  void enqueueSync(String table, String action, Map<String, dynamic> payload) {
    final itemId = payload['id']?.toString() ?? payload['username']?.toString() ?? '';
    if (itemId.isEmpty) return;

    _pendingSyncQueue.removeWhere((item) => item.table == table && item.id == itemId);
    _pendingSyncQueue.add(PendingSyncItem(
      id: itemId,
      action: action,
      table: table,
      payload: payload,
    ));
    _persist();
    debugPrint('Queued pending sync item for $table: $itemId (Total in Queue: ${_pendingSyncQueue.length})');
    unawaited(SupabaseService.instance.processAndFetchCloud());
  }

  void removePendingSync(String itemId) {
    _pendingSyncQueue.removeWhere((item) => item.id == itemId);
    _persist();
    debugPrint('Removed item $itemId from pending sync queue. Remaining: ${_pendingSyncQueue.length}');
  }

  // --- DYNAMIC ROOM MANAGEMENT ---
  void addRoom(String roomName) {
    final clean = roomName.trim();
    if (clean.isNotEmpty && !allRooms.contains(clean)) {
      _customRooms.add(clean);
      addLog('ADD_ROOM', 'Menambahkan ruang terapi baru: \'$clean\'');
      _persist();
    }
  }

  void deleteRoom(String roomName) {
    _customRooms.removeWhere((r) => r.toLowerCase() == roomName.toLowerCase());
    addLog('DELETE_ROOM', 'Menghapus ruang terapi: \'$roomName\'');
    _persist();
  }

  // --- COMPLETED PROGRAM HELPERS ---
  Set<String> getChildCompletedPrograms(String childName, {String? excludeNotulenId}) {
    final completedSet = <String>{};
    final childNotulens = _notulens.where((n) {
      if (excludeNotulenId != null && n.id == excludeNotulenId) return false;
      return n.childName.toLowerCase() == childName.toLowerCase();
    });

    for (var n in childNotulens) {
      final statuses = n.status;
      for (var pName in n.programsSelected) {
        final cleanProgName = resolveProgramName(pName);
        final statusVal = statuses[pName] ?? statuses[cleanProgName];
        if (statusVal == 'tuntas' || statusVal == 'S' || statusVal == 'K') {
          completedSet.add(pName);
          completedSet.add(cleanProgName);
        }
      }
    }
    return completedSet;
  }

  Map<String, Set<int>> getChildPastAchievedPoints(String childName, {String? excludeNotulenId}) {
    final Map<String, Set<int>> map = {};
    final childNotulens = _notulens.where((n) {
      if (excludeNotulenId != null && n.id == excludeNotulenId) return false;
      return n.childName.toLowerCase() == childName.toLowerCase();
    });

    for (var n in childNotulens) {
      final points = n.pointsAchieved;
      points.forEach((progKey, indices) {
        final cleanKey = resolveProgramName(progKey);
        if (!map.containsKey(progKey)) map[progKey] = <int>{};
        if (!map.containsKey(cleanKey)) map[cleanKey] = <int>{};

        for (var idx in indices) {
          if (idx is num) {
            final val = idx.toInt();
            map[progKey]!.add(val);
            map[cleanKey]!.add(val);
          }
        }
      });
    }
    return map;
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

  String resolveProgramName(String idOrName) {
    final clean = idOrName.trim();
    if (clean.isEmpty) return '';

    // 1. Direct match by id or programName (case-insensitive)
    final match = _programs.firstWhere(
      (p) => p.id.toLowerCase() == clean.toLowerCase() || p.programName.toLowerCase() == clean.toLowerCase(),
      orElse: () => ProgramModel(id: '', room: '', programName: '', indicators: [], targetPoints: 10),
    );
    if (match.programName.isNotEmpty) {
      return match.programName;
    }

    // 2. Partial ID match
    final partialMatch = _programs.firstWhere(
      (p) => p.id.toLowerCase().contains(clean.toLowerCase()) || clean.toLowerCase().contains(p.id.toLowerCase()),
      orElse: () => ProgramModel(id: '', room: '', programName: '', indicators: [], targetPoints: 10),
    );
    if (partialMatch.programName.isNotEmpty) {
      return partialMatch.programName;
    }

    // 3. Match against InitialSeedData programs
    final seedMatch = InitialSeedData.programs.firstWhere(
      (p) => p.id.toLowerCase() == clean.toLowerCase() || p.programName.toLowerCase() == clean.toLowerCase() || p.id.toLowerCase().contains(clean.toLowerCase()) || clean.toLowerCase().contains(p.id.toLowerCase()),
      orElse: () => ProgramModel(id: '', room: '', programName: '', indicators: [], targetPoints: 10),
    );
    if (seedMatch.programName.isNotEmpty) {
      return seedMatch.programName;
    }

    // 4. Fallback if clean starts with SUB_ or contains hex ID
    if (clean.startsWith('SUB_') || clean.startsWith('sub_')) {
      final subClean = clean.substring(4);
      if (subClean.length <= 8 && RegExp(r'^[a-fA-F0-9]+$').hasMatch(subClean)) {
        return 'Program Terapi ($subClean)';
      }
      return subClean;
    }

    return clean;
  }

  bool updatePassword(String username, String newPassword) {
    final idx = _users.indexWhere((u) => u.username == username);
    if (idx != -1) {
      final old = _users[idx];
      final updated = UserModel(
        username: old.username,
        password: newPassword,
        name: old.name,
        role: old.role,
      );
      _users[idx] = updated;
      if (currentUser?.username == username) {
        currentUser = updated;
      }
      addLog('UPDATE_PASSWORD', 'Mengubah password pengguna: ${old.name}');
      enqueueSync('users', 'UPSERT', updated.toJson());
      _persist();
      SupabaseService.instance.syncToCloud('users', updated.toJson());
      return true;
    }
    return false;
  }

  // --- CHILDREN CRUD ---
  void addChild(String name, String category) {
    final newChild = ChildModel(
      id: 'SUB_child_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      category: category.toLowerCase(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _children.insert(0, newChild);
    addLog('ADD_CHILD', 'Menambahkan data anak baru: \'${name.trim()}\' (${category.toUpperCase()})');
    enqueueSync('children', 'UPSERT', newChild.toJson());
    _persist();
    SupabaseService.instance.syncToCloud('children', newChild.toJson());
  }

  void updateChild(String id, String newName, String newCategory) {
    final idx = _children.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updated = ChildModel(
        id: id,
        name: newName.trim(),
        category: newCategory.toLowerCase(),
        createdAt: _children[idx].createdAt,
      );
      _children[idx] = updated;
      addLog('UPDATE_CHILD', 'Mengubah data anak: \'${newName.trim()}\'');
      enqueueSync('children', 'UPSERT', updated.toJson());
      _persist();
      SupabaseService.instance.syncToCloud('children', updated.toJson());
    }
  }

  void deleteChild(String id) {
    final target = _children.firstWhere((c) => c.id == id, orElse: () => ChildModel(id: '', name: '', category: ''));
    _children.removeWhere((c) => c.id == id);
    if (target.id.isNotEmpty) {
      addLog('DELETE_CHILD', 'Menghapus data anak: \'${target.name}\'');
    }
    enqueueSync('children', 'DELETE', {'id': id});
    _persist();
    SupabaseService.instance.deleteFromCloud('children', id);
  }

  // --- STAFF/USER CRUD ---
  void addUser(UserModel user) {
    _users.insert(0, user);
    addLog('ADD_USER', 'Menambahkan akun staf/admin baru: ${user.name} (${user.username})');
    enqueueSync('users', 'UPSERT', user.toJson());
    _persist();
    SupabaseService.instance.syncToCloud('users', user.toJson());

    if (user.role == 'staf') {
      final bundaName = user.name;
      if (!_bundas.any((b) => b.name.toLowerCase() == bundaName.toLowerCase())) {
        final newBunda = BundaModel(id: 'SUB_${DateTime.now().millisecondsSinceEpoch}', name: bundaName);
        _bundas.add(newBunda);
        enqueueSync('bundas', 'UPSERT', newBunda.toJson());
        SupabaseService.instance.syncToCloud('bundas', newBunda.toJson());
      }
    }
  }

  void updateUser(UserModel user) {
    final idx = _users.indexWhere((u) => u.username == user.username);
    if (idx != -1) {
      _users[idx] = user;
      addLog('UPDATE_USER', 'Mengubah akun staf/admin: ${user.name}');
      enqueueSync('users', 'UPSERT', user.toJson());
      _persist();
      SupabaseService.instance.syncToCloud('users', user.toJson());
    }
  }

  void deleteUser(String username) {
    final target = _users.firstWhere((u) => u.username == username, orElse: () => UserModel(username: '', password: '', name: '', role: ''));
    _users.removeWhere((u) => u.username == username);
    if (target.username.isNotEmpty) {
      addLog('DELETE_USER', 'Menghapus akun pengguna: ${target.name} (${target.username})');
    }
    enqueueSync('users', 'DELETE', {'username': username});
    _persist();
    SupabaseService.instance.deleteFromCloud('users', username);
  }

  // --- PROGRAM CRUD ---
  void addProgram(ProgramModel program) {
    _programs.insert(0, program);
    addLog('ADD_PROGRAM', 'Menambahkan program terapi baru: ${program.programName} (${program.room})');
    enqueueSync('programs', 'UPSERT', program.toJson());
    _persist();
    SupabaseService.instance.syncToCloud('programs', program.toJson());
  }

  void updateProgram(ProgramModel program) {
    final idx = _programs.indexWhere((p) => p.id == program.id);
    if (idx != -1) {
      _programs[idx] = program;
      addLog('UPDATE_PROGRAM', 'Mengubah program terapi: ${program.programName}');
      enqueueSync('programs', 'UPSERT', program.toJson());
      _persist();
      SupabaseService.instance.syncToCloud('programs', program.toJson());
    }
  }

  void deleteProgram(String id) {
    final target = _programs.firstWhere((p) => p.id == id, orElse: () => ProgramModel(id: '', room: '', programName: '', indicators: [], targetPoints: 10));
    _programs.removeWhere((p) => p.id == id);
    if (target.id.isNotEmpty) {
      addLog('DELETE_PROGRAM', 'Menghapus program terapi: ${target.programName}');
    }
    enqueueSync('programs', 'DELETE', {'id': id});
    _persist();
    SupabaseService.instance.deleteFromCloud('programs', id);
  }

  // --- NOTULEN CRUD & EDIT ---
  void addNotulen(NotulenModel notulen) {
    _notulens.insert(0, notulen);
    addLog('ADD_NOTULEN', 'Bunda ${notulen.notulen} menginput notulen harian untuk ${notulen.childName} (${notulen.room})');
    enqueueSync('notulens', 'UPSERT', notulen.toJson());
    _persist();
    SupabaseService.instance.syncToCloud('notulens', notulen.toJson());
  }

  void updateNotulen(NotulenModel notulen) {
    final idx = _notulens.indexWhere((n) => n.id == notulen.id);
    if (idx != -1) {
      _notulens[idx] = notulen;
      addLog('UPDATE_NOTULEN', 'Memperbarui notulen harian ${notulen.childName} (${notulen.date})');
      enqueueSync('notulens', 'UPSERT', notulen.toJson());
      _persist();
      SupabaseService.instance.syncToCloud('notulens', notulen.toJson());
    }
  }

  void deleteNotulen(String id) {
    final target = _notulens.firstWhere((n) => n.id == id, orElse: () => NotulenModel(id: '', date: '', childName: '', notulen: '', room: '', programsSelected: [], pointsAchieved: {}, status: {}, notes: ''));
    _notulens.removeWhere((n) => n.id == id);
    if (target.id.isNotEmpty) {
      addLog('DELETE_NOTULEN', 'Menghapus notulen sesi ${target.childName} (${target.date})');
    }
    enqueueSync('notulens', 'DELETE', {'id': id});
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

    // Queue audit log sync payload so offline logs are guaranteed to sync when back online
    final auditPayload = {
      'username': 'SYSTEM_AUDIT_TRAIL',
      'password': 'system_logs_store',
      'name': jsonEncode(_logs.map((l) => l.toJson()).toList()),
      'role': 'system'
    };
    enqueueSync('users', 'UPSERT', auditPayload);
    SupabaseService.instance.syncLogsToCloud(_logs);
  }

  // --- SMART CLOUD DATA SYNC (100% PARITY WITH WEB APP) ---
  void saveCloudChildren(List<ChildModel> cloudList) {
    if (cloudList.isEmpty) return;
    final Map<String, ChildModel> map = {};
    for (var c in cloudList) {
      if (c.id.isNotEmpty) map[c.id] = c;
    }
    for (var c in _children) {
      if (c.id.isNotEmpty && !map.containsKey(c.id)) {
        map[c.id] = c;
      }
    }
    _children = map.values.toList();
    _children.sort((a, b) => a.name.compareTo(b.name));
    _persist();
  }
  void mergeCloudChildren(List<ChildModel> cloudList) => saveCloudChildren(cloudList);

  void saveCloudNotulens(List<NotulenModel> cloudList) {
    if (cloudList.isEmpty) return;
    final Map<String, NotulenModel> map = {};
    for (var n in cloudList) {
      if (n.id.isNotEmpty) map[n.id] = n;
    }
    for (var n in _notulens) {
      if (n.id.isNotEmpty && !map.containsKey(n.id)) {
        map[n.id] = n;
      }
    }
    _notulens = map.values.toList();
    _notulens.sort((a, b) => b.date.compareTo(a.date));
    _persist();
  }
  void mergeCloudNotulens(List<NotulenModel> cloudList) => saveCloudNotulens(cloudList);

  void saveCloudPrograms(List<ProgramModel> cloudList) {
    if (cloudList.isEmpty) return;
    final Map<String, ProgramModel> map = {};
    for (var p in cloudList) {
      if (p.id.isNotEmpty) map[p.id] = p;
    }
    for (var p in _programs) {
      if (p.id.isNotEmpty && !map.containsKey(p.id)) {
        map[p.id] = p;
      }
    }
    _programs = map.values.toList();
    _persist();
  }
  void mergeCloudPrograms(List<ProgramModel> cloudList) => saveCloudPrograms(cloudList);

  void saveCloudBundas(List<BundaModel> cloudList) {
    if (cloudList.isEmpty) return;
    final Map<String, BundaModel> map = {};
    for (var b in cloudList) {
      if (b.id.isNotEmpty) map[b.id] = b;
    }
    for (var b in _bundas) {
      if (b.id.isNotEmpty && !map.containsKey(b.id)) {
        map[b.id] = b;
      }
    }
    _bundas = map.values.toList();
    _persist();
  }
  void mergeCloudBundas(List<BundaModel> cloudList) => saveCloudBundas(cloudList);

  void saveCloudUsers(List<UserModel> cloudList) {
    if (cloudList.isEmpty) return;
    final Map<String, UserModel> map = {};
    for (var u in cloudList) {
      if (u.username.isNotEmpty) map[u.username] = u;
    }
    for (var u in _users) {
      if (u.username.isNotEmpty && !map.containsKey(u.username)) {
        map[u.username] = u;
      }
    }
    _users = map.values.toList();
    _persist();
  }
  void mergeCloudUsers(List<UserModel> cloudList) => saveCloudUsers(cloudList);

  void saveCloudLogs(List<LogModel> cloudLogs) {
    if (cloudLogs.isEmpty) return;
    final Map<String, LogModel> map = {};
    for (var l in cloudLogs) {
      if (l.id.isNotEmpty) map[l.id] = l;
    }
    for (var l in _logs) {
      if (l.id.isNotEmpty && !map.containsKey(l.id)) {
        map[l.id] = l;
      }
    }
    _logs = map.values.toList();
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (_logs.length > 200) _logs = _logs.sublist(0, 200);
    _persist();
  }
  void mergeCloudLogs(List<LogModel> cloudLogs) => saveCloudLogs(cloudLogs);
}
