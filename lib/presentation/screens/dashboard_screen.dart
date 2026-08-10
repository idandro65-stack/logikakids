import 'package:flutter/material.dart';
import '../../app_config.dart';
import '../../data/datasources/local_store.dart';
import 'input_notulen_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

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
                            icon: const Icon(Icons.add_circle_outline),
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
                Icon(Icons.history, size: 18, color: Color(0xFFBE123C)),
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
    final notulens = store.notulens;
    Map<String, int> roomCounts = {};
    for (var r in AppConfig.rooms) {
      roomCounts[r] = 0;
    }

    for (var n in notulens) {
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
                    Icon(Icons.insights, size: 18, color: Color(0xFFF43F5E)),
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
                  'Real-time Cloud',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...AppConfig.rooms.map((room) {
              final count = roomCounts[room] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(room, style: const TextStyle(fontSize: 13)),
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
              );
            }),
          ],
        ),
      ),
    );
  }
}
