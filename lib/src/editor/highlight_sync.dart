import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/editor/line_buffer.dart';

/// Incremental highlight over a [LineBuffer]: keeps a [HighlightDocument] in
/// sync with the buffer's text, re-tokenizing only the edited lines.
///
/// This is what keeps highlighting within the "no per-frame re-tokenize of
/// the whole file" budget (M2a E7): [sync] is called once per buffer edit and
/// applies that edit via [HighlightDocument.replace] (O(edited lines)), never
/// re-tokenizing per frame. Only when several edits accumulate between syncs
/// (or on the first sync) does it fall back to a full rebuild from the buffer's
/// text. Selection-only changes (no buffer edit) are a no-op.
final class Highlighter {
  HighlightDocument? _doc;
  int _seenEdits = 0;

  /// The current document, or null until the first [sync].
  HighlightDocument? get document => _doc;

  /// Re-syncs from [buffer]. No-op when the buffer has no new edit since the
  /// last sync.
  void sync(LineBuffer buffer) {
    final edits = buffer.editCount;
    final doc = _doc;
    if (doc != null) {
      if (edits == _seenEdits) return; // selection-only change, doc is current
      if (edits == _seenEdits + 1) {
        // Exactly one new edit since the last sync → apply it incrementally.
        final edit = buffer.lastEdit!;
        doc.replace(edit.start, edit.end, edit.text);
        _seenEdits = edits;
        return;
      }
    }
    // First sync, or more than one edit since the last sync → rebuild.
    _doc = HighlightDocument.fromText(buffer.text);
    _seenEdits = edits;
  }
}
