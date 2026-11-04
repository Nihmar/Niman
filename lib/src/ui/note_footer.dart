/// The rows under the open note: the frontmatter warning, the notes and the
/// tasks that link it, the status row and the phone's toolbar (issue #100
/// moved them out of `note_view.dart`).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/ui/links_to_note_section.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/note_tasks_section.dart';
import 'package:niman/src/ui/note_view_chrome.dart';

/// The note's bottom chrome. Purely presentational: everything it reads
/// arrives as constructor params, and every tap leaves through a callback.
final class NoteFooter extends StatelessWidget {
  /// The rows under the note, keeping to [column].
  const new({
    required this.column,
    required this.loading,
    required this.ready,
    required this.frontmatterError,
    required this.showRelated,
    required this.linkSource,
    required this.notePath,
    required this.onOpenNote,
    required this.showTasks,
    required this.tasks,
    required this.statusRow,
    required this.toolbarBelow,
    required this.showToolbar,
    required this.toolbar,
    super.key,
  });

  /// Where the note's text sits across the pane.
  final NoteColumn column;

  /// Whether the note is loading.
  final bool loading;

  /// Whether the note is loaded.
  final bool ready;

  /// The parser's message for the note's malformed frontmatter, or null.
  final String? frontmatterError;

  /// Whether the notes and tasks that link this one show here: not while
  /// the window's panel has them.
  final bool showRelated;

  /// Where the notes that link this one are read from.
  final MentionSource? linkSource;

  /// The note's path in the library, or null outside one.
  final String? notePath;

  /// Opens a note that links this one.
  final ValueChanged<String> onOpenNote;

  /// Whether the library's Todo feature is on.
  final bool showTasks;

  /// The tasks that link a note, or null with no library.
  final NoteTasksHost? tasks;

  /// The status row.
  final Widget statusRow;

  /// Whether the toolbar sits here, below the note (the phone's), once the
  /// note is loaded.
  final bool toolbarBelow;

  /// Whether the toolbar shows now.
  final bool showToolbar;

  /// Builds the toolbar.
  final WidgetBuilder toolbar;

  @override
  Widget build(BuildContext context) => SafeArea(
    // The bottom chrome only: top stays false so the status-bar
    // inset is never inserted between the preview and this row
    // (issue #3: that gap read as empty space above the toolbar).
    top: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The malformed-frontmatter line (T-M4-01).
        //
        // A block that does not parse is indexed as if it were not there —
        // no title, no tags, no fields — and nothing else in the app would
        // say so. This does, with the parser's own message, while the note
        // is open and the mistake is still in front of the person who made
        // it.
        if (!loading && frontmatterError != null)
          FrontmatterWarningBanner(message: frontmatterError!),
        // The notes that link to this one (#842), under the note.
        if (!loading && ready && showRelated)
          NoteColumnPadding(
            column: column,
            child: LinksToNoteSection(
              source: linkSource,
              path: notePath,
              onOpenNote: onOpenNote,
            ),
          ),
        // The tasks that link it (#1152), under the links.
        if (!loading && ready && showRelated && showTasks)
          NoteColumnPadding(
            column: column,
            child: NoteTasksSection(host: tasks, path: notePath),
          ),
        NoteColumnPadding(column: column, child: statusRow),
        // The toolbar fades + sizes in and out (hidden in preview
        // mode). It is only mounted once loaded, so it appears
        // immediately on load and animates only when preview mode
        // toggles. Phone only: on desktop it lives above the
        // editor (the top slot).
        if (toolbarBelow)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showToolbar
                ? NoteColumnPadding(column: column, child: toolbar(context))
                : const SizedBox(width: double.infinity),
          ),
      ],
    ),
  );
}
