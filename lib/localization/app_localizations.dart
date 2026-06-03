import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Provides localized strings for the app based on the current locale.
class AppLocalizations {
  /// Creates an [AppLocalizations] for the given [locale].
  AppLocalizations(this.locale);

  /// The current locale.
  final Locale locale;

  /// Returns the [AppLocalizations] instance for the given [context].
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// The localization delegate for [AppLocalizations].
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// The canonical English strings, used as a fallback for keys not yet
  /// translated in the active locale.
  static const String _fallbackLanguage = 'en';

  late Map<String, String> _localizedStrings;
  Map<String, String> _fallbackStrings = const {};

  /// Loads the localized strings from the JSON asset file, plus the English
  /// strings as a fallback (skipped when the active locale is already English).
  Future<bool> load() async {
    _localizedStrings = await _loadLanguage(locale.languageCode);
    _fallbackStrings = locale.languageCode == _fallbackLanguage
        ? _localizedStrings
        : await _loadLanguage(_fallbackLanguage);
    return true;
  }

  Future<Map<String, String>> _loadLanguage(String languageCode) async {
    final jsonString =
        await rootBundle.loadString('assets/translations/$languageCode.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  /// Returns the translated string for [key]: the active-locale value, then the
  /// English fallback, then the key itself.
  String translate(String key) {
    return _localizedStrings[key] ?? _fallbackStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return [
      'en',
      'de',
      'ja',
      'fr',
      'it',
      'es',
      'ko',
      'ru',
      'zh',
      'hi',
      'bn',
      'pt',
      'vi',
      'tr',
      'mr',
      'te',
      'pa',
      'ta',
      'fa',
      'ur',
    ].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
