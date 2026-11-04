/// A source line's gutter (split out of `source_line.dart` for #100): its
/// number, dimmed, and the fold arrow in the gap between the numbers and
/// the text — on a fenced div's band, as tall as the band.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/render/note_margins.dart';
import 'package:niman/src/markdown/render/source_line.dart';

/// The gap between the line numbers and the text ([lineNumbersGap]).
const double _gutterGap = lineNumbersGap;

/// The line's gutter.
extension SourceLineGutter on SourceLine {
  /// The gutter: the line's number, and the fold arrow in the gap between
  /// the numbers and the text, as in the legacy gutter.
  Widget lineGutter(BuildContext context) => SizedBox(
    width: gutterWidth,
    child: MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: number == null
                ? const SizedBox.shrink()
                : ValueListenableBuilder<CaretSpot>(
                    valueListenable: spot,
                    builder: (context, at, _) =>
                        _takesNoRoom(at) ||
                            (hideMarkers &&
                                fence != null &&
                                at.line != index &&
                                !fence!.numbered)
                        ? const SizedBox.shrink()
                        : _number()!,
                  ),
          ),
          SizedBox(width: _gutterGap, child: _foldArrow(context)),
        ],
      ),
    ),
  );

  /// [gutter], on a fence line's band (#729): as tall as the band, what it
  /// draws standing out of it — down from an opener, up from a closer —
  /// into the gutter beside the columns, which has no numbers of its own.
  Widget bandGutter(BuildContext context, Widget gutter) {
    final fence = this.fence;
    if (!hideMarkers || fence == null) return gutter;
    return ValueListenableBuilder<CaretSpot>(
      valueListenable: spot,
      builder: (context, at, child) => at.line == index
          ? child!
          : SizedBox(
              width: gutterWidth,
              height: MediaQuery.textScalerOf(context).scale(theme.divBand),
              child: OverflowBox(
                alignment: fence.numberUp
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                // As short as it is: a gutter of nothing is no height.
                minHeight: 0,
                maxHeight: double.infinity,
                child: child,
              ),
            ),
      child: gutter,
    );
  }

  /// Whether the line takes no room with the caret at [at]: a typeset
  /// formula's lines past its first (the formula is drawn under that one),
  /// definitions out of the caret's reach, a table's delimiter row. Its
  /// number takes none either, or the row would stay open around nothing.
  bool _takesNoRoom(CaretSpot at) {
    final math = formula;
    if (math != null &&
        mathCache != null &&
        (at.line < math.start || at.line >= math.end) &&
        index != math.start) {
      return true;
    }
    final drawing = diagram;
    if (drawing != null &&
        (at.line < drawing.start || at.line >= drawing.end) &&
        index != drawing.start) {
      return true;
    }
    final defined = definition;
    if (defined != null && (at.line < defined.$1 || at.line >= defined.$2)) {
      return true;
    }
    return tableRow?.call(at)?.delimiter ?? false;
  }

  /// The line's number, dimmed, or nothing.
  Widget? _number() => number == null
      ? null
      : Text(
          '$number',
          textAlign: TextAlign.right,
          // One row, whatever the measurement said: a number
          // that wraps makes its line two rows tall and every
          // number below it sits beside the wrong text.
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
          // The text's own face and size, dimmed: what the
          // legacy editor's `DefaultCodeLineNumber` does, so the
          // numbers line up with the characters they count
          // instead of drifting from them.
          style: theme.body.copyWith(color: theme.markerDim),
        );

  /// The fold arrow: pointing down over a section that can fold, right over
  /// one that is folded, nothing elsewhere.
  Widget? _foldArrow(BuildContext context) {
    if (fold == SourceFoldMark.none) return null;
    final row = MediaQuery.textScalerOf(context).scale(theme.lineHeight);
    return Listener(
      onPointerDown: (_) => onFoldDown(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: ValueKey<String>('fold-$index'),
          behavior: HitTestBehavior.opaque,
          onTap: onFold,
          child: SizedBox(
            height: row,
            child: Center(
              child: Icon(
                fold == SourceFoldMark.closed
                    ? Icons.chevron_right
                    : Icons.expand_more,
                size: foldArrowSize,
                color: theme.markerDim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
