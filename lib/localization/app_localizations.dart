import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  // Constructor to initialize locale
  AppLocalizations(this.locale);

  // Helper method to fetch the appropriate instance of AppLocalizations
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // List of supported locales
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  // Load JSON data for the specified locale
  Future<bool> load() async {
    // Load the JSON file from the "assets/translations" directory
    String jsonString = await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    // Convert JSON to a map of string keys and values
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  // Translate a key to the localized string
  String translate(String key) {
    return _localizedStrings[key] ?? '';
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  // Check if the locale is supported
  @override
  bool isSupported(Locale locale) {
    return [
      'en', 'de', 'ja', 'fr', 'it', 'es', 'ko', 'ru', 'zh',
      'hi', 'bn', 'pt', 'vi', 'tr', 'mr', 'te', 'pa', 'ta',
      'fa', 'ur'
    ].contains(locale.languageCode);
  }

  // Load the localization data for the given locale
  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  // Reload the localization data when the delegate changes
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
