import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _selectedDateType = 'میلادی';
  // This variable is used for crown version.
  bool _isProVersionActivated = false;

  String get selectedDateType => _selectedDateType;

  set selectedDateType(String value) {
    _selectedDateType = value;
    notifyListeners();
    _saveSelectedDateType(value);
  }

  SettingsProvider() {
    _readSelectedDateType();
    _readSelectedVersion();
  }

  Future<void> _readSelectedDateType() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedDateType = prefs.getString('selectedDateType') ?? 'میلادی';
    notifyListeners();
  }

  Future<void> _saveSelectedDateType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedDateType', value);
  }

  /* -------------------- These lines of code are related to Crown Version ------------------ */
  bool get getSelectedVersion => _isProVersionActivated;

  set setSelectedVersion(bool value) {
    _isProVersionActivated = value;
    notifyListeners();
    _saveSelectedVersion(value);
  }

  Future<void> _readSelectedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    _isProVersionActivated = prefs.getBool('selectedCrownVersion') ?? false;
    notifyListeners();
  }

  Future<void> _saveSelectedVersion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('selectedCrownVersion', value);
  }
}
