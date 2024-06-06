import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _selectedDateType = 'میلادی';

  String get selectedDateType => _selectedDateType;

  set selectedDateType(String value) {
    _selectedDateType = value;
    notifyListeners();
    _saveSelectedDateType(value);
  }

  SettingsProvider() {
    _readSelectedDateType();
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
}
