import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app_config.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/program_model.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  void _showAddProgramModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final indicatorsCtrl = TextEditingController();
    String selectedRoom = AppConfig.rooms[0];
    int targetPoints = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Program Terapi Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedRoom,
                    decoration: const InputDecoration(
                      labelText: 'Ruang Terapi',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConfig.rooms.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedRoom = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Program Terapi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: indicatorsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Indikator Point (Pisahkan dengan koma / baris baru)',
                      hintText: 'Contoh: Ayunan, Papan Keseimbangan, Lempar Bola',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameCtrl.text.trim().isNotEmpty) {
                          final rawInds = indicatorsCtrl.text.split(RegExp(r'[,\n]'));
                          final cleanInds = rawInds
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          final newProg = ProgramModel(
                            id: 'prog_${DateTime.now().millisecondsSinceEpoch}',
                            room: selectedRoom,
                            programName: nameCtrl.text.trim(),
                            indicators: cleanInds.isEmpty ? ['Latihan Dasar'] : cleanInds,
                            targetPoints: targetPoints,
                          );

                          LocalStore.instance.addProgram(newProg);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Berhasil menambahkan program ${newProg.programName}')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                      icon: const Icon(LucideIcons.check, color: Colors.white),
                      label: const Text('Simpan Program Baru', style: TextStyle(color: Colors.white)),
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

  void _showEditProgramModal(BuildContext context, ProgramModel prog) {
    final nameCtrl = TextEditingController(text: prog.programName);
    final indicatorsCtrl = TextEditingController(text: prog.indicators.join(', '));
    String selectedRoom = prog.room;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Program Terapi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedRoom,
                    decoration: const InputDecoration(
                      labelText: 'Ruang Terapi',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConfig.rooms.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedRoom = val!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Program Terapi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: indicatorsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Indikator Point (Pisahkan dengan koma / baris baru)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameCtrl.text.trim().isNotEmpty) {
                          final rawInds = indicatorsCtrl.text.split(RegExp(r'[,\n]'));
                          final cleanInds = rawInds
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          final updated = ProgramModel(
                            id: prog.id,
                            room: selectedRoom,
                            programName: nameCtrl.text.trim(),
                            indicators: cleanInds.isEmpty ? prog.indicators : cleanInds,
                            targetPoints: prog.targetPoints,
                          );

                          LocalStore.instance.updateProgram(updated);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Berhasil memperbarui program ${updated.programName}')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                      icon: const Icon(LucideIcons.save, color: Colors.white),
                      label: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white)),
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
        final programs = store.programs;
        final isAdmin = store.currentUser?.role == 'admin';

        return Scaffold(
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () => _showAddProgramModal(context),
                  backgroundColor: const Color(0xFFF43F5E),
                  child: const Icon(LucideIcons.plus, color: Colors.white),
                )
              : null,
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: AppConfig.rooms.length,
            itemBuilder: (ctx, idx) {
              final roomName = AppConfig.rooms[idx];
              final roomProgs =
                  programs.where((p) => p.room == roomName).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1F2),
                    child: Icon(LucideIcons.clipboardList, color: Color(0xFFF43F5E)),
                  ),
                  title: Text(
                    roomName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${roomProgs.length} Program Terapi',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  children: roomProgs.isEmpty
                      ? const [
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Belum ada program untuk ruangan ini',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          )
                        ]
                      : roomProgs.map((prog) {
                          return ListTile(
                            title: Text(
                              prog.programName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${prog.indicators.length} Indikator Point Pencapaian',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: isAdmin
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(LucideIcons.edit2, size: 16, color: Colors.blue),
                                        onPressed: () => _showEditProgramModal(context, prog),
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                        onPressed: () => LocalStore.instance.deleteProgram(prog.id),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
