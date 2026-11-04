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

  /// One pass of a line jump: jump to where the map says entry [index]
  /// starts, then look again after the frame that landed.
  void toEntry(int index, {int attempt = 0}) {
    final heights = entries.heights;
    final controller = scroll();
    if (heights == null || !controller.hasClients) return;
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
      toEntry(index, attempt: attempt + 1);
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
  void toAnchor(ScrollAnchor anchor, {int attempt = 0}) {
    final heights = entries.heights;
    final scroll = this.scroll();
    if (heights == null || !scroll.hasClients) return;
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
      if (mounted()) toAnchor(anchor, attempt: attempt + 1);
    });
  }

  /// Goes to the note's end, and again after each frame that measured the
  /// rows it landed on and moved the end — as long as it moves.
  void toEnd({int attempt = 0}) {
    final scroll = this.scroll();
    if (!scroll.hasClients) return;
    final end = scroll.position.maxScrollExtent;
    if ((scroll.position.pixels - end).abs() <= 0.5 && attempt > 0) return;
    scroll.jumpTo(end);
    if (attempt >= maxAttempts) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted()) toEnd(attempt: attempt + 1);
    });
  }
}
