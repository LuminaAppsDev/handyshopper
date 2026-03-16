import 'dart:async';

import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/privacy_policy_screen.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Screen for managing app settings such as currency, language, and privacy.
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('settings')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('general'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Currency selection
            ListTile(
              title: Text(
                AppLocalizations.of(context).translate('currency'),
              ),
              subtitle: Text(settingsProvider.currencySymbol),
              onTap: () {
                showCurrencyPicker(
                  context: context,
                  onSelect: (currency) {
                    unawaited(
                      settingsProvider.setCurrencySymbol(currency.symbol),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).translate('language'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Language selection
            ListTile(
              title: Text(
                AppLocalizations.of(context).translate('language'),
              ),
              subtitle: Text(
                settingsProvider.locale!.languageCode.toUpperCase(),
              ),
              onTap: () {
                _showLanguageDialog(context, settingsProvider);
              },
            ),
            const SizedBox(height: 20),
            // Privacy Policy entry
            ListTile(
              title: Text(
                AppLocalizations.of(context).translate('privacy_policy'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                unawaited(
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Method to show language selection dialog
  void _showLanguageDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context).translate('language'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'English',
                    const Locale('en', 'US'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Bengali (বাংলা)',
                    const Locale('bn', 'BD'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Chinese (中文)',
                    const Locale('zh', 'CN'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'French (Français)',
                    const Locale('fr', 'FR'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'German (Deutsch)',
                    const Locale('de', 'DE'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Hindi (हिन्दी)',
                    const Locale('hi', 'IN'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Italian (Italiano)',
                    const Locale('it', 'IT'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Japanese (日本語)',
                    const Locale('ja', 'JP'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Korean (한국어)',
                    const Locale('ko', 'KR'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Persian (فارسی)',
                    const Locale('fa', 'IR'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Portuguese (Português)',
                    const Locale('pt', 'PT'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Punjabi (ਪੰਜਾਬੀ)',
                    const Locale('pa', 'IN'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Russian (Русский)',
                    const Locale('ru', 'RU'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Spanish (Español)',
                    const Locale('es', 'ES'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Tamil (தமிழ்)',
                    const Locale('ta', 'IN'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Telugu (తెలుగు)',
                    const Locale('te', 'IN'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Turkish (Türkçe)',
                    const Locale('tr', 'TR'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Urdu (اردو)',
                    const Locale('ur', 'PK'),
                  ),
                  _buildLanguageTile(
                    context,
                    settingsProvider,
                    'Vietnamese (Tiếng Việt)',
                    const Locale('vi', 'VN'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    SettingsProvider settingsProvider,
    String label,
    Locale locale,
  ) {
    return ListTile(
      title: Text(label),
      onTap: () {
        unawaited(settingsProvider.setLocale(locale));
        Navigator.of(context).pop();
      },
    );
  }
}
