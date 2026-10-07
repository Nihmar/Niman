import 'package:flutter/widgets.dart';
import 'package:niman/src/ocr/ocr_placed_lines.dart';

/// A scan's recognized lines and the one selected (#596), shared by the
/// scan, which draws and selects them, and the Text pane, which marks the
/// selected one.
final class OcrLinesScope
    extends InheritedNotifier<ValueNotifier<OcrPlacedLine?>> {
  /// The [lines] of the file's text, [selected] among them.
  const new({
    required this.lines,
    required ValueNotifier<OcrPlacedLine?> selected,
    required super.child,
    super.key,
  }) : super(notifier: selected);

  /// The lines with their places, and the pages that lost some.
  final OcrPlacedLines lines;

  /// The line selected, or null.
  OcrPlacedLine? get selected => notifier?.value;

  /// Selects a line (null clears it).
  set selected(OcrPlacedLine? line) => notifier?.value = line;

  /// The scope above [context], or null where the file has no text.
  static OcrLinesScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OcrLinesScope>();

  @override
  bool updateShouldNotify(OcrLinesScope oldWidget) =>
      super.updateShouldNotify(oldWidget) || lines != oldWidget.lines;
}
