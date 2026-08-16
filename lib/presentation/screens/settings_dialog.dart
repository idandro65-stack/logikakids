import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/local_store.dart';
import 'kotak_sampah_screen.dart';
import 'login_screen.dart';

class SettingsDialog {
  static String formatLogTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final mStr = months[dt.month - 1];
      final timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      return "${dt.day} $mStr ${dt.year}, $timeStr";
    } catch (_) {
      return timestamp;
    }
  }

  static void show(BuildContext context) {
    final store = LocalStore.instance;
    final currentUser = store.currentUser;
    final isAdmin = currentUser?.role == 'admin';

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
                'PENGATURAN & BACKUP DATA',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 6),

              // Ganti Password Option
              ListTile(
                leading: const Icon(LucideIcons.keyRound, color: Color(0xFFF43F5E)),
                title: const Text('Ganti Password Saya', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Ubah kata sandi akun ini', style: TextStyle(fontSize: 10)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangePasswordModal(context, store);
                },
              ),

              // Backup Data JSON (Available to All)
              ListTile(
                leading: const Icon(LucideIcons.downloadCloud, color: Color(0xFF0D9488)),
                title: const Text('Backup Seluruh Data (JSON)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Simpan berkas cadangan data anak & notulen', style: TextStyle(fontSize: 10)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportBackupJson(context, store);
                },
              ),

              // Admin Options
              if (isAdmin) ...[
                const Divider(),
                const Text(
                  'KHUSUS ADMIN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Color(0xFFF43F5E)),
                  title: Row(
                    children: [
                      const Text('Kotak Sampah & Pemulihan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (store.trashItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${store.trashItems.length}',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: const Text('Pulihkan data yang terhapus per item atau hapus permanen', style: TextStyle(fontSize: 10)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const KotakSampahScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.clock, color: Color(0xFF7C3AED)),
                  title: const Text('Masa Simpan Sampah Otomatis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    store.trashRetentionDays == -1
                        ? 'Status: Selamanya (Tidak dihapus otomatis)'
                        : 'Status: Dihapus otomatis setelah ${store.trashRetentionDays} hari',
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showTrashRetentionModal(context, store);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.scrollText, color: Color(0xFFF43F5E)),
                  title: const Text('Log Aktivitas Klinik (Audit Trail)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Rekam jejak tindakan staf & admin', style: TextStyle(fontSize: 10)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAuditLogsModal(context, store);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.fileText, color: Color(0xFF2563EB)),
                  title: const Text('Export Log Aktivitas (.txt)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Unduh catatan aktivitas staf ke file .txt (Admin)', style: TextStyle(fontSize: 10)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportAuditLogTxt(context, store);
                  },
                ),
              ],

              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.refreshCw, color: Color(0xFFF43F5E)),
                title: const Text('Cek Pembaruan & Unduh APK Terbaru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Unduh rilis APK terbaru dari GitHub untuk di-update', style: TextStyle(fontSize: 10)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('https://github.com/idandro65-stack/logikakids/actions');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
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

  static Future<void> _exportBackupJson(BuildContext context, LocalStore store) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(now);
      final filename = 'backup_logikakids_$dateStr.json';

      final backupData = {
        'app': 'Logika Kids',
        'version': '1.0.0',
        'exported_at': now.toIso8601String(),
        'children': store.children.map((e) => e.toJson()).toList(),
        'notulens': store.notulens.map((e) => e.toJson()).toList(),
        'programs': store.programs.map((e) => e.toJson()).toList(),
        'bundas': store.bundas.map((e) => e.toJson()).toList(),
        'users': store.users.map((e) => e.toJson()).toList(),
        'custom_rooms': store.allRooms,
        'logs': store.logs.map((e) => e.toJson()).toList(),
      };

      final jsonString = jsonEncode(backupData);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(jsonString, encoding: utf8);

      final xFile = XFile(filePath, mimeType: 'application/json', name: filename);
      await Share.shareXFiles([xFile], text: 'Backup Seluruh Data Klinik Logika Kids (JSON)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat backup data: $e')),
        );
      }
    }
  }

  static Future<void> _exportAuditLogTxt(BuildContext context, LocalStore store) async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(now);
      final filename = 'log_aktivitas_logikakids_$dateStr.txt';

      final sb = StringBuffer();
      sb.writeln('====================================================');
      sb.writeln('LOG AKTIVITAS KLINIK LOGIKA KIDS (AUDIT TRAIL)');
      sb.writeln('Tanggal Export: ${DateFormat('dd MMM yyyy, HH:mm').format(now)}');
      sb.writeln('Total Log: ${store.logs.length} catatan aktivitas');
      sb.writeln('====================================================\n');

      for (int i = 0; i < store.logs.length; i++) {
        final l = store.logs[i];
        sb.writeln('${i + 1}. [${formatLogTimestamp(l.timestamp)}] ${l.userName} (${l.role.toUpperCase()})');
        sb.writeln('   Tindakan: ${l.action}');
        sb.writeln('   Deskripsi: ${l.description}\n');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';
      final file = File(filePath);
      await file.writeAsString(sb.toString(), encoding: utf8);

      final xFile = XFile(filePath, mimeType: 'text/plain', name: filename);
      await Share.shareXFiles([xFile], text: 'Export Log Aktivitas Klinik Logika Kids (.txt)');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export log ke .txt: $e')),
        );
      }
    }
  }

  static void _showChangePasswordModal(BuildContext context, LocalStore store) {
    final pwCtrl = TextEditingController();

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
                'Ganti Password Saya',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBE123C),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: Icon(LucideIcons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (pwCtrl.text.trim().isNotEmpty && store.currentUser != null) {
                      store.updatePassword(store.currentUser!.username, pwCtrl.text.trim());
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password berhasil diperbarui!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
                  icon: const Icon(LucideIcons.check, color: Colors.white),
                  label: const Text('Simpan Password', style: TextStyle(color: Colors.white)),
                ),
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
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final logs = store.logs;
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.history, color: Color(0xFFF43F5E)),
                      SizedBox(width: 8),
                      Text(
                        'Log Aktivitas (Audit Trail)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportAuditLogTxt(context, store);
                    },
                    icon: const Icon(LucideIcons.download, size: 16),
                    label: const Text('Export .txt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.description, style: const TextStyle(fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(formatLogTimestamp(l.timestamp), style: const TextStyle(fontSize: 10, color: Color(0xFF991B1B), fontWeight: FontWeight.w600)),
                                ],
                              ),
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

  static void _showTrashRetentionModal(BuildContext context, LocalStore store) {
    final options = [
      {'label': '7 Hari', 'value': 7},
      {'label': '14 Hari', 'value': 14},
      {'label': '30 Hari (Rekomendasi Standar)', 'value': 30},
      {'label': '60 Hari', 'value': 60},
      {'label': '90 Hari', 'value': 90},
      {'label': 'Selamanya (Simpan Sampah Permanen)', 'value': -1},
    ];

    showModalBottomSheet(
      context: context,
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
              const Row(
                children: [
                  Icon(LucideIcons.clock, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'Atur Masa Simpan Sampah',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Data yang berada di kotak sampah lebih lama dari batas waktu yang dipilih akan dibersihkan secara otomatis oleh sistem.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              ...options.map((opt) {
                final isSelected = store.trashRetentionDays == opt['value'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.black87,
                    ),
                  ),
                  leading: Icon(
                    isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                    color: isSelected ? const Color(0xFF7C3AED) : Colors.grey,
                    size: 18,
                  ),
                  onTap: () {
                    store.setTrashRetentionDays(opt['value'] as int);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Masa simpan sampah disetel ke: ${opt['label']}')),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
