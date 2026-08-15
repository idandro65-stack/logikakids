import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/notulen_model.dart';
import '../../data/models/child_model.dart';
import '../../data/models/program_model.dart';

class InputNotulenScreen extends StatefulWidget {
  final NotulenModel? editNotulen;
  const InputNotulenScreen({super.key, this.editNotulen});

  @override
  State<InputNotulenScreen> createState() => _InputNotulenScreenState();
}

class _InputNotulenScreenState extends State<InputNotulenScreen> {
  late TextEditingController _dateController;
  final TextEditingController _childSearchController = TextEditingController();
  final TextEditingController _programSearchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedChild;
  String? _selectedBunda;
  Set<String> _selectedRooms = {};

  final List<String> _selectedPrograms = [];
  final Map<String, List<int>> _pointsMap = {};
  final Map<String, String> _statusMap = {};

  @override
  void initState() {
    super.initState();
    final store = LocalStore.instance;

    if (widget.editNotulen != null) {
      final n = widget.editNotulen!;
      _dateController = TextEditingController(text: n.date);
      _selectedChild = n.childName;
      _selectedBunda = n.notulen;
      _selectedRooms = n.room.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
      _selectedPrograms.addAll(n.programsSelected);
      _statusMap.addAll(n.status);

      n.pointsAchieved.forEach((k, v) {
        if (v is List) {
          _pointsMap[k] = v.map((e) => (e as num).toInt()).toList();
        }
      });
      _notesController.text = n.notes;
    } else {
      _dateController = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
      if (store.children.isNotEmpty) {
        _selectedChild = store.children[0].name;
      }
      if (store.currentUser != null) {
        _selectedBunda = store.currentUser!.name;
      } else if (store.bundas.isNotEmpty) {
        _selectedBunda = store.bundas[0].name;
      }
      if (store.allRooms.isNotEmpty) {
        _selectedRooms = {store.allRooms[0]};
      }
    }
  }

