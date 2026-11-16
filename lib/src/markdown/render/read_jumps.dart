/// The read view's moves to a place in the note: a block, an anchor, the
/// end — each landing where the height map says, and again after each
/// frame that measured what it landed among (#256, §8.4.3).
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/read_entries.dart';
import 'package:niman/src/markdown/render/scroll_anchor.dart';

/// Moves the read view's scroll to where [entries] place a part of the
/// note, and reads which part is at its top.
final class ReadJumps {
  /// Creates the moves over [entries], made with the controller [scroll]
  /// returns while [mounted] says the view is, below the inset [top]
  /// returns.
  new({
    required this.entries,
    required this.scroll,
    required this.mounted,
    required this.top,
  });

  /// The blocks the view shows, and the height map over them.
  final ReadEntries entries;

  /// The scroll the view is moved by, as of now.
  final ScrollController Function() scroll;

  /// Whether the view is still mounted: a pass a frame later is dropped
  /// when it is not.
  final bool Function() mounted;

  /// The inset above the content, as of now.
  final double Function() top;

  /// How many frames a line jump may take to settle.
  ///
  /// Each pass lands where the map says the target is, the frame that lands
  /// measures the blocks around it, and the target's own offset then moves by
  /// what those measurements were wrong by — a paragraph estimated at one
  /// visual line and drawn at three pushes it down, three times further than
  /// the map thought. That converges geometrically — every pass covers the
  /// ground the last one got wrong — and this bounds it. Measured on an anchor
  /// jump into a note of thirty-word paragraphs: three passes, and the last one
  /// moves nothing.
  static const int maxAttempts = 12;

  /// How many pointers are down on the view: a finger on the page, or a
  /// mouse button held on it.
  int _down = 0;

  /// Counts what the reader did to move the page: a drag that moved it, a
  /// wheel turned or a trackpad scrolled over it, a key that moves it.
  ///
  /// A move settles over the frames after it, and each pass jumps — which
  /// ends a drag or a fling under way, and pulls the page back from under
  /// a wheel. So a pass stops once the reader has moved the page since the
  /// move began: the reader's place is the reader's. A pointer put down and
  /// lifted without a drag is not a move: a tap that gives the view the
  /// keyboard, shows the chrome or follows a link leaves the page where it
  /// is.
  int _moves = 0;

  /// How many times the reader has moved the page so far: a mark to tell,
  /// later, whether they have since.
  int get moves => _moves;

  /// Counts the view's own moves started, and the reader's: a move still
  /// settling stops at the next pass once another has started since — a
  /// newer place asked for, or the reader's hand. Two settling at once
  /// moved the page every frame, each back to its own place (a voice
  /// reading a book asks for every block it speaks).
  int _epoch = 0;

  /// The mark a move's first pass takes, [since] when it is a later pass:
  /// null when a move started since, and the pass is to be dropped.
  int? _passOf(int? since) {
    if (since == null) return ++_epoch;
    return since == _epoch ? since : null;
  }

  /// A pointer went down on the view.
  void pointerDown() => _down++;

  /// A pointer down on the view went up, or was cancelled.
  void pointerUp() {
    if (_down > 0) _down--;
  }

  /// The reader moved the page: a drag moved it, a wheel or a trackpad
  /// scrolled it, a key moved it.
  void readerMoved() {
    _moves++;
    _epoch++;
  }

  /// Whether the reader is moving the page now: a pointer is down on it,
  /// or a fling it let go of is still running.
  bool get readerMoving {
    final controller = scroll();
    return _down > 0 ||
        (controller.hasClients &&
            controller.position.isScrollingNotifier.value);
  }

  /// Puts [anchor] back at the top as [toAnchor] does — unless the reader
  /// is moving the page, which the view then leaves where the reader takes
  /// it.
  void keep(ScrollAnchor anchor) {
    if (!readerMoving) toAnchor(anchor);
  }

