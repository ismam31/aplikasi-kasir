import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model_category;
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/providers/category_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:aplikasi_kasir_seafood/pages/cart_page.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Pemesanan'),
      drawer: const CustomDrawer(currentPage: 'Pemesanan'),
      body: Consumer2<CategoryProvider, MenuProvider>(
        builder: (context, categoryProvider, menuProvider, child) {
          if (categoryProvider.isLoading || menuProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<model_menu.Menu> allMenus = menuProvider.menus;

          // Filter dan sortir menu
          List<model_menu.Menu> filteredMenus = allMenus.where((menu) {
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
                          width: 72,
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
                              DropdownMenuItem(value: 'az', child: Text('A-Z')),
                              DropdownMenuItem(value: 'za', child: Text('Z-A')),
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
                                selected: _selectedCategory?.id == category.id,
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
                                  color: _selectedCategory?.id == category.id
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 0.0,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                              childAspectRatio: 0.6,
                            ),
                        itemCount: filteredMenus.length,
                        itemBuilder: (context, index) {
                          final menu = filteredMenus[index];
                          return _buildMenuItemCard(context, menu);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 0.0,
                        ),
                        itemCount: filteredMenus.length,
                        itemBuilder: (context, index) {
                          final menu = filteredMenus[index];
                          return _buildMenuItemListTile(context, menu);
                        },
                      ),
              ),
              _buildCartView(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(BuildContext context, model_menu.Menu menu) {
    final isAvailable = menu.isAvailable;
    return InkWell(
      onTap: isAvailable ? () => _showQuantityDialog(context, menu) : null,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Column(
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
                        : Image.asset(
                            'assets/placeholder.png',
                            fit: BoxFit.cover,
                          ),
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
              ],
            ),
            if (!isAvailable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Tidak Tersedia',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
        onTap: isAvailable ? () => _showQuantityDialog(context, menu) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          overflow: TextOverflow.ellipsis,
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
        trailing: Container(
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            isAvailable ? 'Tersedia' : 'Tidak Tersedia',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, model_menu.Menu menu) {
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );
    final String unit = menu.weightUnit ?? 'pcs';
    double price = menu.priceSell;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: 'Input Quantity ${menu.name}',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          title: Text(
            menu.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.teal,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Harga per $unit: Rp ${_formatCurrency(price)}',
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        double current =
                            double.tryParse(quantityController.text) ?? 1;
                        if (current > 1) {
                          current -= (unit == 'pcs' || unit == 'porsi')
                              ? 1.0
                              : 0.1;
                        }
                        quantityController.text =
                            (unit == 'pcs' || unit == 'porsi')
                            ? current.toStringAsFixed(0)
                            : current.toStringAsFixed(1);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blueGrey.shade200,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        double current =
                            double.tryParse(quantityController.text) ?? 0;
                        if (current == 0 &&
                            (unit == 'pcs' || unit == 'porsi')) {
                          current = 1.0;
                        } else {
                          current += (unit == 'pcs' || unit == 'porsi')
                              ? 1.0
                              : 0.1;
                        }
                        quantityController.text =
                            (unit == 'pcs' || unit == 'porsi')
                            ? current.toStringAsFixed(0)
                            : current.toStringAsFixed(1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity =
                    double.tryParse(quantityController.text) ?? 0.0;
                if (quantity > 0) {
                  Provider.of<OrderProvider>(
                    context,
                    listen: false,
                  ).addItemToCart(menu: menu, quantity: quantity);
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    '${menu.name} berhasil ditambahkan ke keranjang',
                    backgroundColor: Colors.green,
                    icon: Icons.check,
                  );
                } else {
                  CustomNotification.show(
                    context,
                    'Kuantitas tidak boleh 0',
                    backgroundColor: Colors.red,
                    icon: Icons.error,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tambahkan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartView(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Visibility(
          visible: orderProvider.cart.isNotEmpty,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      'Rp ${_formatCurrency(orderProvider.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text(
                      'Lihat Keranjang (${orderProvider.cart.length})',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
