import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show ScrollController, TextPosition;
import 'package:re_editor/re_editor.dart';

/// What the editor is showing, in source lines (T-M2-06).
///
/// re_editor publishes the paragraphs it has laid out — a source line
/// index and its offset from the top of the viewport — on every layout,
/// through the notifier it hands to its indicator builder. The note editor
/// attaches that notifier here.
///
/// **This is not the scroll sync's file, and it outlives it.** The sync was
/// its first reader and the phase that removed the sync very nearly removed
/// this too, on the reasonable-sounding assumption that the two were one
/// thing; they are not. Its other reader is **typewriter mode**, which asks
/// `caretRowCenter` where the cursor's line is so it can put it in the middle
/// of the pane — and the reason the offsets are tracked *and corrected by the
/// scroll position* is that mode, not the sync: a scroll that lays nothing new
/// out only repaints, so the offsets re_editor published are then as far off
/// as the note has scrolled since. Deleting this file therefore means
/// reimplementing typewriter centring first, which is a piece of work of its
/// own rather than part of removing a pane.
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
    _source?.removeListener(_published);
    _source = source..addListener(_published);
  }

  /// Where that scroll stood when the lines were last published.
  double _publishedAt = 0;

  /// The editor's own vertical scroll, the lines' offsets are measured
  /// against, so [caretRowCenter] can say where a line is now.
  ///
  /// re_editor publishes the lines on layout, relative to the viewport,
  /// and a scroll that lays nothing new out only repaints: the offsets it
  /// published are then as far off as the note has scrolled since.
  ///
  /// Read only while it drives one view: as the editor is rebuilt it is
  /// briefly attached to two, and has no single offset to give.
  ScrollController? scroller;

  void _published() {
    final scroller = this.scroller;
    if (scroller != null && scroller.positions.length == 1) {
      _publishedAt = scroller.offset;
    }
    notifyListeners();
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

  /// How far the top line has scrolled past the top of the viewport, as a
  /// fraction of its own height (0 when it starts exactly there).
  ///
  /// A line of prose wraps over several rows, and the reader looking at the
  /// last of them is most of a paragraph further on than [topLine] alone
  /// says.
  double topOffset() {
    for (final paragraph in paragraphs) {
      if (paragraph.bottom > 0) {
        final height = paragraph.height;
        if (height <= 0) return 0;
        return (-paragraph.top / height).clamp(0.0, 1.0);
      }
    }
    return 0;
  }

  /// How far [line]'s top sits from the top of the viewport (negative when
  /// it has scrolled past it), or null when the line is not laid out.
  double? offsetOf(int line) {
    for (final paragraph in paragraphs) {
      if (paragraph.index == line) return paragraph.top;
    }
    return null;
  }

  /// How far the middle of the caret's row at [position] sits from the
  /// top of the viewport, or null when its line is not laid out.
  ///
  /// The row, not the line: a paragraph of prose wraps over several, and
  /// typewriter mode (#70) centres the one being written.
  double? caretRowCenter(CodeLinePosition position) {
    for (final paragraph in paragraphs) {
      if (paragraph.index != position.index) continue;
      final offset = paragraph.getOffset(
        TextPosition(offset: position.offset, affinity: position.affinity),
      );
      if (offset == null) return null;
      final scroller = this.scroller;
      final since = scroller != null && scroller.positions.length == 1
          ? scroller.offset - _publishedAt
          : 0.0;
      return paragraph.top +
          offset.dy +
          paragraph.preferredLineHeight / 2 -
          since;
    }
    return null;
  }

  /// One unwrapped row's height, or null before the first layout.
  double? get rowHeight =>
      paragraphs.isEmpty ? null : paragraphs.first.preferredLineHeight;

  @override
  void dispose() {
    _source?.removeListener(_published);
    _source = null;
    super.dispose();
  }
}
