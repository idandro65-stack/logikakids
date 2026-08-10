import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app_config.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/notulen_model.dart';
import 'input_notulen_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showRoomDetailModal(BuildContext context, String roomName, LocalStore store) {
    final now = DateTime.now();
    final currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final monthNotulens = store.notulens.where((n) {
      return n.date.startsWith(currentMonthStr);
    }).toList();

    Map<String, int> childSessionCounts = {};
    for (var n in monthNotulens) {
      final rooms = n.room.split(';');
      final matchesRoom = rooms.any((r) => r.trim() == roomName);
      if (matchesRoom) {
        final cName = n.childName.isEmpty ? 'Lainnya' : n.childName;
        childSessionCounts[cName] = (childSessionCounts[cName] ?? 0) + 1;
      }
    }

    final sortedChildren = childSessionCounts.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final totalSesi = childSessionCounts.values.fold(0, (a, b) => a + b);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.doorOpen, color: Color(0xFFF43F5E)),
                      const SizedBox(width: 8),
                      Text(
                        'Ruang $roomName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text('$totalSesi Sesi Bulan Ini'),
                    backgroundColor: const Color(0xFFFFF1F2),
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
                child: sortedChildren.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada sesi notulen tercatat bulan ini di ruangan ini',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedChildren.length,
                        itemBuilder: (ctx, idx) {
                          final cName = sortedChildren[idx];
                          final count = childSessionCounts[cName] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFF1F2),
                                child: Icon(LucideIcons.user, color: Color(0xFFF43F5E), size: 18),
                              ),
                              title: Text(
                                cName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                '$count Sesi Terapi Bulan Ini',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: Chip(
                                label: Text('${count}x sesi'),
                                backgroundColor: Colors.teal.shade50,
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
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

  void _showNotulenDetailModal(BuildContext context, NotulenModel n) {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notulen: ${n.childName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBE123C),
                      ),
                    ),
                    Text(n.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ruang: ${n.room} | Terapis: Bunda ${n.notulen}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20),
                if (n.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.pin, size: 14, color: Color(0xFFBE123C)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Catatan: "${n.notes}"',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFBE123C), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text('Program Terapi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ...n.programsSelected.map((progId) {
                  final cleanName = LocalStore.instance.resolveProgramName(progId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cleanName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
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
        final children = store.children;
        final intensifCount = children.where((c) => c.category == 'intensif').length;
        final regulerCount = children.where((c) => c.category == 'reguler').length;
        final isAdmin = store.currentUser?.role == 'admin';

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Counter Card Stat
                Row(
                  children: [
                    _buildStatCard('TOTAL ANAK', '${children.length}', Colors.red),
                    const SizedBox(width: 8),
                    _buildStatCard('INTENSIF', '$intensifCount', Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('REGULER', '$regulerCount', Colors.teal),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Input Action Banner
                Card(
                  color: const Color(0xFFF43F5E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catat Sesi Hari Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Input notulen program terapi harian anak secara cepat dan terstruktur.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const InputNotulenScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFF43F5E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(LucideIcons.plusCircle),
                            label: const Text(
                              'Input Notulen Baru',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Admin Activity Log Widget (Only visible to Admin)
                if (isAdmin) _buildAdminLogWidget(context, store),

                // Rekap Sesi Ruangan Bulan Ini
                _buildRoomSummaryCard(context, store),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLogWidget(BuildContext context, LocalStore store) {
    final logs = store.logs.take(5).toList();
    return Card(
      color: const Color(0xFFFFF1F2),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFFECDD3)),
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(LucideIcons.history, size: 18, color: Color(0xFFBE123C)),
                SizedBox(width: 6),
                Text(
                  'Log Aktivitas Terkini Klinik',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBE123C),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFFECDD3)),
            if (logs.isEmpty)
              const Text(
                'Belum ada riwayat aktivitas tercatat.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            else
              ...logs.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      '• ${l.userName}: ${l.description}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomSummaryCard(BuildContext context, LocalStore store) {
    final now = DateTime.now();
    final currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final monthNotulens = store.notulens.where((n) => n.date.startsWith(currentMonthStr)).toList();

    Map<String, int> roomCounts = {};
    for (var r in AppConfig.rooms) {
      roomCounts[r] = 0;
    }

    for (var n in monthNotulens) {
      final rooms = n.room.split(';');
      for (var r in rooms) {
        final clean = r.trim();
        if (roomCounts.containsKey(clean)) {
          roomCounts[clean] = (roomCounts[clean] ?? 0) + 1;
        }
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(LucideIcons.barChart2, size: 18, color: Color(0xFFF43F5E)),
                    SizedBox(width: 6),
                    Text(
                      'Rekap Sesi Ruangan Bulan Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Klik Ruang Untuk Detail',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...AppConfig.rooms.map((room) {
              final count = roomCounts[room] ?? 0;
              return InkWell(
                onTap: () => _showRoomDetailModal(context, room, store),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.doorOpen, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(room, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Chip(
                        label: Text('$count Sesi'),
                        backgroundColor: const Color(0xFFFFF1F2),
                        labelStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
