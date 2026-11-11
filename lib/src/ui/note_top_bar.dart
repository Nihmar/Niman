import 'package:flutter/material.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/ui/note_top_bar_room.dart';
import 'package:niman/src/ui/pointer_density.dart';

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

  /// The row's height on a touch device (#1266): a thumb's buttons, with
  /// room around them.
  static const double touchHeight = 54;

  @override
  Widget build(BuildContext context) {
    final toolbar = this.toolbar;
    // A tablet's row holds its Edit | Read and its ⋮ at a thumb's size
    // (#1266); a mouse's keeps the toolbar's.
    final touch = thumbDense(Theme.of(context));
    final row = Row(mainAxisSize: MainAxisSize.min, children: actions);
    return Column(
      key: const Key('note-top-bar'),
      mainAxisSize: MainAxisSize.min,
      children: [
        NoteColumnPadding(
          column: column,
          child: SizedBox(
            height: touch ? touchHeight : height,
            child: LayoutBuilder(
              builder: (context, constraints) => NoteTopBarRoom(
                roomy: constraints.maxWidth >= roomForLabels,
                child: _row(toolbar, row, touch: touch),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  /// The least width of the row its controls show their labels in.
  static const double roomForLabels = 420;

  Widget _row(Widget? toolbar, Widget row, {required bool touch}) => SizedBox(
    height: double.infinity,
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
          if (touch)
            row
          else
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
              child: row,
            ),
        ],
      ),
    ),
  );
}
