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

  late Map<String, String> _localizedStrings;

  /// Loads the localized strings from the JSON asset file.
  Future<bool> load() async {
    final jsonString = await rootBundle
        .loadString('assets/translations/${locale.languageCode}.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  /// Returns the translated string for the given [key].
  String translate(String key) {
    return _localizedStrings[key] ?? key;
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
