import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/datasources/local_store.dart';
import '../../data/models/child_model.dart';

class AnakScreen extends StatefulWidget {
  const AnakScreen({super.key});

  @override
  State<AnakScreen> createState() => _AnakScreenState();
}

class _AnakScreenState extends State<AnakScreen> {
  String _categoryFilter = 'all';
  String _sortBy = 'name-asc';
  String _searchQuery = '';

  void _showAddChildModal() {
    final nameController = TextEditingController();
    String category = 'reguler';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah Data Anak Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Anak',
                      prefixIcon: Icon(LucideIcons.user),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Reguler', style: TextStyle(fontSize: 12)),
                          value: 'reguler',
                          groupValue: category,
                          onChanged: (val) => setModalState(() => category = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Intensif', style: TextStyle(fontSize: 12)),
                          value: 'intensif',
                          groupValue: category,
                          onChanged: (val) => setModalState(() => category = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          LocalStore.instance.addChild(
                            nameController.text.trim(),
                            category,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Berhasil menambahkan anak ${nameController.text.trim()}'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                      ),
                      icon: const Icon(LucideIcons.check, color: Colors.white),
                      label: const Text('Simpan Data Anak', style: TextStyle(color: Colors.white)),
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

  void _showEditChildModal(ChildModel child) {
    final nameController = TextEditingController(text: child.name);
    String category = child.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Data Anak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE123C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Anak',
                      prefixIcon: Icon(LucideIcons.user),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Reguler', style: TextStyle(fontSize: 12)),
                          value: 'reguler',
                          groupValue: category,
                          onChanged: (val) => setModalState(() => category = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Intensif', style: TextStyle(fontSize: 12)),
                          value: 'intensif',
                          groupValue: category,
                          onChanged: (val) => setModalState(() => category = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          LocalStore.instance.updateChild(
                            child.id,
                            nameController.text.trim(),
                            category,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Berhasil memperbarui anak ${nameController.text.trim()}'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocalStore.instance,
      builder: (context, _) {
        var list = List<ChildModel>.from(LocalStore.instance.children);

        // Filter Category
        if (_categoryFilter != 'all') {
          list = list.where((c) => c.category == _categoryFilter).toList();
        }

        // Search Query
        if (_searchQuery.isNotEmpty) {
          list = list
              .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        // Sorting
        if (_sortBy == 'name-asc') {
          list.sort((a, b) => a.name.compareTo(b.name));
        } else if (_sortBy == 'name-desc') {
          list.sort((a, b) => b.name.compareTo(a.name));
        } else if (_sortBy == 'newest') {
          list.sort((a, b) => (b.createdAt ?? b.id).compareTo(a.createdAt ?? a.id));
        } else if (_sortBy == 'oldest') {
          list.sort((a, b) => (a.createdAt ?? a.id).compareTo(b.createdAt ?? b.id));
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddChildModal,
            backgroundColor: const Color(0xFFF43F5E),
            child: const Icon(LucideIcons.plus, color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar + Sort Dropdown
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Cari nama anak...',
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
                      icon: const Icon(LucideIcons.arrowDownUp),
                      onChanged: (val) => setState(() => _sortBy = val!),
                      items: const [
                        DropdownMenuItem(value: 'name-asc', child: Text('Abjad A-Z', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'name-desc', child: Text('Abjad Z-A', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'newest', child: Text('Terbaru', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'oldest', child: Text('Terlama', style: TextStyle(fontSize: 12))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Buttons Segmented
                Row(
                  children: [
                    _buildCategoryBtn('Semua', 'all'),
                    const SizedBox(width: 6),
                    _buildCategoryBtn('Intensif', 'intensif'),
                    const SizedBox(width: 6),
                    _buildCategoryBtn('Reguler', 'reguler'),
                  ],
                ),
                const SizedBox(height: 12),

                // Children List
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada data anak ditemukan',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (ctx, idx) {
                            final child = list[idx];
                            final isIntensif = child.category == 'intensif';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isIntensif ? Colors.blue.shade100 : Colors.teal.shade100,
                                  child: Icon(
                                    LucideIcons.user,
                                    color: isIntensif ? Colors.blue.shade800 : Colors.teal.shade800,
                                  ),
                                ),
                                title: Text(
                                  child.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Kategori: ${child.category.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isIntensif ? Colors.blue : Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.edit2, size: 18, color: Colors.blue),
                                      onPressed: () => _showEditChildModal(child),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                                      onPressed: () {
                                        LocalStore.instance.deleteChild(child.id);
                                      },
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

  Widget _buildCategoryBtn(String label, String category) {
    final isSelected = _categoryFilter == category;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _categoryFilter = category),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFFF43F5E) : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: isSelected ? 2 : 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
