import 'dart:async';
import 'dart:io';

import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The manual open/create screen (M1 scope: manual path entry; M6 onboarding
/// will replace this flow).
final class OpenLibraryScreen extends StatefulWidget {
  /// Creates the open/create screen.
  const OpenLibraryScreen({required this.controller, super.key});

  /// The session that opens or creates the library for this screen.
  final LibrarySession controller;

  /// A sensible default path for the current platform.
  static Future<String> defaultLibraryPath() async {
    if (Platform.isAndroid) {
      // App-specific storage for early builds (M1 scope).
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
    final home = Platform.environment['HOME'] ?? '/';
    return p.join(home, 'Copist');
  }

  @override
  State<OpenLibraryScreen> createState() => _OpenLibraryScreenState();
}

final class _OpenLibraryScreenState extends State<OpenLibraryScreen> {
  late final TextEditingController _text = TextEditingController();
  bool _defaultSet = false;

  @override
  void initState() {
    super.initState();
    unawaited(_setDefaultPath());
  }

  Future<void> _setDefaultPath() async {
    final path = await OpenLibraryScreen.defaultLibraryPath();
    if (mounted && !_defaultSet && _text.text.isEmpty) {
      _text.text = path;
      _defaultSet = true;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool create}) async {
    final path = _text.text.trim();
    if (path.isEmpty) return;
    await widget.controller.open(path, create: create);
    // The controller's event stream drives the rebuild (phase/lastError).
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opening = widget.controller.phase == LibraryPhase.opening;
    final error = widget.controller.lastError;
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: TextField(
                    controller: _text,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Library root path',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: opening ? null : () => _submit(create: false),
                      child: const Text('Open existing'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: opening ? null : () => _submit(create: true),
                      child: const Text('Create new'),
                    ),
                  ],
                ),
                if (opening)
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
}
