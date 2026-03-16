import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen that displays the app's privacy policy.
class PrivacyPolicyScreen extends StatelessWidget {
  /// Creates a [PrivacyPolicyScreen].
  const PrivacyPolicyScreen({super.key});

  /// Loads the privacy policy markdown for the current locale.
  Future<String> loadPrivacyPolicy(BuildContext context) async {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    final locale = settingsProvider.locale ?? const Locale('en', 'US');
    final languageCode = locale.languageCode;

    final filePath = 'assets/privacy_policies/privacy_policy_$languageCode.md';
    try {
      return await rootBundle.loadString(filePath);
    } on Exception catch (_) {
      return rootBundle
          .loadString('assets/privacy_policies/privacy_policy_en.md');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('privacy_policy'),
        ),
      ),
      body: FutureBuilder<String>(
        future: loadPrivacyPolicy(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading privacy policy'),
            );
          }
          return Markdown(
            data: snapshot.data ?? '',
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            onTapLink: (text, href, title) {
              if (href != null) {
                unawaited(launchUrl(Uri.parse(href)));
              }
            },
          );
        },
      ),
    );
  }
}
