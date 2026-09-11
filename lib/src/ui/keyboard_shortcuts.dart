/// The in-app keyboard reference (T-PP-10).
///
/// Built from the same registry the shell installs, so a key that is
/// documented is one that actually runs.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/strings.dart';

/// Lists the app accelerators and the editor's own keys.
final class KeyboardShortcutsScreen extends StatelessWidget {
  /// Creates the reference screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyStyle = TextStyle(
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
    );
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.keyboardShortcutsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final shortcut in nimanAppShortcuts)
            ListTile(
              key: Key('shortcut-${shortcut.command.name}'),
              title: Text(appCommandLabel(shortcut.command)),
              trailing: Text(
                describeActivator(shortcut.activation),
                style: keyStyle,
              ),
            ),
          ListTile(
            title: Text(
              AppStrings.shortcutEditorSection,
              style: theme.textTheme.titleSmall,
            ),
          ),
          ListTile(
            title: Text(AppStrings.shortcutFind),
            trailing: Text('Ctrl+F', style: keyStyle),
          ),
          ListTile(
            title: Text(AppStrings.shortcutReplace),
            trailing: Text('Ctrl+H', style: keyStyle),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              AppStrings.shortcutSavingNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
