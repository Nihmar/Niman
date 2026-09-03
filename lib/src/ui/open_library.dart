import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// The open/create screen.
///
/// Both flows go through the native directory picker (Storage Access
/// Framework on Android, xdg-desktop-portal on Linux) — no manual path
/// entry, so a library root can only ever be a real, readable folder.
final class OpenLibraryScreen extends StatefulWidget {
  /// Creates the open/create screen.
  const OpenLibraryScreen({required this.controller, super.key});

  /// The session that opens or creates the library for this screen.
  final LibrarySession controller;

  @override
  State<OpenLibraryScreen> createState() => _OpenLibraryScreenState();
}

final class _OpenLibraryScreenState extends State<OpenLibraryScreen> {
  /// True while a picker or open is in flight.
  bool _busy = false;

  /// A picker/open failure that the session does not know about.
  String? _pickerError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opening = widget.controller.phase == LibraryPhase.opening;
    final error = widget.controller.lastError ?? _pickerError;
    final active = opening || _busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Copist')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/feather.png',
                  key: const Key('branding'),
                  width: 72,
                ),
                const SizedBox(height: 12),
                Text('Copist', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Open a folder of Markdown notes as your library',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: active ? null : _openExisting,
                      child: const Text('Open existing'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: active ? null : _createNew,
                      child: const Text('Create new'),
                    ),
                  ],
                ),
                if (active)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openExisting() async {
    _pickerError = null;
    final path = await _pickDirectory('Choose the library folder');
    if (path == null) return;
    await widget.controller.open(path, create: false);
    // The controller's event stream drives the rebuild (phase/lastError).
  }

  Future<void> _createNew() async {
    _pickerError = null;
    final parent = await _pickDirectory(
      'Choose the folder the library will be created in',
    );
    if (parent == null) return;
    final name = await _promptName();
    if (name == null || name.isEmpty) return;
    await widget.controller.open(p.join(parent, name), create: true);
    // The controller's event stream drives the rebuild (phase/lastError).
  }

  /// Opens the native directory picker; `null` when the user cancels.
  Future<String?> _pickDirectory(String title) async {
    _setBusy(true);
    try {
      final path = await FilePicker.getDirectoryPath(dialogTitle: title);
      _setBusy(false);
      return path;
    } on Object catch (error) {
      // For example "unknown_path" from SAF for protected trees.
      _setBusy(false);
      _pickerError = 'Could not pick a folder: $error';
      return null;
    }
  }

  Future<String?> _promptName() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _NewLibraryDialog(),
    );
  }

  void _setBusy(bool busy) {
    if (_busy == busy) return;
    setState(() => _busy = busy);
  }
}

/// Dialog that asks for the name of the new library folder.
final class _NewLibraryDialog extends StatefulWidget {
  /// Creates the dialog.
  const _NewLibraryDialog();

  @override
  State<_NewLibraryDialog> createState() => _NewLibraryDialogState();
}

final class _NewLibraryDialogState extends State<_NewLibraryDialog> {
  late final TextEditingController _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so "Create" tracks the (trimmed) name.
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _text.text.trim();
    return AlertDialog(
      title: const Text('Create new library'),
      content: TextField(
        controller: _text,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Folder name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: name.isEmpty ? null : _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(_text.text.trim());
  }
}
