import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/datasources/local_store.dart';
import 'login_screen.dart';

class SettingsDialog {
  static void show(BuildContext context) {
    final store = LocalStore.instance;
    final currentUser = store.currentUser;
    final isAdmin = currentUser?.role == 'admin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFF43F5E),
                      child: Text(
                        (currentUser?.name ?? 'Terapis')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.name ?? 'Terapis',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          isAdmin ? 'Kepala Klinik / Admin' : 'Bunda Terapis',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'AKUN & KEAMANAN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),

              // Admin Audit Log Option (Only for Admin)
              if (isAdmin)
                ListTile(
                  leading: const Icon(LucideIcons.scrollText, color: Color(0xFFF43F5E)),
                  title: const Text('Log Aktivitas Klinik (Audit Trail)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Rekam jejak tindakan staf & admin', style: TextStyle(fontSize: 10)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAuditLogsModal(context, store);
                  },
                ),

              // Reset Data (STRICTLY ADMIN ONLY)
              if (isAdmin)
                ListTile(
                  leading: const Icon(LucideIcons.rotateCcw, color: Colors.orange),
                  title: const Text('Reset Data ke Demo Awal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Hapus notulen uji coba (Khusus Admin)', style: TextStyle(fontSize: 10)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hanya Admin yang berwenang melakukan reset data.')),
                    );
                  },
                ),

              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: Colors.red),
                title: const Text('Keluar / Logout Sesi Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  store.logout();
                  Navigator.pop(ctx);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showAuditLogsModal(BuildContext context, LocalStore store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final logs = store.logs;
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.history, color: Color(0xFFF43F5E)),
                  SizedBox(width: 8),
                  Text(
                    'Log Aktivitas Klinik (Audit Trail)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 350,
                child: logs.isEmpty
                    ? const Center(child: Text('Belum ada data log aktivitas', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (ctx, idx) {
                          final l = logs[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            color: const Color(0xFFFFF1F2),
                            child: ListTile(
                              title: Text('${l.userName} (${l.role.toUpperCase()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              subtitle: Text(l.description, style: const TextStyle(fontSize: 11)),
                              trailing: Text(l.timestamp.substring(11, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
}
