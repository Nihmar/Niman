/// What the read pane draws of the note on the editor surface: a snapshot of
/// the editor's buffer, taken once per revision shown (issue #100 moved it
/// out of `note_view.dart`).
library;

import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The read pane's buffer, and which of the editor's revisions it is.
final class NoteReadSnapshot {
  /// The unified engine's buffer, rebuilt only when the text changes.
  ///
  /// A `SourceBuffer` is a line array with a prefix index: building one per
  /// frame would cost 1.2 ms of `text` and a 7 ms scan on a 930 KB note, which
  /// is exactly what the windowed read view exists to avoid. The preview
  /// refreshes on a 500 ms debounce, so this is rebuilt at that cadence.
  SourceBuffer? _unifiedBuffer;

  /// The editor's buffer and its revision the read pane should show, while
  /// the source pane is the unified surface: the pane is given a snapshot of
  /// that buffer's lines ([SourceBuffer.snapshot]) rather than a buffer read
  /// again from the note's joined text.
  SourceBuffer? _previewOf;
  int _previewRevision = -1;

  /// Whether [_unifiedBuffer] is such a snapshot, and of which revision.
  bool _bufferIsSnapshot = false;
  SourceBuffer? _snapshotFrom;
  int _snapshotRevision = -1;

  /// Whether the preview's text is behind the note because the preview was
  /// not on screen when the note changed.
  bool stale = false;

  /// Lets go of the note that went: the read pane shows nothing of it.
  void clear() {
    _unifiedBuffer = null;
    _bufferIsSnapshot = false;
    _snapshotFrom = null;
    _previewOf = null;
  }

  /// The read pane is to show [live], the editor's buffer, at its revision
  /// now; null shows an empty page.
  void show(SourceBuffer? live) {
    _previewOf = live;
    _previewRevision = live?.revision ?? -1;
  }

  /// Whether the read pane already shows [live] at its revision now: the
  /// editor's own lines, by revision — no text joined, no text compared.
  bool shows(SourceBuffer live) =>
      identical(live, _previewOf) && live.revision == _previewRevision;

  /// The buffer the unified engine draws, built once per text change.
  SourceBuffer get buffer {
    final live = _previewOf;
    if (live != null) {
      if (_unifiedBuffer == null ||
          !_bufferIsSnapshot ||
          !identical(_snapshotFrom, live) ||
          _snapshotRevision != _previewRevision) {
        _unifiedBuffer = live.snapshot();
        _bufferIsSnapshot = true;
        _snapshotFrom = live;
        _snapshotRevision = _previewRevision;
      }
      return _unifiedBuffer!;
    }
    // No note yet: an empty page.
    if (_unifiedBuffer == null || _bufferIsSnapshot) {
      _unifiedBuffer = SourceBuffer.fromText('');
      _bufferIsSnapshot = false;
    }
    return _unifiedBuffer!;
  }

  /// [editor], when the read pane shows it as it is — the snapshot is of
  /// that buffer at its revision now — or null: a line number of an older
  /// snapshot is not this note's.
  SourceBuffer? current(SourceBuffer editor) {
    final from = _snapshotFrom;
    if (from == null ||
        !identical(from, editor) ||
        from.revision != _snapshotRevision) {
      return null;
    }
    return from;
  }

  /// The blocks and definitions of [buffer] as the source pane — [editor] —
  /// already holds them, when [buffer] is the snapshot of its note at the
  /// revision the pane has read — or null, and the read pane scans for itself.
  ///
  /// One reading of the note for both panes: the editor keeps its own current
  /// edit by edit, and scanning the snapshot again was 3.3 s in an isolate on
  /// a 246 MB note, after holding the frame that opened the pane to hand the
  /// note over.
  DocumentScan? editorScanOf(
    SourceBuffer buffer,
    MarkdownSourceViewState? editor,
  ) {
    final from = _snapshotFrom;
    if (!_bufferIsSnapshot ||
        !identical(buffer, _unifiedBuffer) ||
        from == null ||
        from.revision != _snapshotRevision) {
      return null;
    }
    if (editor == null || !identical(editor.widget.buffer, from)) return null;
    final scan = editor.handOver();
    if (scan == null || scan.revision != from.revision) return null;
    // The same lines, in a buffer of their own: the definitions are read
    // against it from now on.
    return DocumentScan(
      blocks: scan.blocks,
      scope: scan.scope.on(buffer, buffer.revision),
      revision: buffer.revision,
      changes: scan.changes,
    );
  }
}
