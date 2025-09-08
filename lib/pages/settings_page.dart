import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/setting.dart' as model_setting;
import 'package:aplikasi_kasir_seafood/providers/setting_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  late TextEditingController _phoneController;
  late TextEditingController _phone2Controller;
  String? _restoLogoPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final settingProvider = Provider.of<SettingProvider>(
      context,
      listen: false,
    );
    final setting = settingProvider.settings;

    _restoNameController = TextEditingController(
      text: setting?.restoName ?? '',
    );
    _restoAddressController = TextEditingController(
      text: setting?.restoAddress ?? '',
    );
    _receiptMessageController = TextEditingController(
      text: setting?.receiptMessage ?? '',
    );
    _phoneController = TextEditingController(text: setting?.restoPhone ?? '');
    _phone2Controller = TextEditingController(text: setting?.restoPhone2 ?? '');
    _restoLogoPath = setting?.restoLogo;
  }

  @override
  void dispose() {
    _restoNameController.dispose();
    _restoAddressController.dispose();
    _receiptMessageController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    super.dispose();
  }

  // ✅ Metode baru untuk menyimpan file gambar secara permanen
  Future<String?> _saveLogoPermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(imagePath);
    final File newImage = await File(
      imagePath,
    ).copy('${directory.path}/$fileName');
    return newImage.path;
  }

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // ✅ Menyimpan file secara permanen dan mendapatkan path baru
      final permanentPath = await _saveLogoPermanently(pickedFile.path);
      setState(() {
        _restoLogoPath = permanentPath;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settingProvider = Provider.of<SettingProvider>(
        context,
        listen: false,
      );

      final newSettings = model_setting.Setting(
        id: settingProvider.settings?.id,
        restoName: _restoNameController.text.trim(),
        restoAddress: _restoAddressController.text.trim(),
        receiptMessage: _receiptMessageController.text.trim(),
        restoLogo: _restoLogoPath,
        restoPhone: _phoneController.text.trim(),
        restoPhone2: _phone2Controller.text.trim(),
      );

      await settingProvider.saveSettings(newSettings);

      if (!mounted) return;
      CustomNotification.show(
        context,
        'Pengaturan berhasil disimpan!',
        backgroundColor: Colors.green,
        icon: Icons.check,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Pengaturan'),
      drawer: const CustomDrawer(currentPage: 'Pengaturan'),
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
                  // Logo Preview
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

                  // Informasi Restoran
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Informasi Restoran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _restoNameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Restoran',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Nama restoran tidak boleh kosong'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _restoAddressController,
                            decoration: InputDecoration(
                              labelText: 'Alamat Restoran',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Nomor Telepon 1',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone2Controller,
                            decoration: InputDecoration(
                              labelText: 'Nomor Telepon 2 (opsional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pengaturan Struk
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pengaturan Struk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _receiptMessageController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Pesan Kaki Struk',
                              hintText: 'Contoh: Terima Kasih!',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Pengaturan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
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
