/// The note as a centred column (issue #171).
///
/// A note used to fill whatever width its pane had: on a 1280 px window a
/// line of prose ran to about 180 characters. With the column on, the
/// text keeps to `NoteColumn.width` and the space left over goes to the
/// sides — in the editors, in the preview, and in the chrome around them
/// (toolbar, find bar, status row), so the editor reads as a page and not
/// as a text field.
///
/// One rule for every surface, and no platform check: the column is
/// min(pane, setting). A phone is narrower than any column, so there the
/// side space is zero and nothing moves; a tablet or a phone in landscape
/// gets the column the moment it has room for one.
///
/// Both editors and the preview inset their text by `textInset` from
/// their own edge; the side space is added on top of that. That is what
/// keeps the text's left edge at the same x when switching editors — the
/// source editor's row numbers are laid out inside the side space rather
/// than in front of the text (see `NoteEditor`).
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_config.dart';

/// Where a note's text sits across its pane.
@immutable
final class NoteColumn {
  /// A column [width] wide when [enabled].
  const new({this.enabled = true, this.width = defaultNoteColumnWidth});

  /// The full-width note: the text runs from edge to edge of its pane.
  static const NoteColumn off = NoteColumn(enabled: false);

  /// Whether the text keeps to a column at all.
  final bool enabled;

  /// The width of the text itself, in logical pixels.
  final double width;

  /// How far each surface keeps its text from its own edge, column or
  /// not: the WYSIWYG's and the preview's padding, which the source
  /// editor matches whenever there is side space to match it in.
  static const double textInset = 16;

  /// The space added on each side of the text in a surface [paneWidth]
  /// wide: zero when the column is off or the pane has no room for it.
  double sideSpaceIn(double paneWidth) {
    if (!enabled || !paneWidth.isFinite) return 0;
    return math.max(0, (paneWidth - width - 2 * textInset) / 2);
  }

  @override
  bool operator ==(Object other) =>
      other is NoteColumn && other.enabled == enabled && other.width == width;

  @override
  int get hashCode => Object.hash(enabled, width);

  @override
  String toString() => enabled ? 'NoteColumn($width)' : 'NoteColumn.off';
}

/// Lays [child] out inside [column]: the side space of its own width goes
/// to both sides as padding.
///
/// For the chrome that follows the text — the toolbar, the find bars, the
/// status row. Their background still spans the pane; only what is on
/// them moves in.
final class NoteColumnPadding extends StatelessWidget {
  /// Pads [child] by [column]'s side space.
  const new({required this.column, required this.child, super.key});

  /// The column to align to.
  final NoteColumn column;

  /// What goes inside it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!column.enabled) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = column.sideSpaceIn(constraints.maxWidth);
        if (side == 0) return child;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: side),
          child: child,
        );
      },
    );
  }
}
