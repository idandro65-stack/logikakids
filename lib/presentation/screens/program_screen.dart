import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/program_model.dart';

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  Future<void> _confirmDeleteProgram(ProgramModel prog) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus Program', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Yakin ingin menghapus program terapi \'${prog.programName}\' dari ruang ${prog.room}?', style: const TextStyle(fontSize: 13)),
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
      LocalStore.instance.deleteProgram(prog.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Program terapi \'${prog.programName}\' berhasil dipindahkan ke Kotak Sampah')),
        );
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
        content: Text('Apakah Anda yakin ingin menghapus ruang terapi \'$roomName\'?', style: const TextStyle(fontSize: 13)),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruang terapi \'$roomName\' berhasil dipindahkan ke Kotak Sampah')),
        );
      }
    }
  }

  void _showAddRoomModal(BuildContext context, LocalStore store) {
    final roomCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom +
                20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Ruang Terapi Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBE123C),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Ruangan (Contoh: Snoezelen / Hydrotherapy)',
                  prefixIcon: Icon(LucideIcons.doorOpen),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (roomCtrl.text.trim().isNotEmpty) {
                      store.addRoom(roomCtrl.text.trim());
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Berhasil menambah ruang ${roomCtrl.text.trim()}')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                  icon: const Icon(LucideIcons.check, color: Colors.white),
                  label: const Text('Simpan Ruang Terapi', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProgramModal(BuildContext context, LocalStore store) {
    final nameCtrl = TextEditingController();
    final indicatorsCtrl = TextEditingController();
    final rooms = store.allRooms;
    String selectedRoom = rooms.isNotEmpty ? rooms[0] : 'Sensori Integrasi';
    int targetPoints = 10;

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
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom +
                    20,
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
                    initialValue: selectedRoom,
                    decoration: const InputDecoration(
                      labelText: 'Ruang Terapi',
                      border: OutlineInputBorder(),
                    ),
                    items: store.allRooms.map((r) {
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
                            id: 'SUB_prog_${DateTime.now().millisecondsSinceEpoch}',
                            room: selectedRoom,
                            programName: nameCtrl.text.trim(),
                            indicators: cleanInds.isEmpty ? ['Latihan Dasar'] : cleanInds,
                            targetPoints: targetPoints,
                          );

                          store.addProgram(newProg);
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

  void _showEditProgramModal(BuildContext context, ProgramModel prog, LocalStore store) {
    final nameCtrl = TextEditingController(text: prog.programName);
    final indicatorsCtrl = TextEditingController(text: prog.indicators.join(', '));
    String selectedRoom = store.allRooms.contains(prog.room) ? prog.room : (store.allRooms.isNotEmpty ? store.allRooms[0] : 'Sensori Integrasi');

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
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom +
                    MediaQuery.of(ctx).padding.bottom +
                    20,
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
                    initialValue: selectedRoom,
                    decoration: const InputDecoration(
                      labelText: 'Ruang Terapi',
                      border: OutlineInputBorder(),
                    ),
                    items: store.allRooms.map((r) {
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

                          store.updateProgram(updated);
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
        final allRooms = store.allRooms;
        final isAdmin = store.currentUser?.role == 'admin';

        return Scaffold(
          floatingActionButton: isAdmin
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'btn_add_room',
                      onPressed: () => _showAddRoomModal(context, store),
                      backgroundColor: Colors.teal,
                      icon: const Icon(LucideIcons.doorOpen, color: Colors.white, size: 18),
                      label: const Text('Ruangan Baru', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.extended(
                      heroTag: 'btn_add_prog',
                      onPressed: () => _showAddProgramModal(context, store),
                      backgroundColor: const Color(0xFFF43F5E),
                      icon: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
                      label: const Text('Program Baru', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                )
              : null,
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: allRooms.length,
            itemBuilder: (ctx, idx) {
              final roomName = allRooms[idx];
              final roomProgs =
                  programs.where((p) => p.room == roomName).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  onLongPress: () => _confirmDeleteRoom(roomName),
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
                      '${roomProgs.length} Program Terapi (Tahan untuk hapus)',
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
                                          onPressed: () => _showEditProgramModal(context, prog, store),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.red),
                                          onPressed: () => _confirmDeleteProgram(prog),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
