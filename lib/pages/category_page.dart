import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model_category;
import 'package:aplikasi_kasir_seafood/providers/category_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  // Metode untuk menangani reordering
  void _onReorder(
      int oldIndex, int newIndex, List<model_category.Category> categories) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = categories.removeAt(oldIndex);
      categories.insert(newIndex, item);
    });
    // Panggil provider untuk menyimpan urutan baru
    Provider.of<CategoryProvider>(context, listen: false).updateOrder(
      categories,
    );
  }

  // Dialog untuk menambah kategori baru dengan desain modern
  void _showAddCategoryDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Tambah Kategori Baru',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nama Kategori',
              hintText: 'Misal: Ikan, Udang, dsb.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00796B)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueGrey,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Provider.of<CategoryProvider>(
                    context,
                    listen: false,
                  ).addCategory(controller.text);
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    'Kategori berhasil ditambahkan',
                    backgroundColor: Colors.green,
                    icon: Icons.check_circle,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk mengedit kategori dengan desain modern
  void _showEditCategoryDialog(
    BuildContext context,
    model_category.Category category,
  ) {
    TextEditingController controller = TextEditingController(
      text: category.name,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Kategori',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nama Kategori',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00796B)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueGrey,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  category.name = controller.text;
                  Provider.of<CategoryProvider>(
                    context,
                    listen: false,
                  ).updateCategory(category);
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    'Kategori berhasil diperbarui',
                    backgroundColor: Colors.green,
                    icon: Icons.check_circle,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Dialog konfirmasi untuk menghapus kategori dengan desain modern
  void _showDeleteConfirmation(
    BuildContext context,
    model_category.Category category,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Hapus Kategori',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueGrey,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<CategoryProvider>(
                  context,
                  listen: false,
                ).deleteCategory(category.id!);
                Navigator.pop(context);
                CustomNotification.show(
                  context,
                  'Kategori berhasil dihapus',
                  backgroundColor: Colors.green,
                  icon: Icons.check_circle,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Kategori'),
      drawer: const CustomDrawer(
        currentPage: 'Kategori',
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.tags,
                    size: 80,
                    color: Colors.blueGrey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada kategori.\nTambahkan sekarang!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blueGrey.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }
          
          final categories = categoryProvider.categories;
          
          return ReorderableListView(
            padding: const EdgeInsets.all(16),
            onReorder: (oldIndex, newIndex) =>
                _onReorder(oldIndex, newIndex, categories),
            children: categories.map((category) {
              return Container(
                key: ValueKey(category.id),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: const FaIcon(
                    FontAwesomeIcons.tag,
                    color: Color(0xFF00796B),
                    size: 24,
                  ),
                  title: Text(
                    category.name!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconButton(
                        icon: Icons.edit,
                        color: Colors.blue.shade700,
                        onPressed: () =>
                            _showEditCategoryDialog(context, category),
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(
                        icon: Icons.delete,
                        color: Colors.red.shade700,
                        onPressed: () =>
                            _showDeleteConfirmation(context, category),
                      ),
                      const SizedBox(width: 8),
                      const FaIcon(
                        FontAwesomeIcons.gripLines,
                        color: Colors.blueGrey,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget pembantu untuk membuat ikon tombol dengan gaya yang konsisten
  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
