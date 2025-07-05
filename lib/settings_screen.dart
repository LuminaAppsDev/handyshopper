import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:currency_picker/currency_picker.dart';
import 'providers/settings_provider.dart';
import 'localization/app_localizations.dart';
import 'privacy_policy_screen.dart'; // Import the privacy policy screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('settings')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('general'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Currency selection
            ListTile(
              title: Text(AppLocalizations.of(context).translate('currency')),
              subtitle: Text(settingsProvider.currencySymbol),
              onTap: () {
                showCurrencyPicker(
                  context: context,
                  showFlag: true,
                  showCurrencyName: true,
                  showCurrencyCode: true,
                  onSelect: (Currency currency) {
                    settingsProvider.setCurrencySymbol(currency.symbol);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).translate('language'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Language selection
            ListTile(
              title: Text(AppLocalizations.of(context).translate('language')),
              subtitle: Text(settingsProvider.locale!.languageCode.toUpperCase()),
              onTap: () {
                _showLanguageDialog(context, settingsProvider);
              },
            ),
            const SizedBox(height: 20),
            // Privacy Policy entry
            ListTile(
              title: Text(AppLocalizations.of(context).translate('privacy_policy')),
              trailing: const Icon(Icons.arrow_forward_ios), // Add arrow icon
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
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
  void _showLanguageDialog(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('language')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('English'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('en', 'US'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Bengali (বাংলা)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('bn', 'BD'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Chinese (中文)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('zh', 'CN'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('French (Français)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('fr', 'FR'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('German (Deutsch)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('de', 'DE'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Hindi (हिन्दी)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('hi', 'IN'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Italian (Italiano)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('it', 'IT'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Japanese (日本語)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('ja', 'JP'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Korean (한국어)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('ko', 'KR'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Persian (فارسی)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('fa', 'IR'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Portuguese (Português)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('pt', 'PT'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Punjabi (ਪੰਜਾਬੀ)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('pa', 'IN'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Russian (Русский)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('ru', 'RU'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Spanish (Español)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('es', 'ES'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Tamil (தமிழ்)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('ta', 'IN'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Telugu (తెలుగు)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('te', 'IN'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Turkish (Türkçe)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('tr', 'TR'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Urdu (اردو)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('ur', 'PK'));
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Vietnamese (Tiếng Việt)'),
                  onTap: () {
                    settingsProvider.setLocale(const Locale('vi', 'VN'));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
