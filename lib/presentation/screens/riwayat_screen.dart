import 'package:flutter/material.dart';
import '../../core/services/pdf_service.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/child_model.dart';
import '../../data/models/notulen_model.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({Key? key}) : super(key: key);

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final TextEditingController _filterController = TextEditingController();

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
                    hintText: 'Filter Program Terapi (Vestibular, Gunting, dll)...',
                    prefixIcon: const Icon(Icons.filter_list),
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
                                            const Icon(Icons.account_circle, color: Color(0xFFF43F5E)),
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
                                          icon: const Icon(Icons.picture_as_pdf, size: 14),
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
                                            const Icon(Icons.push_pin, size: 12, color: Color(0xFFBE123C)),
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
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.assignment_turned_in, size: 14, color: Colors.grey),
                                              SizedBox(width: 4),
                                              Text('Riwayat Sesi Terapi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          Text(
                                            '${childNotulens.length} Sesi Tercatat',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                                          ),
                                        ],
                                      ),
                                    ),
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
