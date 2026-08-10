import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app_config.dart';
import '../../data/datasources/local_store.dart';

class ProgramScreen extends StatelessWidget {
  const ProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalStore.instance,
      builder: (context, _) {
        final programs = LocalStore.instance.programs;

        return Scaffold(
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
