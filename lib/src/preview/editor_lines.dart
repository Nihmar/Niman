import 'package:flutter/foundation.dart';
import 'package:re_editor/re_editor.dart';

/// What the editor is showing, in source lines (T-M2-06).
///
/// re_editor publishes the paragraphs it has laid out — a source line
/// index and its offset from the top of the viewport — on every layout,
/// through the notifier it hands to its indicator builder. The note editor
/// attaches that notifier here and the scroll sync reads the visible lines
/// from it.
///
/// It has to: the editor's own `maxScrollExtent` is a running estimate.
/// Every line below the viewport counts as a single row, so the extent
/// grows as wrapped lines scroll into view, and `pixels / maxScrollExtent`
/// says nothing about which line is on screen — on a note whose paragraphs
/// wrap eight rows apiece it ran the preview a screenful ahead of the
/// editor (device report, 2026-09-10).
final class EditorLineView extends ChangeNotifier {
  /// Creates an empty view; [attach] connects it to an editor.
  new();

  ValueListenable<CodeIndicatorValue?>? _source;

  /// Listens to [source] (the editor's indicator notifier), replacing any
  /// previous one. Called from the editor's build, so it must never
  /// rebuild anything itself.
  void attach(ValueListenable<CodeIndicatorValue?> source) {
    if (identical(_source, source)) return;
    _source?.removeListener(notifyListeners);
    _source = source..addListener(notifyListeners);
  }

  /// The laid-out lines, top-first, with viewport-relative offsets.
  List<CodeLineRenderParagraph> get paragraphs =>
      _source?.value?.paragraphs ?? const <CodeLineRenderParagraph>[];

  /// Whether the editor has reported any line yet.
  bool get hasLines => paragraphs.isNotEmpty;

  /// The source line at the top of the viewport, or null before the first
  /// layout. A line scrolled halfway out still counts as the top one.
  int? topLine() {
    for (final paragraph in paragraphs) {
      if (paragraph.bottom > 0) return paragraph.index;
    }
    return paragraphs.isEmpty ? null : paragraphs.last.index;
  }

  /// How far [line]'s top sits from the top of the viewport (negative when
  /// it has scrolled past it), or null when the line is not laid out.
  double? offsetOf(int line) {
    for (final paragraph in paragraphs) {
      if (paragraph.index == line) return paragraph.top;
    }
    return null;
  }

  /// One unwrapped row's height, or null before the first layout.
  double? get rowHeight =>
      paragraphs.isEmpty ? null : paragraphs.first.preferredLineHeight;

  @override
  void dispose() {
    _source?.removeListener(notifyListeners);
    _source = null;
    super.dispose();
  }
}
