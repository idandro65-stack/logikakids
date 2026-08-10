import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app_config.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/notulen_model.dart';

class InputNotulenScreen extends StatefulWidget {
  const InputNotulenScreen({Key? key}) : super(key: key);

  @override
  State<InputNotulenScreen> createState() => _InputNotulenScreenState();
}

class _InputNotulenScreenState extends State<InputNotulenScreen> {
  final _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  String? _selectedChild;
  String? _selectedBunda;
  String _selectedRoom = AppConfig.rooms[0];
  final _notesController = TextEditingController();

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

    final newNotulen = NotulenModel(
      id: 'notulen_${DateTime.now().millisecondsSinceEpoch}',
      date: _dateController.text,
      childName: _selectedChild!,
      notulen: _selectedBunda!,
      room: _selectedRoom,
      programsSelected: [],
      pointsAchieved: {},
      status: {},
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
            // Date Picker
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Tanggal Sesi Terapi',
                prefixIcon: Icon(Icons.calendar_today),
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

            // Select Child
            DropdownButtonFormField<String>(
              value: _selectedChild,
              decoration: const InputDecoration(
                labelText: 'Pilih Nama Anak',
                prefixIcon: Icon(Icons.child_care),
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

            // Select Room Chip Selector
            const Text(
              'Pilih Ruang Terapi:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: AppConfig.rooms.map((room) {
                final isSelected = _selectedRoom == room;
                return ChoiceChip(
                  label: Text(room),
                  selected: isSelected,
                  selectedColor: const Color(0xFFF43F5E),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRoom = room);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Notes TextField
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Khusus Perkembangan Anak',
                hintText: 'Tuliskan perkembangan penting sesi hari ini...',
                prefixIcon: Icon(Icons.edit_note),
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
                icon: const Icon(Icons.save, color: Colors.white),
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
}
