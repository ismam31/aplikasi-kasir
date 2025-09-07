import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/setting.dart' as model_setting;
import 'package:aplikasi_kasir_seafood/providers/setting_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _restoNameController;
  late TextEditingController _restoAddressController;
  late TextEditingController _receiptMessageController;
  String? _restoLogoPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );

    _restoNameController = TextEditingController(
      text: settingProvider.settings?.restoName ?? '',
    );
    _restoAddressController = TextEditingController(
      text: settingProvider.settings?.restoAddress ?? '',
    );
    _receiptMessageController = TextEditingController(
      text: settingProvider.settings?.receiptMessage ?? '',
    );
    _restoLogoPath = settingProvider.settings?.restoLogo;
  }

  @override
  void dispose() {
    _restoNameController.dispose();
    _restoAddressController.dispose();
    _receiptMessageController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _restoLogoPath = pickedFile.path;
      });
    }
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settingProvider = Provider.of<SettingProvider>(
        context,
        listen: false,
      );

      final newSettings = model_setting.Setting(
        id: settingProvider.settings?.id,
        restoName: _restoNameController.text,
        restoAddress: _restoAddressController.text,
        receiptMessage: _receiptMessageController.text,
        restoLogo: _restoLogoPath,
      );

      settingProvider.saveSettings(newSettings);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan berhasil disimpan!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Pengaturan'),
      drawer: const CustomDrawer(currentPage: 'Pengaturan',),
      body: Consumer<SettingProvider>(
        builder: (context, settingProvider, child) {
          if (settingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 🔹 Logo Preview
                  InkWell(
                    onTap: _pickLogo,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _restoLogoPath != null
                          ? FileImage(File(_restoLogoPath!))
                          : null,
                      child: _restoLogoPath == null
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Informasi Restoran
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Informasi Restoran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _restoNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Restoran',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Nama restoran wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _restoAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Alamat Restoran',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Pengaturan Struk
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pengaturan Struk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _receiptMessageController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Pesan Kaki Struk',
                              hintText: 'Contoh: Terima Kasih!',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🔹 Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Simpan Pengaturan',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
