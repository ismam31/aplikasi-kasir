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
import 'package:aplikasi_kasir_seafood/providers/category_provider.dart';

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
      drawer: const CustomDrawer(currentPage: 'Manajemen Menu'),
      body: Consumer<MenuProvider>(
        builder: (context, menuProvider, child) {
          if (menuProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gunakan Consumer nested untuk mengakses CategoryProvider
          return Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              if (categoryProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              List<model_menu.Menu> filteredMenus = [];
              if (_selectedCategory == null) {
                // Jika "Semua" dipilih, urutkan berdasarkan urutan kategori
                for (final category in categoryProvider.categories) {
                  final menusOfCategory = menuProvider.menus
                      .where((menu) => menu.categoryId == category.id)
                      .toList();
                  if (_sortOrder == 'az') {
                    menusOfCategory.sort((a, b) => a.name.compareTo(b.name));
                  } else {
                    menusOfCategory.sort((a, b) => b.name.compareTo(a.name));
                  }
                  filteredMenus.addAll(menusOfCategory);
                }
                // Jika ada menu tanpa kategori, tambahkan di akhir
                final menusWithoutCategory = menuProvider.menus
                    .where((menu) => menu.categoryId == null)
                    .toList();
                if (_sortOrder == 'az') {
                  menusWithoutCategory.sort((a, b) => a.name.compareTo(b.name));
                } else {
                  menusWithoutCategory.sort((a, b) => b.name.compareTo(a.name));
                }
                filteredMenus.addAll(menusWithoutCategory);
              } else {
                // Jika kategori spesifik dipilih, tampilkan menu dari kategori itu saja
                filteredMenus = menuProvider.menus
                    .where((menu) => menu.categoryId == _selectedCategory!.id)
                    .toList();
                if (_sortOrder == 'az') {
                  filteredMenus.sort((a, b) => a.name.compareTo(b.name));
                } else {
                  filteredMenus.sort((a, b) => b.name.compareTo(a.name));
                }
              }

              // Filter berdasarkan query pencarian
              if (_searchQuery.isNotEmpty) {
                filteredMenus = filteredMenus
                    .where(
                      (menu) => menu.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();
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
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Cari menu...',
                                    border: InputBorder.none,
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.blueGrey,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: DropdownButtonFormField<String>(
                                value: _sortOrder,
                                decoration: InputDecoration(
                                  labelText: 'Urutkan',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'az',
                                    child: Text('A-Z'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'za',
                                    child: Text('Z-A'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _sortOrder = value!;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isGridView
                                    ? Icons.view_list_rounded
                                    : Icons.grid_view_rounded,
                                color: Colors.teal.shade700,
                                size: 30,
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
                                selectedColor: Colors.teal.shade50,
                                backgroundColor: Colors.grey.shade200,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == null
                                      ? Colors.teal.shade900
                                      : Colors.blueGrey,
                                ),
                                showCheckmark: false,
                              ),
                              ...categoryProvider.categories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(category.name!),
                                    selected:
                                        _selectedCategory?.id == category.id,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = selected
                                            ? category
                                            : null;
                                      });
                                    },
                                    selectedColor: Colors.teal.shade50,
                                    backgroundColor: Colors.grey.shade200,
                                    labelStyle: TextStyle(
                                      color:
                                          _selectedCategory?.id == category.id
                                          ? Colors.teal.shade900
                                          : Colors.blueGrey,
                                    ),
                                    showCheckmark: false,
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
                    child: filteredMenus.isEmpty
                        ? const Center(
                            child: Text('Tidak ada menu yang ditemukan.'),
                          )
                        : _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.all(16.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                  childAspectRatio: 0.6, // Mengubah rasio aspek
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
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMenuItemCard(BuildContext context, model_menu.Menu menu) {
    final isAvailable = menu.isAvailable;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: menu.image != null && menu.image!.isNotEmpty
                  ? Image.file(
                      File(menu.image!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/placeholder.png',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp ${_formatCurrency(menu.priceSell)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAvailable
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue.shade700),
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
                    icon: Icon(Icons.delete, color: Colors.red.shade700),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: SizedBox(
          width: 70,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: menu.image != null && menu.image!.isNotEmpty
                ? Image.file(
                    File(menu.image!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/placeholder.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
          ),
        ),
        title: Text(
          menu.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isAvailable ? Colors.blueGrey.shade900 : Colors.grey,
          ),
        ),
        subtitle: Text(
          isAvailable
              ? 'Rp ${_formatCurrency(menu.priceSell)}'
              : 'Tidak Tersedia',
          style: TextStyle(
            color: isAvailable ? Colors.blueGrey.shade700 : Colors.red,
            fontWeight: isAvailable ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade700),
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
              icon: Icon(Icons.delete, color: Colors.red.shade700),
              onPressed: () => _showDeleteConfirmation(context, menu),
            ),
          ],
        ),
      ),
    );
  }
}
