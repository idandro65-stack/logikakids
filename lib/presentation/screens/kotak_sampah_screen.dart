import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/trash_item_model.dart';

class KotakSampahScreen extends StatefulWidget {
  const KotakSampahScreen({super.key});

  @override
  State<KotakSampahScreen> createState() => _KotakSampahScreenState();
}

class _KotakSampahScreenState extends State<KotakSampahScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

  String _formatDeletedAt(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final mStr = months[dt.month - 1];
      final timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      return "${dt.day} $mStr ${dt.year}, $timeStr";
    } catch (_) {
      return isoString;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'notulen':
        return LucideIcons.fileText;
      case 'anak':
        return LucideIcons.user;
      case 'program':
        return LucideIcons.bookOpen;
      case 'staf':
        return LucideIcons.userCheck;
      case 'ruang':
        return LucideIcons.doorOpen;
      default:
        return LucideIcons.archive;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'notulen':
        return const Color(0xFFF43F5E);
      case 'anak':
        return const Color(0xFF2563EB);
      case 'program':
        return const Color(0xFF7C3AED);
      case 'staf':
        return const Color(0xFF0D9488);
      case 'ruang':
        return const Color(0xFFD97706);
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'notulen':
        return 'NOTULEN';
      case 'anak':
        return 'ANAK';
      case 'program':
        return 'PROGRAM';
      case 'staf':
        return 'STAF';
      case 'ruang':
        return 'RUANG';
      default:
        return type.toUpperCase();
    }
  }

  Future<void> _confirmRestore(BuildContext context, TrashItemModel item, LocalStore store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.undo2, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text('Pulihkan Data?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin memulihkan "${item.title}" kembali ke daftar aktif?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            child: const Text('Pulihkan Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = store.restoreTrashItem(item.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data "${item.title}" berhasil dipulihkan!')),
        );
      }
    }
  }

  Future<void> _confirmDeletePermanent(BuildContext context, TrashItemModel item, LocalStore store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Permanen?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus permanen "${item.title}"? Tindakan ini tidak dapat dibatalkan selamanya.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Selamanya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = store.deleteTrashItemPermanently(item.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data "${item.title}" telah dihapus permanen.')),
        );
      }
    }
  }

  Future<void> _confirmEmptyTrash(BuildContext context, LocalStore store) async {
    final count = store.trashItems.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.trash2, color: Colors.red),
            SizedBox(width: 8),
            Text('Kosongkan Kotak Sampah?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Seluruh ($count) data di kotak sampah akan dimusnahkan secara permanen dari sistem. Tindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kosongkan Semua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      store.emptyTrash();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count item sampah telah dimusnahkan secara permanen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    final currentUser = store.currentUser;
    final isAdmin = currentUser?.role == 'admin';

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Akses Ditolak'),
          backgroundColor: const Color(0xFFF43F5E),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.shieldAlert, size: 48, color: Colors.red),
              SizedBox(height: 12),
              Text(
                'Halaman ini hanya dapat diakses oleh Admin / Kepala Klinik.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final trashList = store.trashItems;
        final retentionDays = store.trashRetentionDays;

        // Filter by category
        var filteredList = trashList;
        if (_selectedCategory != 'all') {
          filteredList = filteredList.where((item) => item.itemType == _selectedCategory).toList();
        }

        // Filter by search query
        final query = _searchController.text.trim().toLowerCase();
        if (query.isNotEmpty) {
          filteredList = filteredList.where((item) {
            final matchesTitle = item.title.toLowerCase().contains(query);
            final matchesSubtitle = item.subtitle.toLowerCase().contains(query);
            final matchesDeletedBy = item.deletedBy.toLowerCase().contains(query);
            return matchesTitle || matchesSubtitle || matchesDeletedBy;
          }).toList();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(LucideIcons.trash2, size: 20),
                SizedBox(width: 8),
                Text('Kotak Sampah & Pemulihan'),
              ],
            ),
            backgroundColor: const Color(0xFFF43F5E),
            foregroundColor: Colors.white,
            actions: [
              if (trashList.isNotEmpty)
                IconButton(
                  icon: const Icon(LucideIcons.trash2),
                  tooltip: 'Kosongkan Semua Sampah',
                  onPressed: () => _confirmEmptyTrash(context, store),
                ),
            ],
          ),
          body: Column(
            children: [
              // 1. Info Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFFFF1F2),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: Color(0xFFBE123C)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        retentionDays == -1
                            ? 'Masa simpan: Selamanya. Data tersimpan hingga dihapus manual.'
                            : 'Masa simpan: $retentionDays hari. Data yang melewati batas akan dibersihkan otomatis.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Search & Filter Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari di kotak sampah...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua (${trashList.length})', 'all'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Notulen (${trashList.where((e) => e.itemType == 'notulen').length})', 'notulen'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Anak (${trashList.where((e) => e.itemType == 'anak').length})', 'anak'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Program (${trashList.where((e) => e.itemType == 'program').length})', 'program'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Staf (${trashList.where((e) => e.itemType == 'staf').length})', 'staf'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Ruang (${trashList.where((e) => e.itemType == 'ruang').length})', 'ruang'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Items List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.trash, size: 54, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'Kotak Sampah Kosong',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Tidak ada item yang sesuai dengan pencarian'
                                  : 'Belum ada data yang dihapus',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filteredList.length,
                        itemBuilder: (ctx, i) {
                          final item = filteredList[i];
                          final typeColor = _getTypeColor(item.itemType);
                          final typeIcon = _getTypeIcon(item.itemType);
                          final typeLabel = _getTypeLabel(item.itemType);
                          final formattedDate = _formatDeletedAt(item.deletedAt);

                          // Calculate remaining days
                          int? remainingDays;
                          if (retentionDays > 0) {
                            try {
                              final delDate = DateTime.parse(item.deletedAt);
                              final passed = DateTime.now().difference(delDate).inDays;
                              remainingDays = (retentionDays - passed).clamp(0, retentionDays);
                            } catch (_) {}
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Type Badge & Remaining Days
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(typeIcon, size: 12, color: typeColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              typeLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: typeColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (remainingDays != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(LucideIcons.clock, size: 10, color: Colors.grey),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Sisa $remainingDays hari',
                                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Title & Subtitle
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (item.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.subtitle,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                  const SizedBox(height: 6),

                                  // Audit Info: Deleted By & At
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.userX, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Dihapus oleh ${item.deletedBy} pada $formattedDate',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),

                                  // Action Buttons: Restore & Delete Forever
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Restore Button
                                      InkWell(
                                        onTap: () => _confirmRestore(context, item, store),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(LucideIcons.undo2, size: 12, color: Color(0xFF0D9488)),
                                              SizedBox(width: 4),
                                              Text(
                                                'Pulihkan',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Delete Permanently Button
                                      InkWell(
                                        onTap: () => _confirmDeletePermanent(context, item, store),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(LucideIcons.trash2, size: 12, color: Colors.red),
                                              SizedBox(width: 4),
                                              Text(
                                                'Hapus Permanen',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF43F5E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFF43F5E) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
