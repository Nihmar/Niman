import 'package:flutter/material.dart';
import 'package:niman/src/ocr/ocr_placed_lines.dart';
import 'package:niman/src/ui/ocr/ocr_lines_scope.dart';

/// The recognized lines over page [pageNumber] of a scan (#596), placed at
/// [pageRect]'s scale from their boxes: each one a target, the selected
/// one tinted as the Text pane tints it. [onPick] gets the line tapped and
/// where. Nothing where the file has no text.
List<Widget> ocrLineOverlays(
  BuildContext context,
  Rect pageRect,
  int pageNumber, {
  required void Function(OcrPlacedLine line, Offset at) onPick,
}) {
  final scope = OcrLinesScope.maybeOf(context);
  if (scope == null) return const [];
  final size = pageRect.size;
  final selected = scope.selected;
  return [
    for (final line in scope.lines.lines)
      if (line.page == pageNumber)
        Positioned(
          left: line.box.left * size.width,
          top: line.box.top * size.height,
          width: (line.box.right - line.box.left) * size.width,
          height: (line.box.bottom - line.box.top) * size.height,
          child: _LineBox(
            key: Key('ocr-line-${line.sourceLine}'),
            selected: line == selected,
            onTapUp: (details) => onPick(line, details.globalPosition),
          ),
        ),
  ];
}

final class _LineBox extends StatelessWidget {
  const new({required this.selected, required this.onTapUp, super.key});

  final bool selected;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapUp,
        child: DecoratedBox(
          decoration: selected
              ? BoxDecoration(
                  color: accent.withValues(alpha: 0.25),
                  border: Border.all(color: accent, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                )
              : const BoxDecoration(),
        ),
      ),
    );
  }
}
