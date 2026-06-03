import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Thin wrapper around the platform share / file-picker plugins.
///
/// Isolated from the rest of the app so the pure logic (text formatting,
/// JSON (de)serialization) stays unit-testable while the plugin calls live in
/// one place.
class ShareService {
  /// Shares plain [text] via the system share sheet.
  Future<void> shareText(String text) {
    return SharePlus.instance.share(ShareParams(text: text));
  }

  /// Writes [jsonContent] to a temporary [fileName] and shares it as a file,
  /// optionally with accompanying [text].
  Future<void> shareJsonFile(
    String fileName,
    String jsonContent, {
    String? text,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(jsonContent);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }

  /// The largest import file accepted, guarding against memory exhaustion.
  static const int maxImportBytes = 10 * 1024 * 1024; // 10 MB

  /// Prompts the user to pick a `.json` file and returns its decoded content,
  /// or `null` if the picker was cancelled, the file was too large, or its
  /// content could not be read as a JSON object.
  Future<Map<String, dynamic>?> pickJsonData() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final bytes = result?.files.singleOrNull?.bytes;
    if (bytes == null || bytes.length > maxImportBytes) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null; // malformed UTF-8 or JSON
    }
  }
}
