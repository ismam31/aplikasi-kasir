import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/models/category.dart' as model_category;
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/category_provider.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';

class AddEditMenuScreen extends StatefulWidget {
  final model_menu.Menu? menu;
  const AddEditMenuScreen({Key? key, this.menu}) : super(key: key);

  @override
  State<AddEditMenuScreen> createState() => _AddEditMenuScreenState();
}

class _AddEditMenuScreenState extends State<AddEditMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceBaseController;
  late TextEditingController _priceSellController;
  late TextEditingController _stockController;
  late TextEditingController _weightUnitController;
  model_category.Category? _selectedCategory;
  String? _selectedWeightUnit;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  final List<String> _weightUnits = ['gram', 'kg', 'ml', 'liter', 'pcs'];

  @override
  void initState() {
    super.initState();
    final menu = widget.menu;
    _nameController = TextEditingController(text: menu?.name ?? '');
    _descController = TextEditingController(text: menu?.description ?? '');
    _priceBaseController = TextEditingController(
      text: menu?.priceBase?.toString() ?? '',
    );
    _priceSellController = TextEditingController(
      text: menu?.priceSell.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: menu?.stock?.toString() ?? '',
    );
    _weightUnitController = TextEditingController(text: menu?.weightUnit ?? '');
    _selectedWeightUnit = menu?.weightUnit;
    _imagePath = menu?.image;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProv = Provider.of<CategoryProvider>(context, listen: false);
      if (catProv.categories.isEmpty) {
        catProv.loadCategories();
      }
      if (menu != null && menu.categoryId != null) {
        final matchedCategory = catProv.categories.firstWhere(
          (cat) => cat.id == menu.categoryId,
          orElse: () => model_category.Category(id: 0, name: ''),
        );
        if (matchedCategory.id != 0) {
          setState(() {
            _selectedCategory = matchedCategory;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceBaseController.dispose();
    _priceSellController.dispose();
    _stockController.dispose();
    _weightUnitController.dispose();
    super.dispose();
  }

  // Fungsi parse harga aman
  double _parseCurrency(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
  }

  // Ambil gambar
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  // Simpan menu
  void _save() async {
    if (_formKey.currentState!.validate()) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);

      final newMenu = model_menu.Menu(
        id: widget.menu?.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        priceBase: _parseCurrency(_priceBaseController.text),
        priceSell: _parseCurrency(_priceSellController.text),
        stock: int.tryParse(_stockController.text),
        weightUnit: _selectedWeightUnit,
        image: _imagePath,
        categoryId: _selectedCategory?.id,
      );

      try {
        if (widget.menu == null) {
          await menuProvider.addMenu(newMenu);
          CustomNotification.show(
            context,
            'Menu berhasil ditambahkan',
            backgroundColor: Colors.green,
            icon: Icons.check,
          );
        } else {
          await menuProvider.updateMenu(newMenu);
          CustomNotification.show(
            context,
            'Menu berhasil diperbarui',
            backgroundColor: Colors.green,
            icon: Icons.check,
          );
        }
        Navigator.pop(context);
      } catch (e) {
        CustomNotification.show(
          context,
          'Gagal menyimpan menu: ${e.toString()}',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.menu != null;
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: isEdit ? 'Edit Menu' : 'Tambah Menu',
        showBackButton: true,
      ),
      body: categoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Nama menu
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama Menu'),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Deskripsi
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    // Harga dasar
                    TextFormField(
                      controller: _priceBaseController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Dasar',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(
                          thousandSeparator: ThousandSeparator.Period,
                          mantissaLength: 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Harga jual
                    TextFormField(
                      controller: _priceSellController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(
                          thousandSeparator: ThousandSeparator.Period,
                          mantissaLength: 0,
                        ),
                      ],
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Harga jual wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // Stok
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    // Satuan berat
                    DropdownButtonFormField<String>(
                      value: _selectedWeightUnit,
                      decoration: const InputDecoration(
                        labelText: 'Satuan Berat',
                      ),
                      items: _weightUnits.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWeightUnit = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Kategori
                    DropdownButtonFormField<model_category.Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categoryProvider.categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name!),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                      validator: (val) =>
                          val == null ? 'Kategori wajib dipilih' : null,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: _imagePath != null && _imagePath!.isNotEmpty
                          ? (_imagePath!.startsWith('/data') ||
                                    _imagePath!.startsWith('/storage'))
                                // Kalau path lokal (baru diupload dari HP)
                                ? Image.file(
                                    File(_imagePath!),
                                    height: 150,
                                    fit: BoxFit.cover,
                                  )
                                // Kalau path dari database (URL / path relative)
                                : Image.network(
                                    _imagePath!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) {
                                      return Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
                                      );
                                    },
                                  )
                          : Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text('Ketuk untuk pilih gambar'),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    // Tombol simpan
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Update' : 'Tambah'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
