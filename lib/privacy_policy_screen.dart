import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure this import is added
import 'providers/settings_provider.dart';
import 'localization/app_localizations.dart'; // Import AppLocalizations

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<String> loadPrivacyPolicy(BuildContext context) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final locale = settingsProvider.locale ?? const Locale('en', 'US');
    final languageCode = locale.languageCode;

    final filePath = 'assets/privacy_policies/privacy_policy_$languageCode.md';
    try {
      return await rootBundle.loadString(filePath);
    } catch (e) {
      return await rootBundle.loadString('assets/privacy_policies/privacy_policy_en.md');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('privacy_policy')), // Use localized string
      ),
      body: FutureBuilder<String>(
        future: loadPrivacyPolicy(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading privacy policy'));
          }
          return Markdown(
            data: snapshot.data ?? '',
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href));
              }
            },
          );
        },
      ),
    );
  }
}
