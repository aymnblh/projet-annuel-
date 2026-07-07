import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModeProvider extends ChangeNotifier {
  String _mode = 'sale'; // 'sale' or 'rent'
  bool _isLoaded = false;
  bool _isFirstTime = false;

  String get mode => _mode;
  bool get isLoaded => _isLoaded;
  bool get isFirstTime => _isFirstTime;
  bool get isBuyMode => _mode == 'sale';
  bool get isRentMode => _mode == 'rent';

  AppModeProvider() {
    _loadMode();
  }

  Future<void> setMode(String mode) async {
    _mode = mode;
    _isFirstTime = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appMode', mode);
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('appMode');
    if (saved == null) {
      _isFirstTime = true;
      _mode = 'sale';
    } else {
      _isFirstTime = false;
      _mode = saved;
    }
    _isLoaded = true;
    notifyListeners();
  }
}
