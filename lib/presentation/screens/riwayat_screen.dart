import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/pdf_service.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/child_model.dart';
import '../../data/models/notulen_model.dart';
import '../../data/models/program_model.dart';
import 'input_notulen_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _categoryFilter = 'all';
  String _roomFilter = 'all';
  String _sortBy = 'date-desc'; // Default: Tanggal Terbaru
  DateTime? _dateFrom;
  DateTime? _dateTo;

  Future<void> _confirmDeleteNotulen(NotulenModel n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Hapus Sesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus notulen sesi ${n.childName} tanggal ${n.date}? Tindakan ini tidak dapat dibatalkan.', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Sesi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LocalStore.instance.deleteNotulen(n.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notulen sesi ${n.childName} berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalStore.instance,
      builder: (context, _) {
        final store = LocalStore.instance;
        final notulens = store.notulens;

        // Group Notulens by Child Name with Comprehensive Web Filters
        Map<String, List<NotulenModel>> groupedByChild = {};

        for (var n in notulens) {
          final childObj = store.children.firstWhere(
            (c) => c.name.toLowerCase() == n.childName.toLowerCase(),
            orElse: () => ChildModel(id: '', name: n.childName, category: 'reguler'),
          );

          // 1. Category Filter
          if (_categoryFilter != 'all' && childObj.category != _categoryFilter) {
            continue;
          }

          // 2. Room Filter
          if (_roomFilter != 'all') {
            final rooms = n.room.split(';').map((r) => r.trim());
            if (!rooms.contains(_roomFilter)) continue;
          }

          // 3. Date Range Filter
          if (_dateFrom != null || _dateTo != null) {
            try {
              final notulenDate = DateTime.parse(n.date);
              if (_dateFrom != null && notulenDate.isBefore(_dateFrom!)) continue;
              if (_dateTo != null && notulenDate.isAfter(_dateTo!.add(const Duration(days: 1)))) continue;
            } catch (_) {
              // Skip if date format is invalid
            }
          }

          // 4. Search Bar Filter
          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            final matchChild = n.childName.toLowerCase().contains(query);
            final matchRoom = n.room.toLowerCase().contains(query);
            final matchNotes = n.notes.toLowerCase().contains(query);
            final matchProg = n.programsSelected.any((p) {
              final clean = store.resolveProgramName(p);
              return clean.toLowerCase().contains(query);
            });

            if (!matchChild && !matchRoom && !matchNotes && !matchProg) continue;
          }

          if (!groupedByChild.containsKey(n.childName)) {
            groupedByChild[n.childName] = [];
          }
          groupedByChild[n.childName]!.add(n);
        }

        var childNames = groupedByChild.keys.toList();

        // Sorting Logic (Explicit Date & Name Sorting)
        if (_sortBy == 'date-desc') {
          childNames.sort((a, b) {
            final latestA = groupedByChild[a]!.first.date;
            final latestB = groupedByChild[b]!.first.date;
            return latestB.compareTo(latestA);
          });
        } else if (_sortBy == 'date-asc') {
          childNames.sort((a, b) {
            final latestA = groupedByChild[a]!.first.date;
            final latestB = groupedByChild[b]!.first.date;
            return latestA.compareTo(latestB);
          });
        } else if (_sortBy == 'name-asc') {
          childNames.sort((a, b) => a.compareTo(b));
        } else if (_sortBy == 'name-desc') {
          childNames.sort((a, b) => b.compareTo(a));
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Search Bar + Date/Name Sort Dropdown
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nama anak / program / ruangan...',
                          prefixIcon: const Icon(LucideIcons.search),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(LucideIcons.arrowDownUp, size: 18),
                      onChanged: (val) => setState(() => _sortBy = val!),
                      items: const [
                        DropdownMenuItem(value: 'date-desc', child: Text('Tgl Terbaru', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'date-asc', child: Text('Tgl Terlama', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'name-asc', child: Text('Nama A-Z', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'name-desc', child: Text('Nama Z-A', style: TextStyle(fontSize: 11))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Category & Room Filters Toolbar
                Row(
                  children: [
                    // Category Chips
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          _buildCatChip('Semua', 'all'),
                          const SizedBox(width: 4),
                          _buildCatChip('Intensif', 'intensif'),
                          const SizedBox(width: 4),
                          _buildCatChip('Reguler', 'reguler'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Room Dropdown Filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _roomFilter,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Semua Ruang', style: TextStyle(fontSize: 11))),
                          ...store.allRooms.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 11)))),
                        ],
                        onChanged: (val) => setState(() => _roomFilter = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Date Range Filter Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateFrom ?? DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _dateFrom = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 14, color: Color(0xFFF43F5E)),
                              const SizedBox(width: 4),
                              Text(
                                _dateFrom != null
                                    ? 'Dari: ${DateFormat('yyyy-MM-dd').format(_dateFrom!)}'
                                    : 'Dari Tanggal',
                                style: TextStyle(fontSize: 10, color: _dateFrom != null ? Colors.black87 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateTo ?? DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _dateTo = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendarCheck, size: 14, color: Color(0xFFF43F5E)),
                              const SizedBox(width: 4),
                              Text(
                                _dateTo != null
                                    ? 'Sampai: ${DateFormat('yyyy-MM-dd').format(_dateTo!)}'
                                    : 'Sampai Tanggal',
                                style: TextStyle(fontSize: 10, color: _dateTo != null ? Colors.black87 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_dateFrom != null || _dateTo != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(LucideIcons.x, size: 16, color: Colors.red),
                        onPressed: () => setState(() {
                          _dateFrom = null;
                          _dateTo = null;
                        }),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Riwayat Cards List (100% Matching Web Layout Screenshot!)
                Expanded(
                  child: childNames.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data riwayat notulen sesuai filter',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: childNames.length,
                          itemBuilder: (ctx, idx) {
                            final childName = childNames[idx];
                            final childNotulens = groupedByChild[childName]!;
                            childNotulens.sort((a, b) => b.date.compareTo(a.date));

                            final childObj = store.children.firstWhere(
                              (c) => c.name.toLowerCase() == childName.toLowerCase(),
                              orElse: () => ChildModel(id: '', name: childName, category: 'reguler'),
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFFECDD3)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Child Header Banner (Matching Web Screenshot 100%)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.user, color: Color(0xFFF43F5E), size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              childName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: childObj.category == 'intensif'
                                                    ? Colors.blue.shade100
                                                    : Colors.teal.shade100,
                                                borderRadius: BorderRadius.circular(99),
                                              ),
                                              child: Text(
                                                childObj.category.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: childObj.category == 'intensif'
                                                      ? Colors.blue.shade900
                                                      : Colors.teal.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                PdfService.generateAndPrintRaport(context, childName);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFF43F5E),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                minimumSize: Size.zero,
                                              ),
                                              icon: const Icon(LucideIcons.fileText, size: 12),
                                              label: const Text('Raport PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(4),
                                              icon: const Icon(LucideIcons.send, color: Colors.green, size: 18),
                                              onPressed: () {
                                                PdfService.shareToWhatsApp(context, childName);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📋 Riwayat Sesi Terapi: ${childNotulens.length} Sesi Tercatat',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                    ),
                                    const Divider(height: 16),

                                    // Session Items Cards
                                    ...childNotulens.map((n) {
                                      return _buildSessionCard(context, n, store);
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

  Color _getRoomColor(String room) {
    final lower = room.toLowerCase();
    if (lower.contains('sensori')) return const Color(0xFFE11D48); // Rose / Sensori
    if (lower.contains('okupasi')) return const Color(0xFF7C3AED); // Violet / Okupasi
    if (lower.contains('wicara')) return const Color(0xFF0D9488); // Teal / Wicara
    if (lower.contains('snoezelen')) return const Color(0xFFD97706); // Amber / Snoezelen
    if (lower.contains('akademik') || lower.contains('remidial')) return const Color(0xFF0284C7); // Sky Blue
    if (lower.contains('fisioterapi')) return const Color(0xFF059669); // Emerald
    if (lower.contains('perilaku') || lower.contains('aba')) return const Color(0xFFC026D3); // Fuchsia
    return const Color(0xFF4F46E5); // Indigo default
  }

  Widget _buildSessionCard(BuildContext context, NotulenModel n, LocalStore store) {
    final primaryRoom = n.room.split(';').first.trim();
    final roomColor = _getRoomColor(primaryRoom);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: roomColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roomColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Line: Date | Bunda | Edit | Hapus
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: roomColor),
                    const SizedBox(width: 6),
                    Text(
                      '${n.date}  |  Bunda: ${n.notulen}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => InputNotulenScreen(editNotulen: n),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(LucideIcons.edit2, size: 10),
                      label: const Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: () => _confirmDeleteNotulen(n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(LucideIcons.trash2, size: 10),
                      label: const Text('Hapus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: roomColor.withValues(alpha: 0.2)),

          // Session Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Title Badges (Matching Web Palette 100%)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: n.room.split(';').map((rm) {
                    final cleanRm = rm.trim();
                    if (cleanRm.isEmpty) return const SizedBox.shrink();
                    final rmColor = _getRoomColor(cleanRm);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: rmColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: rmColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        cleanRm,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: rmColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Special Notes Badge if available
                if (n.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.pin, size: 12, color: Color(0xFFBE123C)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Catatan Perkembangan: "${n.notes}"',
                            style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Program Items Details (Matching Web Screenshot 100%)
                ...n.programsSelected.map((progId) {
                  final cleanProgName = store.resolveProgramName(progId);
                  final progObj = store.programs.firstWhere(
                    (p) => p.id == progId || p.programName == progId,
                    orElse: () => ProgramModel(id: '', room: '', programName: cleanProgName, indicators: [], targetPoints: 10),
                  );

                  final totalTarget = progObj.targetPoints > 0
                      ? progObj.targetPoints
                      : (progObj.indicators.isNotEmpty ? progObj.indicators.length : 10);

                  final statusVal = n.status[progId] ?? n.status[cleanProgName] ?? 'S';
                  final isTuntas = statusVal == 'tuntas' || statusVal == 'S' || statusVal == 'K';

                  final statusLabel = isTuntas
                      ? 'Tuntas'
                      : (statusVal == 'BS' ? 'Berlangsung' : (statusVal == 'TS' ? 'Tidak Selesai' : 'Berlangsung'));

                  final statusColor = isTuntas ? Colors.green : Colors.orange;

                  // Calculate Achieved Points
                  final rawPoints = n.pointsAchieved[progId] ?? n.pointsAchieved[cleanProgName];
                  List<int> achievedIndices = [];
                  if (rawPoints != null && rawPoints is List) {
                    achievedIndices = (rawPoints as List).map((e) => (e as num).toInt()).toList();
                  }

                  List<int> tercapaiNumbers = [];
                  List<int> belumNumbers = [];

                  for (int i = 1; i <= totalTarget; i++) {
                    // 0-based index check (i - 1) matching web app 100%!
                    if (achievedIndices.contains(i - 1)) {
                      tercapaiNumbers.add(i);
                    } else {
                      belumNumbers.add(i);
                    }
                  }

                  final tercapaiStr = tercapaiNumbers.isNotEmpty ? tercapaiNumbers.join(', ') : '—';
                  final belumStr = belumNumbers.isNotEmpty ? belumNumbers.join(', ') : '—';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Program Name & Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cleanProgName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isTuntas ? LucideIcons.checkCircle2 : LucideIcons.rotateCcw,
                                    size: 10,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Checkpoint Tercapai Line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✓ Tercapai: ', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                tercapaiStr,
                                style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        // Checkpoint Belum Line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('✕ Belum: ', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                belumStr,
                                style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(String label, String value) {
    final isSelected = _categoryFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _categoryFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF43F5E) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
