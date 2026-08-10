import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app_config.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/notulen_model.dart';

class InputNotulenScreen extends StatefulWidget {
  const InputNotulenScreen({super.key});

  @override
  State<InputNotulenScreen> createState() => _InputNotulenScreenState();
}

class _InputNotulenScreenState extends State<InputNotulenScreen> {
  final _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  String? _selectedChild;
  String? _selectedBunda;
  final Set<String> _selectedRooms = {AppConfig.rooms[0]};
  final _notesController = TextEditingController();

  final List<String> _selectedPrograms = [];
  final Map<String, List<int>> _pointsMap = {};
  final Map<String, String> _statusMap = {};

  @override
  void initState() {
    super.initState();
    final store = LocalStore.instance;
    if (store.children.isNotEmpty) {
      _selectedChild = store.children[0].name;
    }
    if (store.currentUser != null) {
      _selectedBunda = store.currentUser!.name;
    } else if (store.bundas.isNotEmpty) {
      _selectedBunda = store.bundas[0].name;
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

    final newNotulen = NotulenModel(
      id: 'notulen_${DateTime.now().millisecondsSinceEpoch}',
      date: _dateController.text,
      childName: _selectedChild!,
      notulen: _selectedBunda!,
      room: _selectedRooms.join('; '),
      programsSelected: _selectedPrograms,
      pointsAchieved: _pointsMap,
      status: _statusMap,
      notes: _notesController.text.trim(),
    );

    LocalStore.instance.addNotulen(newNotulen);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notulen harian berhasil disimpan!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final children = store.children;
    final bundas = store.bundas;

    // Filter available programs in ANY of the selected rooms
    final availablePrograms = store.programs
        .where((p) => _selectedRooms.contains(p.room))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Notulen Terapi Harian'),
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

            // 2. Select Child
            DropdownButtonFormField<String>(
              initialValue: _selectedChild,
              decoration: const InputDecoration(
                labelText: 'Pilih Nama Anak',
                prefixIcon: Icon(LucideIcons.user),
                border: OutlineInputBorder(),
              ),
              items: children.map((c) {
                return DropdownMenuItem(
                  value: c.name,
                  child: Text('${c.name} (${c.category.toUpperCase()})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedChild = val),
            ),
            const SizedBox(height: 14),

            // 3. Room Selector Chips (Multi-Select Enabled!)
            const Text(
              'Pilih Ruang Terapi (Bisa Lebih Dari 1):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: AppConfig.rooms.map((room) {
                final isSelected = _selectedRooms.contains(room);
                return FilterChip(
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
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 4. Multi-Select Programs
            const Text(
              'Pilih Program Terapi (Dapat Dicentang Banyak):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (availablePrograms.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Pilih ruangan terapi untuk menampilkan program...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              )
            else
              ...availablePrograms.map((prog) {
                final isChecked = _selectedPrograms.contains(prog.programName);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          prog.programName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text('${prog.room} | ${prog.indicators.length} Indikator Point', style: const TextStyle(fontSize: 11)),
                        value: isChecked,
                        activeColor: const Color(0xFFF43F5E),
                        onChanged: (val) {
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

                      // Status Selector if Checked
                      if (isChecked)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status Hasil Program:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildStatusChip(prog.programName, 'S', 'Sudah (S)', Colors.green),
                                  const SizedBox(width: 4),
                                  _buildStatusChip(prog.programName, 'BS', 'Belum (BS)', Colors.orange),
                                  const SizedBox(width: 4),
                                  _buildStatusChip(prog.programName, 'TS', 'Tidak (TS)', Colors.red),
                                  const SizedBox(width: 4),
                                  _buildStatusChip(prog.programName, 'K', 'Konsisten (K)', Colors.teal),
                                ],
                              ),
                            ],
                          ),
                        ),
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
              items: (bundas.isNotEmpty
                      ? bundas.map((b) => b.name).toList()
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
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveNotulen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                ),
                icon: const Icon(LucideIcons.save, color: Colors.white),
                label: const Text(
                  'Simpan Notulen Sesi',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String progName, String val, String label, Color color) {
    final isSelected = (_statusMap[progName] ?? 'S') == val;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _statusMap[progName] = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
