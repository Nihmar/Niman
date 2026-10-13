/// The block anchors of the note being edited (#844), read off its buffer.
///
/// A note's headings come from the scan its panes already paid for. A block's
/// ` ^id` is not in that scan, so a link followed to a block — or a `[[#^`
/// being typed — asks for the ids here: one walk over the buffer's lines,
/// kept for the revision it was made at, and paused for the event loop every
/// so many lines on a note too long to walk in one frame.
library;

import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The block anchors of one [SourceBuffer], by revision.
final class BufferBlockAnchors {
  /// Reads the anchors of [_buffer] when asked.
  new(this._buffer);

  final SourceBuffer Function() _buffer;

  int _revision = -1;
  SourceBuffer? _of;
  Future<List<BlockAnchor>>? _anchors;

  /// A note longer than this (characters) is walked in slices, yielding to
  /// the event loop between them.
  static const int sliceAbove = 64 * 1024;

  /// How many lines a slice walks before it yields.
  static const int sliceLines = 20000;

  /// The note's anchors, in line order: the answer kept for the revision it
  /// was made at, or a walk begun now.
  Future<List<BlockAnchor>> read() {
    final buffer = _buffer();
    final kept = _anchors;
    if (kept != null &&
        identical(_of, buffer) &&
        _revision == buffer.revision) {
      return kept;
    }
    final revision = buffer.revision;
    _of = buffer;
    _revision = revision;
    final walk = blockAnchorsOfLines(
      buffer.lineCount,
      // The note may change under a walk that pauses: a line that is gone
      // reads as blank, and the answer is not kept past the revision.
      (line) => line < buffer.lineCount ? buffer.lineAt(line) : '',
      yieldEvery: buffer.length > sliceAbove ? sliceLines : null,
    );
    _anchors = walk;
    return walk.then((anchors) {
      if (buffer.revision != revision && identical(_anchors, walk)) {
        _anchors = null;
      }
      return anchors;
    });
  }
}
