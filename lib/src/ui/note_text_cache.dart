/// The note's text as the editor surface has it, joined once per revision
/// (issue #100 moved it out of `note_view.dart`).
library;

import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The note's text as the unified source surface has it, which is where
/// saving, the preview and the statistics all get their text from — so
/// this pane reaches every one of them through one door.
///
/// Joined from the surface's buffer when it is asked for, once per revision:
/// the surface reports an edit without its text, because joining the note on
/// every keystroke is O(n) for a text only the save debounce needs.
///
/// A long note's join is not kept (#1197). The text it was read from stays
/// alive anyway — every line not yet written is a view of it — so a kept
/// join was a second whole copy of the note, 247 MB of the stress note,
/// held until the next keystroke. A long note is the one the editor scans
/// in the background ([MarkdownSourceViewState.readsInBackground]), whose
/// panels read what the scan keeps rather than the text; what still asks for
/// the whole note (a kind's edit, a comparison with the disk) joins it for
/// that call alone. A short one keeps its join: a kind's view asks for it
/// on every build.
final class NoteTextCache {
  /// The text of the buffer [buffer] answers, the editor surface's.
  new(this.buffer);

  /// The buffer the unified source surface edits, or null before one is
  /// built.
  final SourceBuffer? Function() buffer;

  String _cache = '';
  SourceBuffer? _buffer;
  int _revision = -1;

  /// The note's text: the buffer's, joined once per revision, or the text
  /// last seeded while there is no buffer.
  String get text {
    final buffer = this.buffer();
    if (buffer == null) return _cache;
    if (identical(buffer, _buffer) && buffer.revision == _revision) {
      return _cache;
    }
    final text = buffer.text;
    if (MarkdownSourceViewState.readsInBackground(buffer)) {
      // The text the note was loaded from, which the seed kept, is let go
      // with the rest: the lines still reading it keep it, and no more.
      _cache = '';
      _buffer = null;
      _revision = -1;
      return text;
    }
    _cache = text;
    _buffer = buffer;
    _revision = buffer.revision;
    return text;
  }

  /// Seeds [text] with the text [buffer] was read from.
  set text(String text) {
    final buffer = this.buffer();
    _cache = text;
    _buffer = buffer;
    _revision = buffer?.revision ?? -1;
  }

  /// The first [maxChars] units of [text], read from the buffer's own lines:
  /// O(the head), not O(the note).
  String head(int maxChars) {
    final buffer = this.buffer();
    if (buffer == null) {
      final text = _cache;
      return text.length <= maxChars ? text : text.substring(0, maxChars);
    }
    return buffer.substring(
      0,
      buffer.length < maxChars ? buffer.length : maxChars,
    );
  }
}
