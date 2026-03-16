import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide settings such as locale and currency.
class SettingsProvider with ChangeNotifier {
  /// Creates a [SettingsProvider] and loads persisted settings.
  SettingsProvider() {
    unawaited(_loadSettings());
  }

  Locale? _locale;
  String _currencySymbol = r'$';

  /// The current locale, or `null` if not yet loaded.
  Locale? get locale => _locale;

  /// The current currency symbol.
  String get currencySymbol => _currencySymbol;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    final countryCode = prefs.getString('countryCode');
    _locale = Locale(languageCode, countryCode);

    _currencySymbol = prefs.getString('currencySymbol') ?? r'$';

    notifyListeners();
  }

  /// Reloads settings from shared preferences.
  Future<void> loadSettings() async {
    await _loadSettings();
  }

  /// Sets the app locale and persists it.
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

  /// Sets the currency symbol and persists it.
  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currencySymbol', symbol);
    notifyListeners();
  }
}
