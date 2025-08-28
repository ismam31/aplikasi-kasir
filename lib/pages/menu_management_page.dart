import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:aplikasi_kasir_seafood/pages/add_edit_menu_screen.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model_category;

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOrder = 'az';
  model_category.Category? _selectedCategory;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MenuProvider>(
        context,
        listen: false,
      ).loadMenusAndCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, model_menu.Menu menu) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Menu'),
          content: Text(
            'Apakah Anda yakin ingin menghapus menu "${menu.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<MenuProvider>(
                  context,
                  listen: false,
                ).deleteMenu(menu.id!);
                Navigator.pop(context);
                CustomNotification.show(
                  context,
                  'Menu berhasil dihapus',
                  backgroundColor: Colors.green,
                  icon: Icons.check,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manajemen Menu'),
      drawer: const CustomDrawer(),
      body: Consumer<MenuProvider>(
        builder: (context, menuProvider, child) {
          if (menuProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<model_menu.Menu> filteredMenus = menuProvider.menus.where((
            menu,
          ) {
            final matchCategory =
                _selectedCategory == null ||
                menu.categoryId == _selectedCategory!.id;
            final matchQuery = menu.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            return matchCategory && matchQuery;
          }).toList();

          if (_sortOrder == 'az') {
            filteredMenus.sort((a, b) => a.name.compareTo(b.name));
          } else {
            filteredMenus.sort((a, b) => b.name.compareTo(a.name));
          }

          if (filteredMenus.isEmpty) {
            return const Center(child: Text('Tidak ada menu yang ditemukan.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Cari menu...',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _sortOrder,
                          items: const [
                            DropdownMenuItem(value: 'az', child: Text('A-Z')),
                            DropdownMenuItem(value: 'za', child: Text('Z-A')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortOrder = value!;
                            });
                          },
                        ),
                        IconButton(
                          // Tombol switch tampilan
                          icon: Icon(
                            _isGridView ? Icons.view_list : Icons.grid_view,
                          ),
                          onPressed: () {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = null;
                              });
                            },
                          ),
                          ...menuProvider.categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: ChoiceChip(
                                label: Text(category.name!),
                                selected: _selectedCategory?.id == category.id,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected
                                        ? category
                                        : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 5.0,
                              mainAxisSpacing: 5.0,
                              childAspectRatio: 0.5,
                            ),
                        itemCount: filteredMenus.length,
                        itemBuilder: (context, index) {
                          final menu = filteredMenus[index];
                          return _buildMenuItemCard(context, menu);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: filteredMenus.length,
                        itemBuilder: (context, index) {
                          final menu = filteredMenus[index];
                          return _buildMenuItemListTile(context, menu);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditMenuScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenuItemCard(BuildContext context, model_menu.Menu menu) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: menu.image != null && menu.image!.isNotEmpty
                  ? Image.file(File(menu.image!), fit: BoxFit.cover)
                  : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('Rp ${_formatCurrency(menu.priceSell)}'),
                const SizedBox(height: 4),
                Text(menu.isAvailable ? 'Tersedia' : 'Tidak Tersedia'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditMenuScreen(menu: menu),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, menu),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemListTile(BuildContext context, model_menu.Menu menu) {
    final isAvailable = menu.isAvailable;
    return Column(
      children: [
        ListTile(
          leading: SizedBox(
            width: 70,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: menu.image != null && menu.image!.isNotEmpty
                  ? Image.file(File(menu.image!), fit: BoxFit.cover)
                  : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
            ),
          ),
          title: Text(
            menu.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAvailable ? Colors.black : Colors.grey,
            ),
          ),
          subtitle: Text(
            isAvailable
                ? 'Rp ${_formatCurrency(menu.priceSell)}'
                : 'Tidak Tersedia',
            style: TextStyle(color: isAvailable ? Colors.black : Colors.red),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditMenuScreen(menu: menu),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(context, menu),
              ),
            ],
          ),
        ),
        const Divider(thickness: 1, height: 1, color: Colors.grey),
      ],
    );
  }
}