  /// One pass of a line jump: jump to where the map says entry [index]
  /// starts, then look again after the frame that landed — unless the
  /// reader has moved the page, or another move has started, since the
  /// first pass, [since] by [_epoch].
  void toEntry(int index, {int attempt = 0, int? since}) {
    final heights = entries.heights;
    final controller = scroll();
    final pass = _passOf(since);
    if (heights == null || !controller.hasClients || pass == null) return;
    final offset = heights
        .offsetOf(index)
        .clamp(0.0, controller.position.maxScrollExtent);
    final moved = (controller.position.pixels - offset).abs() > 0.5;
    if (moved) {
      controller.jumpTo(offset);
    } else if (attempt > 0) {
      // The map agrees with where we are: nothing left to correct.
      return;
    }
    if (attempt >= maxAttempts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted()) return;
      toEntry(index, attempt: attempt + 1, since: pass);
    });
  }

  /// The source line at the top of the view, and how far into it: a
  /// block's lines share its height evenly, so a paragraph of one line is
  /// that line and a code block of forty is cut in forty. Null while there
  /// is nothing drawn to ask.
  ScrollAnchor? get topAnchor {
    final heights = entries.heights;
    final blocks = entries.blocks;
    final scroll = this.scroll();
    if (heights == null || blocks.isEmpty || !scroll.hasClients) return null;
    final y = scroll.offset - top();
    if (y <= 0) return (line: 0, fraction: 0.0);
    final index = heights.indexAt(y);
    if (index == null) {
      // Past the blocks, in the footnotes: the note's last line, whole.
      return (line: blocks.last.endLine - 1, fraction: 1.0);
    }
    final block = blocks[index];
    final extent = heights.extentFor(index);
    final lines = block.endLine - block.startLine;
    final into = extent > 0 ? (y - heights.offsetOf(index)) / extent : 0.0;
    final exact = into.clamp(0.0, 1.0) * lines;
    final line = exact.floor().clamp(0, lines - 1);
    return (line: block.startLine + line, fraction: exact - line);
  }

  /// Scrolls the view so [anchor]'s line is at its top, as far into it as
  /// the anchor says — and again after each frame that measured the blocks
  /// it landed among, as [toEntry] does.
  void toAnchor(ScrollAnchor anchor, {int attempt = 0, int? since}) {
    final heights = entries.heights;
    final scroll = this.scroll();
    final pass = _passOf(since);
    if (heights == null || !scroll.hasClients || pass == null) return;
    final found = entries.indexAt(anchor.line);
    if (found == null) return;
    final index = entries.hosts.entryOf(found);
    final block = entries.blocks[index];
    final lines = block.endLine - block.startLine;
    final into = index != found
        ? 0.0
        : lines > 0
        ? ((anchor.line - block.startLine) + anchor.fraction) / lines
        : 0.0;
    final atTop = anchor.line == 0 && anchor.fraction == 0;
    final offset = atTop
        ? 0.0
        : (top() + heights.offsetOf(index) + into * heights.extentFor(index))
              .clamp(0.0, scroll.position.maxScrollExtent);
    final moved = (scroll.position.pixels - offset).abs() > 0.5;
    if (moved) {
      scroll.jumpTo(offset);
    } else if (attempt > 0) {
      return;
    }
    if (attempt >= maxAttempts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted()) toAnchor(anchor, attempt: attempt + 1, since: pass);
    });
  }

  /// Goes to the note's end, and again after each frame that measured the
  /// rows it landed on and moved the end — as long as it moves, and
  /// neither the reader nor another move does.
  void toEnd({int attempt = 0, int? since}) {
    final scroll = this.scroll();
    final pass = _passOf(since);
    if (!scroll.hasClients || pass == null) return;
    final end = scroll.position.maxScrollExtent;
    if ((scroll.position.pixels - end).abs() <= 0.5 && attempt > 0) return;
    scroll.jumpTo(end);
    if (attempt >= maxAttempts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted()) toEnd(attempt: attempt + 1, since: pass);
    });
  }
}