  Future<void> _confirmDeleteRoom(String roomName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Ruang Terapi?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Yakin ingin menghapus ruang terapi \'$roomName\'?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Ruangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LocalStore.instance.deleteRoom(roomName);
      setState(() {
        _selectedRooms.remove(roomName);
        if (_selectedRooms.isEmpty && LocalStore.instance.allRooms.isNotEmpty) {
          _selectedRooms.add(LocalStore.instance.allRooms[0]);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruang terapi \'$roomName\' telah dihapus')),
        );
      }
    }
  }

  void _saveNotulen() {
    if (_selectedChild == null || _selectedBunda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih data anak dan terapis')),
      );
      return;
    }

    if (_selectedRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih minimal 1 ruang terapi')),
      );
      return;
    }

    final store = LocalStore.instance;
    final isEdit = widget.editNotulen != null;

    final notulenObj = NotulenModel(
      id: isEdit ? widget.editNotulen!.id : 'SUB_notulen_${DateTime.now().millisecondsSinceEpoch}',
      date: _dateController.text,
      childName: _selectedChild!,
      notulen: _selectedBunda!,
      room: _selectedRooms.join('; '),
      programsSelected: _selectedPrograms,
      pointsAchieved: _pointsMap,
      status: _statusMap,
      notes: _notesController.text.trim(),
    );

    if (isEdit) {
      store.updateNotulen(notulenObj);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notulen sesi berhasil diperbarui & disimpan!')),
      );
    } else {
      store.addNotulen(notulenObj);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notulen harian berhasil disimpan!')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;

    // Filter Children by Search Query
    List<ChildModel> filteredChildren = store.children;
    if (_childSearchController.text.isNotEmpty) {
      final q = _childSearchController.text.toLowerCase();
      filteredChildren = filteredChildren.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    // Get Past Achieved Points per program for the selected child to LOCK achieved indicators!
    final pastAchievedPointsMap = _selectedChild != null
        ? store.getChildPastAchievedPoints(_selectedChild!, excludeNotulenId: widget.editNotulen?.id)
        : <String, Set<int>>{};

    // Completed Programs Set
    final completedSet = _selectedChild != null
        ? store.getChildCompletedPrograms(_selectedChild!, excludeNotulenId: widget.editNotulen?.id)
        : <String>{};

    // Available Programs for Selected Rooms
    var availablePrograms = store.programs
        .where((p) => _selectedRooms.contains(p.room))
        .toList();

    // Filter Programs by Search Bar
    if (_programSearchController.text.isNotEmpty) {
      final q = _programSearchController.text.toLowerCase();
      availablePrograms = availablePrograms
          .where((p) => p.programName.toLowerCase().contains(q) || p.room.toLowerCase().contains(q))
          .toList();
    }

    final isEdit = widget.editNotulen != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Notulen Sesi' : 'Input Notulen Terapi Harian'),
        backgroundColor: const Color(0xFFF43F5E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Date Picker
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Tanggal Sesi Terapi',
                prefixIcon: Icon(LucideIcons.calendar),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              },
            ),
            const SizedBox(height: 14),

            // 2. Search Child & Select Dropdown
            TextField(
              controller: _childSearchController,
              onChanged: (val) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Cari Nama Anak...',
                prefixIcon: Icon(LucideIcons.search),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              key: ValueKey(_selectedChild ?? 'none'),
              initialValue: filteredChildren.any((c) => c.name == _selectedChild) ? _selectedChild : null,
              decoration: const InputDecoration(
                labelText: 'Pilih Nama Anak',
                prefixIcon: Icon(LucideIcons.user),
                border: OutlineInputBorder(),
              ),
              items: filteredChildren.map((c) {
                return DropdownMenuItem(
                  value: c.name,
                  child: Text('${c.name} (${c.category.toUpperCase()})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedChild = val;
                });
              },
            ),
            const SizedBox(height: 14),

            // 3. Multi-Select Room Selector Chips (Hold/Long-Press to Delete!)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Pilih Ruang Terapi (Bisa Lebih Dari 1):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Tahan tombol untuk hapus',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: store.allRooms.map((room) {
                final isSelected = _selectedRooms.contains(room);
                return InkWell(
                  onLongPress: () => _confirmDeleteRoom(room),
                  child: FilterChip(
                    label: Text(room),
                    selected: isSelected,
                    selectedColor: const Color(0xFFF43F5E),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRooms.add(room);
                        } else {
                          if (_selectedRooms.length > 1) {
                            _selectedRooms.remove(room);
                          }
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 4. Search Bar for Programs & Multi-Select Program Checkboxes
            const Text(
              'Pilih Program Terapi (Dapat Dicentang Banyak):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _programSearchController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama program terapi...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            if (availablePrograms.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Program tidak ditemukan atau pilih ruangan di atas...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              )
            else
              ...availablePrograms.map((prog) {
                final isCompleted = completedSet.contains(prog.id) || completedSet.contains(prog.programName);
                final isChecked = _selectedPrograms.contains(prog.programName);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isCompleted ? Colors.grey.shade100 : null,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                prog.programName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? Colors.grey : Colors.black87,
                                ),
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Tuntas (Sesi Lalu)',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('${prog.room} | ${prog.indicators.length} Indikator Checkpoint', style: const TextStyle(fontSize: 11)),
                        value: isChecked,
                        activeColor: const Color(0xFFF43F5E),
                        onChanged: isCompleted
                            ? null
                            : (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedPrograms.add(prog.programName);
                                    _statusMap[prog.programName] = 'S';
                                  } else {
                                    _selectedPrograms.remove(prog.programName);
                                  }
                                });
                              },
                      ),

                      // Checkpoint Indicators List if Program Selected
                      if (isChecked) ...[
                        const Divider(height: 1),
                        _buildIndicatorChecklist(prog, pastAchievedPointsMap),
                      ],
                    ],
                  ),
                );
              }),

            const SizedBox(height: 14),

            // 5. Select Terapis (Bunda)
            DropdownButtonFormField<String>(
              initialValue: _selectedBunda,
              decoration: const InputDecoration(
                labelText: 'Bunda Terapis Pencatat',
                prefixIcon: Icon(LucideIcons.userCheck),
                border: OutlineInputBorder(),
              ),
              items: (store.bundas.isNotEmpty
                      ? store.bundas.map((b) => b.name).toList()
                      : ['Ani', 'Eka', 'Lia', 'Mila', 'Oza'])
                  .map((name) {
                return DropdownMenuItem(
                  value: name,
                  child: Text('Bunda $name'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedBunda = val),
            ),
            const SizedBox(height: 14),

            // 6. Notes TextField
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Khusus Perkembangan Anak',
                hintText: 'Tuliskan perkembangan penting sesi hari ini...',
                prefixIcon: Icon(LucideIcons.fileEdit),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveNotulen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(isEdit ? LucideIcons.save : LucideIcons.check, color: Colors.white, size: 18),
              label: Text(
                isEdit ? 'Simpan Perubahan Notulen' : 'Simpan Notulen Sesi',
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorChecklist(ProgramModel prog, Map<String, Set<int>> pastAchievedMap) {
    final progKey = prog.programName;
    final pastAchieved = pastAchievedMap[prog.id] ?? pastAchievedMap[progKey] ?? <int>{};
    final currentSessionPoints = _pointsMap[progKey] ?? <int>[];

    final targetPoints = prog.targetPoints > 0 ? prog.targetPoints : 10;
    final indicatorsList = prog.indicators;

    final allUnlockedIndices = List.generate(targetPoints, (i) => i + 1).where((idx) => !pastAchieved.contains(idx)).toList();
    final isAllUnlockedChecked = allUnlockedIndices.isNotEmpty && allUnlockedIndices.every((idx) => currentSessionPoints.contains(idx));

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Checkpoints Indikator:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text('${currentSessionPoints.length + pastAchieved.length} / $targetPoints tercapai', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    if (!_pointsMap.containsKey(progKey)) {
                      _pointsMap[progKey] = [];
                    }
                    if (!isAllUnlockedChecked) {
                      for (var idx in allUnlockedIndices) {
                        if (!_pointsMap[progKey]!.contains(idx)) {
                          _pointsMap[progKey]!.add(idx);
                        }
                      }
                      _statusMap[progKey] = 'S';
                    } else {
                      _pointsMap[progKey]!.clear();
                      _statusMap[progKey] = 'BS';
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: isAllUnlockedChecked,
                          activeColor: const Color(0xFFF43F5E),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setState(() {
                              if (!_pointsMap.containsKey(progKey)) {
                                _pointsMap[progKey] = [];
                              }
                              if (val == true) {
                                for (var idx in allUnlockedIndices) {
                                  if (!_pointsMap[progKey]!.contains(idx)) {
                                    _pointsMap[progKey]!.add(idx);
                                  }
                                }
                                _statusMap[progKey] = 'S';
                              } else {
                                _pointsMap[progKey]!.clear();
                                _statusMap[progKey] = 'BS';
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

          // Render Checkpoints / Indicators
          ...List.generate(targetPoints, (i) {
            final pointNum = i + 1; // 1-based indicator number
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
                    Expanded(
                      child: Text(
                        labelText,
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('✓ Tercapai (Sesi Lalu)', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }

            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(labelText, style: const TextStyle(fontSize: 12)),
              value: isCurrentChecked,
              activeColor: const Color(0xFFF43F5E),
              onChanged: (val) {
                setState(() {
                  if (!_pointsMap.containsKey(progKey)) {
                    _pointsMap[progKey] = [];
                  }
                  if (val == true) {
                    if (!_pointsMap[progKey]!.contains(pointNum)) {
                      _pointsMap[progKey]!.add(pointNum);
                    }
                  } else {
                    _pointsMap[progKey]!.remove(pointNum);
                  }

                  final totalNow = _pointsMap[progKey]!.length + pastAchieved.length;
                  _statusMap[progKey] = (totalNow >= targetPoints) ? 'S' : 'BS';
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
