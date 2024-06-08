import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Define initial locale and currency symbol
  Locale _locale = const Locale('en', 'US');
  String _currencySymbol = '€';

  Locale get locale => _locale;
  String get currencySymbol => _currencySymbol;

  // Method to set the locale and store it persistently
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('locale', locale.toString());
  }

  // Method to set the currency symbol and store it persistently
  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('currencySymbol', symbol);
  }

  // Method to load settings from persistent storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = prefs.getString('locale');
    if (localeString != null) {
      final localeList = localeString.split('_');
      _locale = Locale(localeList[0], localeList.length > 1 ? localeList[1] : '');
    }
    _currencySymbol = prefs.getString('currencySymbol') ?? '€';
  }
}
