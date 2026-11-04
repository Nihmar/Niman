/// What frames the editor pane of the open note: its find bar above it, the
/// frontmatter fields panel, and the find keys over both (issue #100 moved
/// it out of `note_view.dart`).
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/find_bar.dart';
import 'package:niman/src/editor/note_column.dart';

/// The editor pane's frame. Purely presentational: everything it reads
/// arrives as constructor params.
final class NoteEditorFrame extends StatelessWidget {
  /// Frames [child], the note, under the bar of [find].
  const new({
    required this.find,
    required this.column,
    required this.frontmatter,
    required this.onKey,
    required this.child,
    super.key,
  });

  /// The note's find & replace, whose bar shows above the note.
  final FindBarModel find;

  /// Where the note's text sits across the pane.
  final NoteColumn column;

  /// The frontmatter fields panel, or null when the note has none to show.
  final Widget? frontmatter;

  /// The find keys, for the note and its bar.
  final FocusOnKeyEventCallback onKey;

  /// The note.
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: onKey,
    child: Column(
      children: <Widget>[
        ListenableBuilder(
          listenable: find,
          builder: (context, _) =>
              FindBar(controller: find, column: column, keyPrefix: 'source'),
        ),
        // The fields panel, above the note's first line, in the same place
        // the read view shows it: the note itself is still the source, and
        // its frontmatter lines are still text below this (#157). The inset
        // is the note's own: a box with an edge of its own does not run to
        // the pane's edge when there is no column to align to.
        if (frontmatter case final panel?)
          NoteColumnPadding(
            column: column,
            minInset: NoteColumn.textInset,
            child: panel,
          ),
        Expanded(child: child),
      ],
    ),
  );
}
