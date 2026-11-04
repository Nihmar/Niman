import 'package:flutter/painting.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/column_layout.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/note_margins.dart';

/// What the source view's last frame laid the note out with: the pane's
/// width and the text's scale, the column's side space, the gutter and the
/// text's width — and the lengths counted from them.
///
/// Read in `build`, where the inherited widgets may be asked, and reused by
/// the layouts the caret, the gestures and the estimates ask for outside it.
final class SourceMetrics {
  /// The metrics of a note drawn with [_theme] in [_column].
  new({
    required this._theme,
    required this._column,
    required this._numberedLines,
  });

  /// The theme the lines are drawn with.
  final MarkdownTheme Function() _theme;

  /// The column the note is set in.
  final NoteColumn Function() _column;

  /// How many lines the gutter numbers, or null when it numbers none.
  final int? Function() _numberedLines;

  /// The width the text has, from the last frame that laid it out.
  double? paneWidth;

  /// The text scale the lines are drawn at, from the last frame.
  TextScaler textScaler = TextScaler.noScaling;

  /// The space the note column puts on each side of the text.
  double sideSpace = 0;

  /// The gutter's width this frame: the numbers, and with a note column the
  /// legacy `side + 16 - 5`, so the text starts exactly on the column's edge.
  double gutter = 0;

  /// The width the lines' text has, from the last frame that laid it out:
  /// what a table wider than it is fitted to.
  double textWidth = 0;

  /// The text scaler and the syntax colours of the last frame that laid the
  /// note out: read in `build`, where the inherited widgets may be asked,
  /// and reused by the layouts the caret and the gestures ask for outside
  /// it — a table's pieces are needed before the first frame, when asking
  /// `MediaQuery` would be an error, and after it this is the same value
  /// that frame used.
  TextScaler scaler = TextScaler.noScaling;

  /// The syntax colours of the last frame, as [scaler] is its scaler.
  SyntaxColors? syntax;

  ({int digits, TextStyle style, TextScaler scaler, double width})? _digits;

  /// An em of the note's text, as drawn: what a column's minimum and the
  /// gap between columns are counted in.
  double get em => textScaler.scale(_theme().body.fontSize ?? 14);

  /// The room between two columns, and between two rows of them.
  double get gap => ColumnLayout.gapEms * em;

  /// A fence line's band, as drawn.
  double get band => textScaler.scale(_theme().divBand);

  /// One row's height as the lines are drawn: the theme's, at the note's
  /// text scale. The theme's own number is the unscaled one, and paging or
  /// estimating with it put the caret short of where a page ends at any size
  /// but 100 %.
  double get rowHeight => textScaler.scale(_theme().lineHeight);

  /// The field's inset on the left ([noteFieldInset]).
  static const double _fieldInset = noteFieldInset;

  /// The field's inset on the right: the column's edge, as the read view's
  /// ([noteTextInsets]).
  double get rightInset => sideSpace + NoteColumn.textInset;

  /// The field's inset on the left.
  double get leftInset => _fieldInset;

  /// How far the list items and the quote [run] stands in indent its
  /// columns.
  double itemsIndent(LiveRun run) =>
      run.items * _theme().listIndentPerLevel +
      run.quoteDepth * _theme().quoteIndentPerLevel;

  /// The note box's x where [layout]'s columns start: past the gutter, and
  /// the indent of the list items the block stands in.
  double columnsLeft(LiveLayout layout) =>
      leftInset + gutter + itemsIndent(layout.run);

  /// Roughly how many monospace characters fit a line at this width and size.
  ///
  /// The pane's real width is not known here (the estimator is asked before a
  /// frame), so this is deliberately a *shape* and not a measurement: the
  /// sliver
  /// replaces every estimate with the line's own height as soon as it draws it,
  /// and only a jump made before that first frame can see the difference.
  double get columnsPerLine {
    final size = textScaler.scale(_theme().body.fontSize ?? 14);
    final advance = size * 0.6;
    if (advance <= 0) return 1;
    // The pane's real width once a frame has measured it; before that a guess,
    // which the sliver replaces with measured heights as it draws each line.
    final width = paneWidth ?? 360;
    return (width - gutter) / advance;
  }

  /// Lays the pane out [width] wide with its text at [scaler]: the side
  /// space, the gutter and the text's width that leaves. Answers whether the
  /// width or the scale changed, which wraps the caret's line anew.
  bool layOut(double width, TextScaler scaler) {
    final changed = paneWidth != width || textScaler != scaler;
    paneWidth = width;
    textScaler = scaler;
    // The legacy editor's box, to the pixel (`note_editor.dart`):
    // `side` is the note column's side space, the gutter is
    // `side + 16 - 5` when there is a column (and never narrower than
    // the numbers), the field is inset by 5 on the left and by
    // `side + 16` on the right. The text therefore measures exactly
    // `column.width` and sits centred — which is what the column means,
    // and what a gutter eating into it made narrower.
    sideSpace = _column().sideSpaceIn(width);
    // The gutter is the numbers *or* the column's own indentation: the
    // legacy editor reserved `side + 16 - 5` even with the numbers
    // turned
    // off, which is what keeps a column centred when the gutter is
    // empty.
    // The text's left edge is the read view's ([noteTextInsets]): the
    // column's edge, or past the numbers — with no column too, where
    // it stood 5 px in and moved at every flip to the read pane.
    gutter =
        noteTextInsets(side: sideSpace, numbers: _numbersWidth(scaler)).left -
        leftInset;
    // The pane's text width: what a table wider than it is fitted to.
    // Kept here so every caller that lays a table out reads the same
    // number, the gesture path included.
    textWidth = width - leftInset - rightInset - gutter;
    return changed;
  }

  /// How wide the numbers are in the note's own face, plus the gap
  /// ([lineNumbersWidth]); kept while the digits, the face and the scale are.
  double _numbersWidth(TextScaler scaler) {
    final lines = _numberedLines();
    if (lines == null) return 0;
    final digits = lines.toString().length;
    final style = _theme().body;
    final cached = _digits;
    if (cached != null &&
        cached.digits == digits &&
        cached.style == style &&
        cached.scaler == scaler) {
      return cached.width;
    }
    final width = lineNumbersWidth(lines, style, scaler);
    _digits = (digits: digits, style: style, scaler: scaler, width: width);
    return width;
  }
}
