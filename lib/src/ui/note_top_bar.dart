import 'package:flutter/material.dart';
import 'package:niman/src/editor/note_column.dart';

/// The one row of chrome above a note on the desktop (issue #173).
///
/// It used to be two: a header naming the note with its ⋮ menu, and the
/// formatting toolbar under it, running the width of the pane. Now the
/// [toolbar] sits on the left and the note's own [actions] — the kind
/// toggles and the ⋮ — at the right end of the same row, and the whole
/// row keeps to the note's [column], so the first button starts where
/// the text does.
///
/// The row is there even with no [toolbar] (the preview, a list note, a
/// file that did not open): the ⋮ stays where the hand last found it.
final class NoteTopBar extends StatelessWidget {
  /// Creates the row; a null [toolbar] leaves only the [actions].
  const new({
    required this.column,
    required this.actions,
    this.toolbar,
    super.key,
  });

  /// The note's column, which the row keeps to.
  final NoteColumn column;

  /// The formatting toolbar, or null when there is nothing to format.
  final Widget? toolbar;

  /// The note's own controls, at the right end.
  final List<Widget> actions;

  /// The row's height: the toolbar's, with room around it.
  static const double height = 38;

  @override
  Widget build(BuildContext context) {
    final toolbar = this.toolbar;
    return Column(
      key: const Key('note-top-bar'),
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteColumnPadding(
          column: column,
          child: SizedBox(
            height: height,
            child: Padding(
              // The first button's icon lands on the text's left edge
              // (NoteColumn.textInset, less the button's own padding).
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: toolbar == null
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: toolbar,
                          ),
                  ),
                  // Sized like the toolbar's buttons, not like a phone's.
                  IconButtonTheme(
                    data: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        iconSize: 18,
                        minimumSize: const Size(30, 30),
                        padding: const EdgeInsets.all(6),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
