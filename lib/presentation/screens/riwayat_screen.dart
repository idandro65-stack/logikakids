import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/pdf_service.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/child_model.dart';
import '../../data/models/notulen_model.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final TextEditingController _filterController = TextEditingController();

  void _showSessionDetailModal(BuildContext context, NotulenModel n) {
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
                    Row(
                      children: [
                        const Icon(LucideIcons.clipboardCheck, color: Color(0xFFF43F5E)),
                        const SizedBox(width: 8),
                        Text(
                          'Sesi: ${n.childName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBE123C),
                          ),
                        ),
                      ],
                    ),
                    Text(n.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Ruang Terapi: ${n.room} | Terapis: Bunda ${n.notulen}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 20),

                // Special Notes Badge
                if (n.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.pin, size: 16, color: Color(0xFFBE123C)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan Perkembangan: "${n.notes}"',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBE123C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Program & Status List
                const Text(
                  'Program Terapi yang Dijalankan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (n.programsSelected.isEmpty)
                  const Text('Tidak ada rincian program spesifik', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...n.programsSelected.map((progId) {
                    final cleanProgName = LocalStore.instance.resolveProgramName(progId);
                    final statusVal = n.status[progId] ?? n.status[cleanProgName] ?? 'S';
                    final statusLabel = statusVal == 'S'
                        ? 'Sudah (S)'
                        : statusVal == 'BS'
                            ? 'Belum Sempurna (BS)'
                            : statusVal == 'TS'
                                ? 'Tidak Selesai (TS)'
                                : 'Konsisten (K)';

                    final statusColor = statusVal == 'S' || statusVal == 'K'
                        ? Colors.green
                        : statusVal == 'BS'
                            ? Colors.orange
                            : Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cleanProgName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Chip(
                              label: Text(statusLabel),
                              backgroundColor: statusColor.withOpacity(0.1),
                              labelStyle: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),
                // Actions PDF & Share & Delete
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          PdfService.generateAndPrintRaport(context, n.childName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(LucideIcons.fileText, size: 16),
                        label: const Text('Raport PDF', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          PdfService.shareToWhatsApp(context, n.childName);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                        icon: const Icon(LucideIcons.send, size: 16),
                        label: const Text('Kirim WA', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.red),
                      onPressed: () {
                        LocalStore.instance.deleteNotulen(n.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notulen sesi berhasil dihapus')),
                        );
                      },
                    ),
                  ],
                ),
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
        final notulens = store.notulens;

        // Group Notulens by Child Name
        Map<String, List<NotulenModel>> groupedByChild = {};
        for (var n in notulens) {
          if (_filterController.text.isNotEmpty) {
            final filter = _filterController.text.toLowerCase();
            final matchProg = n.programsSelected.any((p) {
              final clean = store.resolveProgramName(p);
              return clean.toLowerCase().contains(filter);
            });
            final matchChild = n.childName.toLowerCase().contains(filter);
            if (!matchProg && !matchChild) continue;
          }

          if (!groupedByChild.containsKey(n.childName)) {
            groupedByChild[n.childName] = [];
          }
          groupedByChild[n.childName]!.add(n);
        }

        var childNames = groupedByChild.keys.toList();
        childNames.sort((a, b) => a.compareTo(b));

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Program Filter Field
                TextField(
                  controller: _filterController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Filter Program Terapi / Nama Anak...',
                    prefixIcon: const Icon(LucideIcons.filter),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Riwayat Cards List
                Expanded(
                  child: childNames.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada riwayat notulen tercatat',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: childNames.length,
                          itemBuilder: (ctx, idx) {
                            final childName = childNames[idx];
                            final childNotulens = groupedByChild[childName]!;
                            final childObj = store.children.firstWhere(
                              (c) => c.name == childName,
                              orElse: () => ChildModel(id: '', name: childName, category: 'reguler'),
                            );

                            final latestNoteWithText = childNotulens.firstWhere(
                              (n) => n.notes.trim().isNotEmpty,
                              orElse: () => NotulenModel(id: '', date: '', childName: '', notulen: '', room: '', programsSelected: [], pointsAchieved: {}, status: {}, notes: ''),
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Child Name & Raport Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.user, color: Color(0xFFF43F5E)),
                                            const SizedBox(width: 6),
                                            Text(
                                              childName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Chip(
                                              label: Text(childObj.category.toUpperCase()),
                                              backgroundColor: childObj.category == 'intensif'
                                                  ? Colors.blue.shade50
                                                  : Colors.teal.shade50,
                                              labelStyle: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: childObj.category == 'intensif' ? Colors.blue : Colors.teal,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            PdfService.generateAndPrintRaport(context, childName);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF43F5E),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          icon: const Icon(LucideIcons.fileText, size: 14),
                                          label: const Text('Raport PDF', style: TextStyle(fontSize: 10)),
                                        ),
                                      ],
                                    ),

                                    // Special Notes Badge if available
                                    if (latestNoteWithText.notes.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1F2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFFECDD3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(LucideIcons.pin, size: 12, color: Color(0xFFBE123C)),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Catatan: "${latestNoteWithText.notes}"',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFBE123C),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    const SizedBox(height: 10),
                                    // Session Items List
                                    ...childNotulens.take(3).map((n) {
                                      return InkWell(
                                        onTap: () => _showSessionDetailModal(context, n),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(LucideIcons.calendar, size: 12, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text('${n.date} (${n.room})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    'Bunda ${n.notulen}',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(LucideIcons.chevronRight, size: 14, color: Colors.grey),
                                                ],
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
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
