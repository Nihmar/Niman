import 'package:copist/src/library/session.dart';
import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:copist/src/ui/settings.dart';
import 'package:flutter/material.dart';

/// The Settings bottom-nav tab: today's settings list without its own
/// Scaffold — the shell provides the app bar.
final class SettingsTab extends StatelessWidget {
  /// Creates the settings tab.
  const new({required this.controller, this.spellCheck, super.key});

  /// The session of the library whose settings this tab edits.
  final LibrarySession controller;

  /// The editor's spelling state (T-PP-09), for its toggle; null hides it.
  final EditorSpellCheck? spellCheck;

  @override
  Widget build(BuildContext context) {
    return SettingsBody(controller: controller, spellCheck: spellCheck);
  }
}
