import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final settingProvider = Provider.of<SettingProvider>(context, listen: false);
    
    _restoNameController = TextEditingController(text: settingProvider.settings?.restoName ?? '');
    _restoAddressController = TextEditingController(text: settingProvider.settings?.restoAddress ?? '');
    _receiptMessageController = TextEditingController(text: settingProvider.settings?.receiptMessage ?? '');
  }

  @override
  void dispose() {
    _restoNameController.dispose();
    _restoAddressController.dispose();
    _receiptMessageController.dispose();
    super.dispose();
  }
  
  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settingProvider = Provider.of<SettingProvider>(context, listen: false);
      final newSettings = model_setting.Setting(
        id: settingProvider.settings?.id,
        restoName: _restoNameController.text,
        restoAddress: _restoAddressController.text,
        receiptMessage: _receiptMessageController.text,
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
      drawer: const CustomDrawer(),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Restoran',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _restoNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Restoran',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Nama restoran wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _restoAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Restoran',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pengaturan Struk',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _receiptMessageController,
                    decoration: const InputDecoration(
                      labelText: 'Pesan Kaki Struk (contoh: Terima Kasih!)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Simpan Pengaturan'),
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
