import 'package:flutter/material.dart';
import 'package:handyshopper/localization/app_localizations.dart';

/// A full-screen multiline editor for an item's note.
///
/// Opened with the current [initialText]; returns the edited text via
/// `Navigator.pop`, or `null` if dismissed without saving.
class NoteEditorScreen extends StatefulWidget {
  /// Creates a [NoteEditorScreen] seeded with [initialText].
  const NoteEditorScreen({this.initialText = '', super.key});

  /// The note text to edit.
  final String initialText;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('note')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(_controller.text),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: null,
          expands: true,
          maxLength: 5000,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
    );
  }
}
