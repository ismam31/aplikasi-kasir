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
    // Muat data kategori saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  // Dialog untuk menambah kategori baru
  void _showAddCategoryDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk mengedit kategori
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
          title: const Text('Edit Kategori'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nama Kategori',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // Dialog konfirmasi untuk menghapus kategori
  void _showDeleteConfirmation(
    BuildContext context,
    model_category.Category category,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kategori'),
          content: Text(
            'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      drawer: const CustomDrawer(),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.categories.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori. Tambahkan sekarang!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: const FaIcon(
                    FontAwesomeIcons.tag,
                    color: Colors.blueGrey,
                  ),
                  title: Text(
                    category.name!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showEditCategoryDialog(context, category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmation(context, category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
