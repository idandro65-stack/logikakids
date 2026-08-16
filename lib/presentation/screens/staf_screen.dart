import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/user_model.dart';

class StafScreen extends StatefulWidget {
  const StafScreen({super.key});

  @override
  State<StafScreen> createState() => _StafScreenState();
}

class _StafScreenState extends State<StafScreen> {
  Future<void> _confirmDeleteStaff(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Yakin ingin menghapus akun staf \'${user.name}\' (${user.username})? Akun ini tidak dapat mengakses aplikasi lagi.', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LocalStore.instance.deleteUser(user.username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Akun staf \'${user.name}\' berhasil dipindahkan ke Kotak Sampah')),
        );
      }
    }
  }

  void _showAddStaffModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    String role = 'staf';

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
                    'Tambah Staf / Admin Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Staf / Terapis',
                      prefixIcon: Icon(LucideIcons.user),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username Akses',
                      prefixIcon: Icon(LucideIcons.atSign),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(LucideIcons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Bunda Terapis (Staf)', style: TextStyle(fontSize: 11)),
                          value: 'staf',
                          groupValue: role,
                          onChanged: (val) => setModalState(() => role = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Admin Klinik', style: TextStyle(fontSize: 11)),
                          value: 'admin',
                          groupValue: role,
                          onChanged: (val) => setModalState(() => role = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameCtrl.text.trim().isNotEmpty && userCtrl.text.trim().isNotEmpty) {
                          final newUser = UserModel(
                            username: userCtrl.text.trim().toLowerCase(),
                            password: pwCtrl.text.trim().isEmpty ? '123456' : pwCtrl.text.trim(),
                            name: nameCtrl.text.trim(),
                            role: role,
                          );
                          LocalStore.instance.addUser(newUser);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Berhasil menambahkan staf ${newUser.name}')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                      icon: const Icon(LucideIcons.check, color: Colors.white),
                      label: const Text('Simpan Staf Baru', style: TextStyle(color: Colors.white)),
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

  void _showEditStaffModal(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final userCtrl = TextEditingController(text: user.username);
    final pwCtrl = TextEditingController(text: user.password);
    String role = user.role;

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
                    'Edit Data Staf',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Staf',
                      prefixIcon: Icon(LucideIcons.user),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: userCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Username (Tidak dapat diubah)',
                      prefixIcon: Icon(LucideIcons.atSign),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pwCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru',
                      prefixIcon: Icon(LucideIcons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Bunda Terapis (Staf)', style: TextStyle(fontSize: 11)),
                          value: 'staf',
                          groupValue: role,
                          onChanged: (val) => setModalState(() => role = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Admin Klinik', style: TextStyle(fontSize: 11)),
                          value: 'admin',
                          groupValue: role,
                          onChanged: (val) => setModalState(() => role = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final updated = UserModel(
                          username: user.username,
                          password: pwCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          role: role,
                        );
                        LocalStore.instance.updateUser(updated);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Berhasil memperbarui staf ${updated.name}')),
                        );
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

  void _showStaffHistoryModal(BuildContext context, UserModel user) {
    final staffNotulens = LocalStore.instance.notulens.where((n) {
      final nameClean = user.name.toLowerCase().replaceAll('bunda.', '').trim();
      final notulenClean = n.notulen.toLowerCase().replaceAll('bunda.', '').trim();
      return notulenClean.contains(nameClean) || nameClean.contains(notulenClean);
    }).toList();

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
              Text(
                'Riwayat Notulen: Bunda ${user.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBE123C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Total ${staffNotulens.length} Sesi Terapi Dikerjakan',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Divider(height: 20),
              SizedBox(
                height: 350,
                child: staffNotulens.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat notulen dari terapis ini',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: staffNotulens.length,
                        itemBuilder: (ctx, idx) {
                          final n = staffNotulens[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(n.childName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Tanggal: ${n.date} | Ruang: ${n.room}', style: const TextStyle(fontSize: 11)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
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
        final isAdmin = store.currentUser?.role == 'admin';

        if (!isAdmin) {
          return const Center(
            child: Text(
              'Menu Staf hanya untuk Kepala Klinik (Admin)',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final users = store.users;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddStaffModal(context),
            backgroundColor: const Color(0xFFF43F5E),
            child: const Icon(LucideIcons.plus, color: Colors.white),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (ctx, idx) {
              final u = users[idx];
              final isStaffAdmin = u.role == 'admin';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStaffAdmin ? const Color(0xFFFFF1F2) : Colors.blue.shade50,
                    child: Icon(
                      isStaffAdmin ? LucideIcons.shieldCheck : LucideIcons.user,
                      color: isStaffAdmin ? const Color(0xFFF43F5E) : Colors.blue,
                    ),
                  ),
                  title: Text(
                    u.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Username: ${u.username} | Role: ${u.role.toUpperCase()}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.history, size: 18, color: Colors.teal),
                        onPressed: () => _showStaffHistoryModal(context, u),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                        onPressed: () => _showEditStaffModal(context, u),
                      ),
                      if (u.username != 'admin')
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                          onPressed: () => _confirmDeleteStaff(u),
                        ),
                    ],
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
