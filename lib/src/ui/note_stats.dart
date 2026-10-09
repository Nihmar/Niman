import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_frontmatter_head.dart';

/// An open note's statistics (T-M2-07): its word count, its outline and why
/// its frontmatter does not parse, refreshed a pause after the last edit.
///
/// Listeners hear of every refresh, whether or not a figure changed: the
/// note view repaints on it, as it did when the refresh was its own
/// `setState`. [outline] is also published on its own, for the panels
/// beside the note (#175).
final class NoteStatsController extends ChangeNotifier {
  /// Statistics of the note [surface] holds, while [loading] says it is not
  /// one being replaced; [sourceView] and [readView] are the panes whose
  /// scans the outline is read off, when they have one.
  new({
    required this.surface,
    required this.loading,
    required this.sourceView,
    required this.readView,
  });

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// Whether a note is being loaded: its statistics are not this one's.
  final bool Function() loading;

  /// The source pane's state, when it is built.
  final MarkdownSourceViewState? Function() sourceView;

  /// The read pane's state, when it is built.
  final MarkdownReadViewState? Function() readView;

  /// How long a note waits after the last edit before its word count and
  /// outline are refreshed, or null to wait for nothing (a test's).
  static Duration? delayOverride;

  /// The largest note worked out here and now rather than in the
  /// background: its word count adopted, its headings walked.
  static const int syncWorkLimit = 64 * 1024;

  /// The note's word count, as of the last refresh.
  int get wordCount => _wordCount;
  int _wordCount = 0;

  /// The note's headings, as of the last refresh.
  ValueListenable<List<OutlineEntry>> get outline => _outline;
  final ValueNotifier<List<OutlineEntry>> _outline = ValueNotifier(
    const <OutlineEntry>[],
  );

  /// Why the note's frontmatter block does not parse, or null when it does
  /// (or when there is no block).
  String? get frontmatterError => _frontmatterError;
  String? _frontmatterError;

  /// The note's revision the word count and the outline were last read at,
  /// or -1 before the first read. Comparing revisions is what says a note
  /// changed, where the statistics used to compare its whole text.
  int _revision = -1;

  Timer? _timer;
  bool _disposed = false;

  /// The note was edited: refreshed once the writer pauses.
  void schedule() {
    _timer?.cancel();
    _timer = Timer(_delay, refresh);
  }

  /// Refreshes the word count and the outline (T-M2-07).
  ///
  /// Neither reads the note any more, which is what this used to cost: the
  /// statistics joined the whole text (190 ms on the 246 MB note), compared
  /// it to the last one for equality, copied it to an isolate and walked it
  /// twice there (1.2 s). Now the count is kept by the edits
  /// ([MarkdownSurfaceController.words]) and the outline is read off the
  /// blocks the styling is already drawn from, so this is O(blocks) at
  /// worst — and the frontmatter check, which only ever wanted the leading
  /// block, gets the note's first lines rather than the whole note.
  void refresh() {
    if (_disposed || loading()) return;
    final surface = this.surface();
    if (surface != null) {
      // The surface counts its own words as it is edited. A note whose
      // count is not there yet (a big one, counted in the background) keeps
      // the count it has and takes the next refresh's.
      final revision = surface.revision;
      if (revision == _revision && surface.words.isCounted) return;
      final counted = surface.words.isCounted ? surface.words.words : null;
      final headings = _outlineNow(surface);
      // The pane's scan may still be carrying on an edit that changed the rest
      // of the note, and the outline is the whole note's: this revision is not
      // done until it lands, so the refresh asks again rather than keeping
      // the outline from before the edit for as long as nobody types.
      if (sourceView()?.scanSettled ?? true) {
        _revision = revision;
      } else {
        schedule();
      }
      final frontmatter = frontmatterErrorOf(surface.buffer);
      if (counted != null) _wordCount = counted;
      _frontmatterError = frontmatter;
      notifyListeners();
      if (headings != null) _outline.value = headings;
      // Nothing else asks again once the count lands: a note nobody types
      // in would keep showing none.
      if (!surface.words.isCounted) {
        unawaited(surface.buildWords().then((_) => _again(surface)));
      }
    }
  }

  /// Refreshes the statistics once [surface]'s count has landed, if it is
  /// still the note on screen.
  void _again(MarkdownSurfaceController surface) {
    if (_disposed || !identical(this.surface(), surface)) return;
    if (!surface.words.isCounted) return;
    _revision = -1;
    refresh();
  }

  /// The note's headings, from a scan something already paid for, or worked
  /// out here for a note small enough to walk now.
  ///
  /// The source pane's own reading of the blocks, the read pane's — scanned
  /// for the page — or the surface's, for a note whose pane is hidden or has
  /// not scanned yet. The first three cost nothing; the last is a scan over
  /// the note's text, which is why it is behind [syncWorkLimit] and nothing
  /// larger takes it.
  List<OutlineEntry>? _outlineNow(MarkdownSurfaceController surface) {
    final source = sourceView();
    if (source != null) {
      final headings = source.headings;
      if (headings != null) return headings;
    }
    final read = readView();
    if (read != null) {
      final headings = read.headings;
      if (headings != null) return headings;
    }
    final scanned = surface.headings;
    if (scanned != null) return scanned;
    // Nothing has scanned this note yet — a note just opened, or one whose
    // pane is off stage — and only a small one may be walked for its
    // headings here. A big one keeps the outline it has until a pane's own
    // scan lands ([refresh] asks again).
    if (surface.buffer.length > syncWorkLimit) return null;
    return outlineOfBlocks(
      BlockIndex(
        blocks: BlockScanner(surface.buffer).index.blocks,
        revision: surface.revision,
      ),
      surface.buffer.lineAt,
    );
  }

  /// How long the writer has to pause before the word count and the outline
  /// are worked out again.
  ///
  /// They read the whole note — joined, sent to an isolate, scanned — so a
  /// note of hundreds of megabytes waits for a real pause rather than for
  /// every breath between words (0.0.9 stress test: a 246 MB note paid 12 s
  /// of isolate time after each one).
  Duration get _delay {
    final override = delayOverride;
    if (override != null) return override;
    final length = surface()?.buffer.length ?? 0;
    if (length > 16 << 20) return const Duration(seconds: 5);
    if (length > 2 << 20) return const Duration(seconds: 2);
    return const Duration(milliseconds: 350);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _outline.dispose();
    super.dispose();
  }
}
