import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/setting.dart' as model_setting;
import 'package:aplikasi_kasir_seafood/services/setting_service.dart';

class SettingProvider with ChangeNotifier {
  final SettingService _settingService = SettingService();

  model_setting.Setting? _settings;
  bool _isLoading = false;

  model_setting.Setting? get settings => _settings;
  bool get isLoading => _isLoading;

  SettingProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _settingService.getSettings();

    // Normalisasi biar gak null/empty string
    if (_settings != null) {
      if (_settings!.restoPhone == null || _settings!.restoPhone!.isEmpty) {
        _settings = _settings!.copyWith(restoPhone: "Nomor Telepon Restoran");
      }
      if (_settings!.restoPhone2 == null || _settings!.restoPhone2!.isEmpty) {
        _settings = _settings!.copyWith(restoPhone2: "");
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSettings(model_setting.Setting newSettings) async {
    await _settingService.saveSettings(newSettings);
    await loadSettings();
  }
}
