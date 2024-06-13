import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  Locale? _locale;
  String _currencySymbol = '\$';

  Locale? get locale => _locale;
  String get currencySymbol => _currencySymbol;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    final countryCode = prefs.getString('countryCode');
    _locale = Locale(languageCode, countryCode);

    _currencySymbol = prefs.getString('currencySymbol') ?? '\$';

    notifyListeners();
  }

   // Expose a Public Method to Load Settings
   Future<void> loadSettings() async {
    await _loadSettings();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('countryCode', locale.countryCode!);
    } else {
      await prefs.remove('countryCode');
    }
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencySymbol', symbol);
    notifyListeners();
  }
}
