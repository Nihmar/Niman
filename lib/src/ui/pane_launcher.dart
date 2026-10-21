/// What a pane with no note on screen offers (#1134): the ways in — a new
/// note, a note from a template, the note picker — and the notes shown
/// last, where a session starts. A new tab shows it, and so does a pane
/// with nothing open.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The launcher, centred in the pane.
final class PaneLauncher extends StatelessWidget {
  /// The launcher's actions, and the [recent] notes to offer.
  const new({
    required this.onNewNote,
    required this.onNewFromTemplate,
    required this.onGoToNote,
    required this.recent,
    required this.onOpen,
    super.key,
  });

  /// Makes a new note, in this pane.
  final VoidCallback onNewNote;

  /// Makes a note from a template, in this pane.
  final VoidCallback onNewFromTemplate;

  /// Opens the note picker.
  final VoidCallback onGoToNote;

  /// The notes shown last, library-relative, the latest first.
  final List<String> recent;

  /// Opens a note of [recent].
  final ValueChanged<String> onOpen;

  /// The width of the action column.
  static const double _width = 300;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget action(String key, IconData icon, String label, VoidCallback on) =>
        OutlinedButton.icon(
          key: Key(key),
          onPressed: on,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
            shape: const StadiumBorder(),
            foregroundColor: theme.colorScheme.onSurface,
            textStyle: theme.textTheme.bodyLarge,
          ),
        );
    return Center(
      key: const ValueKey('detail-empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: SizedBox(
          width: _width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              action(
                'launcher-new-note',
                Icons.edit_note,
                AppStrings.newNoteTitle,
                onNewNote,
              ),
              action(
                'launcher-template',
                Icons.dashboard_customize_outlined,
                AppStrings.newFromTemplateTitle,
                onNewFromTemplate,
              ),
              action(
                'launcher-go-to-note',
                Icons.search,
                AppStrings.goToNoteTitle,
                onGoToNote,
              ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: Text(
                    AppStrings.launcherRecent,
                    style: theme.textTheme.labelMedium?.copyWith(color: muted),
                  ),
                ),
                for (final (i, path) in recent.indexed)
                  TextButton(
                    key: Key('launcher-recent-$i'),
                    onPressed: () => onOpen(path),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      alignment: AlignmentDirectional.centerStart,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    child: Row(
                      spacing: 14,
                      children: [
                        Icon(Icons.history, size: 18, color: muted),
                        Expanded(
                          child: Text(
                            noteTabLabel(path),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.posix.dirname(path) case final folder
                            when folder != '.')
                          Flexible(
                            child: Text(
                              folder,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
