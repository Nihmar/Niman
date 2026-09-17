import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The frame every settings area screen wears (issue #104): the app bar
/// with back, the area's title, and — for a library area — the library's
/// name under it, over the screen's rows.
final class SettingsAreaShell extends StatelessWidget {
  /// Creates the frame for [title]'s rows.
  const new({
    required this.title,
    required this.controller,
    required this.body,
    this.library,
    super.key,
  });

  /// The area's name, the app bar's title.
  final String title;

  /// The session the screen edits; the library's name comes from it.
  final LibrarySession controller;

  /// Whether this is a library area: the name goes under the title, so
  /// a library setting cannot be changed for the wrong library.
  final bool? library;

  /// The screen's rows.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final library = this.library;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: library == true
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    AppStrings.settingsGroupLibrary(
                      p.basename(controller.root ?? ''),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(title),
      ),
      body: body,
    );
  }
}
