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
  model_category.Category? _selectedCategory;
  String? _selectedWeightUnit;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  late bool _isAvailable = true;

  final List<String> _weightUnits = ['gram', 'kg', 'porsi', 'pcs'];

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
    _isAvailable = menu?.isAvailable ?? true;
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
        isAvailable: _isAvailable,
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

  InputDecoration _buildInputDecoration(String labelText, {String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
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
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Nama menu
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration(
                        'Nama Menu',
                        hintText: 'Mis: Kepiting Saus Padang',
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Deskripsi
                    TextFormField(
                      controller: _descController,
                      decoration: _buildInputDecoration(
                        'Deskripsi',
                        hintText: 'Mis: Kepiting segar dengan saus khas',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    // Harga dasar
                    TextFormField(
                      controller: _priceBaseController,
                      decoration: _buildInputDecoration('Harga Dasar'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(
                          thousandSeparator: ThousandSeparator.Period,
                          mantissaLength: 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Harga jual
                    TextFormField(
                      controller: _priceSellController,
                      decoration: _buildInputDecoration('Harga Jual'),
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
                    const SizedBox(height: 16),
                    // Stok
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Stok',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                        ),
                        value: _isAvailable,
                        onChanged: (val) {
                          setState(() {
                            _isAvailable = val;
                          });
                        },
                        activeColor: Colors.teal.shade700,
                        activeTrackColor: Colors.teal.shade200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Satuan berat
                    DropdownButtonFormField<String>(
                      value: _selectedWeightUnit,
                      decoration: _buildInputDecoration('Satuan Berat'),
                      items: _weightUnits.map((unit) {
                        return DropdownMenuItem(value: unit, child: Text(unit));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWeightUnit = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Kategori
                    DropdownButtonFormField<model_category.Category>(
                      value: _selectedCategory,
                      decoration: _buildInputDecoration('Kategori'),
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
                    const SizedBox(height: 24),
                    // Image Picker Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _imagePath != null && _imagePath!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _imagePath!.startsWith('http')
                                    ? Image.network(
                                        _imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) {
                                          return _buildImagePlaceholder();
                                        },
                                      )
                                    : Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) {
                                          return _buildImagePlaceholder();
                                        },
                                      ),
                              )
                            : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Tombol simpan
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        isEdit ? 'Update Menu' : 'Tambah Menu',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 50, color: Colors.blueGrey.shade300),
        const SizedBox(height: 8),
        Text(
          'Ketuk untuk pilih gambar',
          style: TextStyle(color: Colors.blueGrey.shade500),
        ),
      ],
    );
  }
}
