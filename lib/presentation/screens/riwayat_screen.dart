import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/pdf_service.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/child_model.dart';
import '../../data/models/notulen_model.dart';
import '../../data/models/program_model.dart';
import 'input_notulen_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _categoryFilter = 'all';
  String _roomFilter = 'all';
  String _programFilter = 'all';
  String _sortBy = 'date-desc'; // Default: Tanggal Terbaru
  DateTime? _dateFrom;
  DateTime? _dateTo;

  Future<void> _confirmDeleteNotulen(NotulenModel n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus Sesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus notulen sesi ${n.childName} tanggal ${n.date}? Tindakan ini tidak dapat dibatalkan.', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Sesi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LocalStore.instance.deleteNotulen(n.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notulen sesi ${n.childName} berhasil dipindahkan ke Kotak Sampah')),
        );
      }
    }
  }

  Future<void> _confirmDeleteSingleProgram(NotulenModel n, String progKey, LocalStore store) async {
    final cleanName = store.resolveProgramName(progKey);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Program Ini?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus program \'$cleanName\' dari sesi tanggal ${n.date}? Hanya program ini saja yang akan dihapus dari notulen.', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Program', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      store.deleteProgramFromNotulen(n.id, progKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Program \'$cleanName\' berhasil dihapus dari sesi')),
        );
      }
    }
  }

  void _showQuickEditProgramModal(NotulenModel n, String progKey, LocalStore store) {
    final cleanProgName = store.resolveProgramName(progKey);
    final progObj = store.programs.firstWhere(
      (p) => p.id == progKey || p.programName == progKey || p.programName.toLowerCase() == cleanProgName.toLowerCase(),
      orElse: () => ProgramModel(id: '', room: '', programName: cleanProgName, indicators: [], targetPoints: 10),
    );

    final targetPoints = progObj.targetPoints > 0 ? progObj.targetPoints : 10;
    final indicatorsList = progObj.indicators;

    // Past achieved for this child excluding current notulen
    final pastAchievedMap = store.getChildPastAchievedPoints(n.childName, excludeNotulenId: n.id);
    final pastAchieved = pastAchievedMap[progKey] ?? pastAchievedMap[cleanProgName] ?? <int>{};

    // Current points in this notulen
    final rawPoints = n.pointsAchieved[progKey] ?? n.pointsAchieved[cleanProgName];
    List<int> currentSessionPoints = [];
    if (rawPoints != null) {
      currentSessionPoints = List<int>.from(rawPoints).where((pt) => pt >= 1).toList();
    }

    String currentStatus = n.status[progKey] ?? n.status[cleanProgName] ?? 'BS';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final allUnlockedIndices = List.generate(targetPoints, (i) => i + 1).where((idx) => !pastAchieved.contains(idx)).toList();
            final isAllUnlockedChecked = allUnlockedIndices.isNotEmpty && allUnlockedIndices.every((idx) => currentSessionPoints.contains(idx));

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cleanProgName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFBE123C)),
                            ),
                            Text(
                              'Sesi ${n.childName} | Tanggal: ${n.date}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Header Checkbox Centang Semua
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pencapaian Kumulatif: ${currentSessionPoints.where((pt) => pt >= 1 && pt <= targetPoints).toSet().union(pastAchieved.where((pt) => pt >= 1 && pt <= targetPoints).toSet()).length} / $targetPoints tercapai',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      InkWell(
                        onTap: () {
                          setModalState(() {
                            if (!isAllUnlockedChecked) {
                              for (var idx in allUnlockedIndices) {
                                if (!currentSessionPoints.contains(idx)) {
                                  currentSessionPoints.add(idx);
                                }
                              }
                              currentStatus = 'S';
                            } else {
                              currentSessionPoints.clear();
                              currentStatus = 'BS';
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAllUnlockedChecked ? const Color(0xFFF43F5E).withValues(alpha: 0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isAllUnlockedChecked ? const Color(0xFFF43F5E) : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 18,
                                width: 18,
                                child: Checkbox(
                                  value: isAllUnlockedChecked,
                                  activeColor: const Color(0xFFF43F5E),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (val) {
                                    setModalState(() {
                                      if (val == true) {
                                        for (var idx in allUnlockedIndices) {
                                          if (!currentSessionPoints.contains(idx)) {
                                            currentSessionPoints.add(idx);
                                          }
                                        }
                                        currentStatus = 'S';
                                      } else {
                                        currentSessionPoints.clear();
                                        currentStatus = 'BS';
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Centang Semua (Tuntas)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isAllUnlockedChecked ? const Color(0xFFBE123C) : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Indicator Checkpoints List
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      itemCount: targetPoints,
                      itemBuilder: (ctx, i) {
                        final pointNum = i + 1;
                        final isPastLocked = pastAchieved.contains(pointNum);
                        final isCurrentChecked = currentSessionPoints.contains(pointNum);
                        final labelText = (indicatorsList.length > i) ? '$pointNum. ${indicatorsList[i]}' : 'Poin Checkpoint $pointNum';

                        if (isPastLocked) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.checkSquare, size: 14, color: Colors.green),
                                const SizedBox(width: 6),
                                Expanded(child: Text(labelText, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade200, borderRadius: BorderRadius.circular(4)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.check, size: 10, color: Colors.green),
                                      SizedBox(width: 2),
                                      Text('Tercapai (Sesi Lalu)', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(labelText, style: const TextStyle(fontSize: 11)),
                          value: isCurrentChecked,
                          activeColor: const Color(0xFFF43F5E),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                if (!currentSessionPoints.contains(pointNum)) {
                                  currentSessionPoints.add(pointNum);
                                }
                              } else {
                                currentSessionPoints.remove(pointNum);
                              }

                              final totalNow = currentSessionPoints.length + pastAchieved.length;
                              currentStatus = (totalNow >= targetPoints) ? 'S' : 'BS';
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        store.quickUpdateNotulenProgram(n.id, progKey, currentSessionPoints, currentStatus);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Perubahan program \'$cleanProgName\' berhasil disimpan!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                      icon: const Icon(LucideIcons.check, color: Colors.white, size: 16),
                      label: const Text('Simpan Perubahan Program', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalStore.instance,
      builder: (context, _) {
        final store = LocalStore.instance;
        final notulens = store.notulens;

        // Group Notulens by Child Name with Comprehensive Filters
        Map<String, List<NotulenModel>> groupedByChild = {};

        for (var n in notulens) {
          final childObj = store.children.firstWhere(
            (c) => c.name.toLowerCase() == n.childName.toLowerCase(),
            orElse: () => ChildModel(id: '', name: n.childName, category: 'reguler'),
          );

          // 1. Category Filter
          if (_categoryFilter != 'all' && childObj.category != _categoryFilter) {
            continue;
          }

          // 2. Room Filter
          if (_roomFilter != 'all') {
            final rooms = n.room.split(';').map((r) => r.trim());
            if (!rooms.contains(_roomFilter)) continue;
          }

          // 3. Program Dropdown Filter
          if (_programFilter != 'all') {
            final hasProgram = n.programsSelected.any((p) {
              final cleanP = store.resolveProgramName(p).toLowerCase();
              return p.toLowerCase() == _programFilter.toLowerCase() || cleanP == _programFilter.toLowerCase();
            });
            if (!hasProgram) continue;
          }

          // 4. Date Range Filter (Exact string comparison on YYYY-MM-DD)
          if (_dateFrom != null) {
            final fromStr = DateFormat('yyyy-MM-dd').format(_dateFrom!);
            if (n.date.compareTo(fromStr) < 0) continue;
          }
          if (_dateTo != null) {
            final toStr = DateFormat('yyyy-MM-dd').format(_dateTo!);
            if (n.date.compareTo(toStr) > 0) continue;
          }

          // 5. Search Text Filter
          final searchLower = _searchController.text.trim().toLowerCase();
          if (searchLower.isNotEmpty) {
            final matchesChild = n.childName.toLowerCase().contains(searchLower);
            final matchesRoom = n.room.toLowerCase().contains(searchLower);
            final matchesProgram = n.programsSelected.any((p) => store.resolveProgramName(p).toLowerCase().contains(searchLower));
            if (!matchesChild && !matchesRoom && !matchesProgram) continue;
          }

          if (!groupedByChild.containsKey(n.childName)) {
            groupedByChild[n.childName] = [];
          }
          groupedByChild[n.childName]!.add(n);
        }

        int extractTimestamp(NotulenModel n) {
          final match = RegExp(r'\d{10,14}').firstMatch(n.id);
          if (match != null) {
            final parsed = int.tryParse(match.group(0)!);
            if (parsed != null) return parsed;
          }
          final idx = notulens.indexOf(n);
          if (idx != -1) {
            return 1000000 - idx;
          }
          return 0;
        }

        // 1. First sort notulens inside each child group: date desc, then timestamp desc
        groupedByChild.forEach((cName, nList) {
          nList.sort((a, b) {
            final dateComp = b.date.compareTo(a.date);
            if (dateComp != 0) return dateComp;
            final tsA = extractTimestamp(a);
            final tsB = extractTimestamp(b);
            return tsB.compareTo(tsA);
          });
        });

        final childNames = groupedByChild.keys.toList();

        // 2. Sort Children Names with High Precision (Newest input always on top for date-desc)
        if (_sortBy == 'name-asc') {
          childNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        } else if (_sortBy == 'name-desc') {
          childNames.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
        } else if (_sortBy == 'date-desc') {
          childNames.sort((a, b) {
            final notulenA = groupedByChild[a]!.first;
            final notulenB = groupedByChild[b]!.first;
            final dateComp = notulenB.date.compareTo(notulenA.date);
            if (dateComp != 0) return dateComp;
            final tsA = extractTimestamp(notulenA);
            final tsB = extractTimestamp(notulenB);
            return tsB.compareTo(tsA);
          });
        } else if (_sortBy == 'date-asc') {
          childNames.sort((a, b) {
            final notulenA = groupedByChild[a]!.last;
            final notulenB = groupedByChild[b]!.last;
            final dateComp = notulenA.date.compareTo(notulenB.date);
            if (dateComp != 0) return dateComp;
            final tsA = extractTimestamp(notulenA);
            final tsB = extractTimestamp(notulenB);
            return tsA.compareTo(tsB);
          });
        }

        // Get Available Programs for Dropdown Filter
        final availablePrograms = store.programs
            .where((p) => _roomFilter == 'all' || p.room.toLowerCase() == _roomFilter.toLowerCase())
            .map((p) => p.programName.trim())
            .where((p) => p.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar & Sort Toolbar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nama anak / program / ruangan...',
                          prefixIcon: const Icon(LucideIcons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(LucideIcons.arrowDownUp, size: 18),
                      onChanged: (val) => setState(() => _sortBy = val!),
                      items: const [
                        DropdownMenuItem(value: 'date-desc', child: Text('Tgl Terbaru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'date-asc', child: Text('Tgl Terlama', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'name-asc', child: Text('Nama A-Z', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'name-desc', child: Text('Nama Z-A', style: TextStyle(fontSize: 11))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Category & Room Filters Toolbar
                Row(
                  children: [
                    // Category Chips
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          _buildCatChip('Semua', 'all'),
                          const SizedBox(width: 4),
                          _buildCatChip('Intensif', 'intensif'),
                          const SizedBox(width: 4),
                          _buildCatChip('Reguler', 'reguler'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Room Dropdown Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _roomFilter,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Semua Ruang', style: TextStyle(fontSize: 11))),
                          ...store.allRooms.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11)))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _roomFilter = val!;
                            _programFilter = 'all'; // reset program filter on room change
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Specific Program Dropdown Filter (Clean without emojis)
                DropdownButtonFormField<String>(
                  value: availablePrograms.contains(_programFilter) ? _programFilter : 'all',
                  decoration: InputDecoration(
                    labelText: 'Filter Berdasarkan Program Terapi',
                    labelStyle: const TextStyle(fontSize: 11),
                    prefixIcon: const Icon(LucideIcons.bookOpen, size: 16, color: Color(0xFFF43F5E)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('Semua Program Terapi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    ...availablePrograms.map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _programFilter = val ?? 'all'),
                ),
                const SizedBox(height: 8),

                // 4. Date Range Filter Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateFrom ?? DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _dateFrom = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 14, color: Color(0xFFF43F5E)),
                              const SizedBox(width: 4),
                              Text(
                                _dateFrom != null
                                    ? 'Dari: ${DateFormat('yyyy-MM-dd').format(_dateFrom!)}'
                                    : 'Dari Tanggal',
                                style: TextStyle(fontSize: 10, color: _dateFrom != null ? Colors.black87 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateTo ?? DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _dateTo = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 14, color: Color(0xFFF43F5E)),
                              const SizedBox(width: 4),
                              Text(
                                _dateTo != null
                                    ? 'Sampai: ${DateFormat('yyyy-MM-dd').format(_dateTo!)}'
                                    : 'Sampai Tanggal',
                                style: TextStyle(fontSize: 10, color: _dateTo != null ? Colors.black87 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_dateFrom != null || _dateTo != null || _programFilter != 'all')
                      IconButton(
                        icon: const Icon(LucideIcons.xCircle, color: Colors.grey, size: 20),
                        tooltip: 'Reset Filter',
                        onPressed: () => setState(() {
                          _dateFrom = null;
                          _dateTo = null;
                          _programFilter = 'all';
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Riwayat Cards List
                Expanded(
                  child: childNames.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data riwayat notulen sesuai filter',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: childNames.length,
                          itemBuilder: (ctx, idx) {
                            final childName = childNames[idx];
                            final childNotulens = groupedByChild[childName]!;

                            final childObj = store.children.firstWhere(
                              (c) => c.name.toLowerCase() == childName.toLowerCase(),
                              orElse: () => ChildModel(id: '', name: childName, category: 'reguler'),
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFFECDD3)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Child Header Banner
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.user, color: Color(0xFFF43F5E), size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              childName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: childObj.category == 'intensif'
                                                    ? Colors.blue.shade100
                                                    : Colors.teal.shade100,
                                                borderRadius: BorderRadius.circular(99),
                                              ),
                                              child: Text(
                                                childObj.category.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: childObj.category == 'intensif'
                                                      ? Colors.blue.shade900
                                                      : Colors.teal.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                PdfService.generateAndPrintRaport(context, childName);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFF43F5E),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                              ),
                                              icon: const Icon(LucideIcons.fileText, size: 12),
                                              label: const Text('Raport PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(4),
                                              icon: const Icon(LucideIcons.send, color: Colors.green, size: 18),
                                              onPressed: () {
                                                PdfService.shareToWhatsApp(context, childName);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.history, size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Riwayat Sesi Terapi: ${childNotulens.length} Sesi Tercatat',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),

                                    // Session Items Cards
                                    ...childNotulens.map((n) {
                                      return _buildSessionCard(context, n, store);
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRoomColor(String room) {
    final lower = room.toLowerCase();
    if (lower.contains('sensori')) return const Color(0xFFE11D48); // Rose / Sensori
    if (lower.contains('okupasi')) return const Color(0xFF7C3AED); // Violet / Okupasi
    if (lower.contains('wicara')) return const Color(0xFF0D9488); // Teal / Wicara
    if (lower.contains('snoezelen')) return const Color(0xFFD97706); // Amber / Snoezelen
    if (lower.contains('akademik') || lower.contains('remidial')) return const Color(0xFF0284C7); // Sky Blue
    if (lower.contains('fisioterapi')) return const Color(0xFF059669); // Emerald
    if (lower.contains('perilaku') || lower.contains('aba')) return const Color(0xFFC026D3); // Fuchsia
    return const Color(0xFF4F46E5); // Indigo default
  }

  Widget _buildSessionCard(BuildContext context, NotulenModel n, LocalStore store) {
    final primaryRoom = n.room.split(';').first.trim();
    final roomColor = _getRoomColor(primaryRoom);

    // Determine which programs should be displayed on this card:
    // If a specific Program Filter or search by program is active, only show the matching program!
    final searchLower = _searchController.text.trim().toLowerCase();
    final isProgramFilterActive = _programFilter != 'all';
    final isTextProgramSearch = searchLower.isNotEmpty &&
        !n.childName.toLowerCase().contains(searchLower) &&
        !n.room.toLowerCase().contains(searchLower);

    List<String> displayedPrograms = n.programsSelected;

    if (isProgramFilterActive) {
      displayedPrograms = displayedPrograms.where((p) {
        final clean = store.resolveProgramName(p).toLowerCase();
        return p.toLowerCase() == _programFilter.toLowerCase() || clean == _programFilter.toLowerCase();
      }).toList();
    } else if (isTextProgramSearch) {
      displayedPrograms = displayedPrograms.where((p) {
        final clean = store.resolveProgramName(p).toLowerCase();
        return clean.contains(searchLower) || p.toLowerCase().contains(searchLower);
      }).toList();
    }

    if (displayedPrograms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: roomColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roomColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Line: Date | Bunda | Edit | Hapus (Whole Session)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 14, color: roomColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${n.date}  |  Bunda: ${n.notulen}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sleek Edit Full Button
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InputNotulenScreen(editNotulen: n),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.edit2, size: 11, color: Colors.blue),
                            SizedBox(width: 3),
                            Text('Edit', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Sleek Hapus Sesi Button
                    InkWell(
                      onTap: () => _confirmDeleteNotulen(n),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.trash2, size: 11, color: Colors.red),
                            SizedBox(width: 3),
                            Text('Hapus', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: roomColor.withValues(alpha: 0.2)),

          // Session Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Title Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: n.room.split(';').map((rm) {
                    final cleanRm = rm.trim();
                    if (cleanRm.isEmpty) return const SizedBox.shrink();
                    final rmColor = _getRoomColor(cleanRm);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: rmColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: rmColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        cleanRm,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: rmColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Special Notes Badge if available
                if (n.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: roomColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.pin, size: 12, color: roomColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Catatan Perkembangan: "${n.notes}"',
                            style: TextStyle(fontSize: 11, color: roomColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Individual Program Items Cards with Focus & Cumulative Calculation
                ...displayedPrograms.map((progId) {
                  final cleanProgName = store.resolveProgramName(progId);
                  final progObj = store.programs.firstWhere(
                    (p) => p.id == progId || p.programName == progId || p.programName.toLowerCase() == cleanProgName.toLowerCase(),
                    orElse: () => ProgramModel(id: '', room: '', programName: cleanProgName, indicators: [], targetPoints: 10),
                  );

                  final totalTarget = progObj.targetPoints > 0
                      ? progObj.targetPoints
                      : (progObj.indicators.isNotEmpty ? progObj.indicators.length : 10);

                  // 1. Calculate Cumulative Achieved Points (Option B)
                  final rawThisSession = n.pointsAchieved[progId] ?? n.pointsAchieved[cleanProgName];
                  final Set<int> allAchievedSet = {};
                  if (rawThisSession != null) {
                    allAchievedSet.addAll(rawThisSession);
                  }

                  final pastAchievedMap = store.getChildPastAchievedPoints(n.childName, excludeNotulenId: n.id);
                  final pastAchieved = pastAchievedMap[progId] ?? pastAchievedMap[cleanProgName] ?? <int>{};
                  allAchievedSet.addAll(pastAchieved);

                  final List<int> tercapaiNumbers = allAchievedSet.where((pt) => pt >= 1 && pt <= totalTarget).toList()..sort();
                  final List<int> belumNumbers = List.generate(totalTarget, (i) => i + 1).where((pt) => !tercapaiNumbers.contains(pt)).toList();

                  final isTuntas = tercapaiNumbers.length >= totalTarget;
                  final statusLabel = isTuntas ? 'Tuntas' : 'Berlangsung';
                  final statusColor = isTuntas ? Colors.green : Colors.orange;

                  final tercapaiStr = tercapaiNumbers.isNotEmpty ? '${tercapaiNumbers.join(', ')} (${tercapaiNumbers.length}/$totalTarget)' : '—';
                  final belumStr = belumNumbers.isNotEmpty ? belumNumbers.join(', ') : '—';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Program Name & Direct Action Buttons (Edit Program & Hapus Program)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cleanProgName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Row(
                              children: [
                                // Edit Single Program Button
                                InkWell(
                                  onTap: () => _showQuickEditProgramModal(n, progId, store),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(LucideIcons.edit3, size: 10, color: Colors.blue),
                                        SizedBox(width: 2),
                                        Text('Edit', style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Delete Single Program Button
                                InkWell(
                                  onTap: () => _confirmDeleteSingleProgram(n, progId, store),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(LucideIcons.trash2, size: 10, color: Colors.red),
                                        SizedBox(width: 2),
                                        Text('Hapus', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isTuntas ? LucideIcons.checkCircle2 : LucideIcons.rotateCcw,
                                        size: 10,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Checkpoint Kumulatif Tercapai Line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.checkCheck, size: 13, color: Colors.green),
                            const SizedBox(width: 4),
                            const Text('Tercapai: ', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                tercapaiStr,
                                style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Checkpoint Belum Line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.xCircle, size: 13, color: Colors.red),
                            const SizedBox(width: 4),
                            const Text('Belum: ', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                belumStr,
                                style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String label, String value) {
    final isSelected = _categoryFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _categoryFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF43F5E) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
