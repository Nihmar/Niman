/// Blocks built line by line, as the block scan reaches each line.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_rules.dart';

/// Blocks built line by line, as a scan reaches each line.
///
/// A block is a run of lines: the first line says what it is, and each line
/// after it either goes on with it or starts the next one. Built as the scan
/// goes rather than after it, so the scan can ask at any line which block is
/// open — which is what deciding that it has converged needs.
final class BlockBuilder {
  /// A builder reading lines by [_rules], with [open] taken open — the
  /// block a rescan resumes — and [_before] the last non-blank block
  /// before the first line it is given.
  new(this._rules, {Block? open, this._before})
    : _open = open,
      openEnd = open?.endLine ?? 0,
      openHoldsFence = open?.holdsFence ?? false;

  final BlockRules _rules;
  final List<Block> _blocks = <Block>[];

  /// The block the next line may go on with. Its own end is not kept up:
  /// the run is [openEnd], and the block is cut there when it closes — a
  /// block a line would be an allocation per line of the note.
  Block? _open;

  /// Where the open block runs to: one past the last line added to it, or
  /// wherever the scan found the old block it turned out to be ending.
  int openEnd;

  /// Whether a line of the open quote block opens a fenced div (#1048), the
  /// lines the scan has not read again — the old block it converged on —
  /// counting by what that block said.
  bool openHoldsFence;

  /// The last non-blank block before the ones built here.
  final Block? _before;

  /// The block the next line may go on with (its end is not its end).
  Block? get open => _open;

  /// The last non-blank block before the next line: what an item starting
  /// there would count on from. An empty footnote definition is blank, and
  /// still one: the list after it is another.
  Block? get previous {
    final open = _open;
    if (open != null && _counts(open)) return open;
    for (var at = _blocks.length - 1; at >= 0; at--) {
      if (_counts(_blocks[at])) return _blocks[at];
    }
    return _before;
  }

  static bool _counts(Block block) =>
      block.kind != BlockKind.blank || block.footnote == Block.opensFootnote;

  /// Adds [line], whose entering state is recorded.
  void add(int line) {
    final open = _open;
    if (open != null) {
      // A paragraph — or an item's first paragraph — that takes its
      // underline is a setext heading from its first line on, and ends there.
      final level =
          open.kind == BlockKind.paragraph || open.kind == BlockKind.listItem
          ? _rules.underlineLevel(open, line)
          : 0;
      if (level > 0) headOpen(level);
      if (level > 0 || _rules.mergesInto(open, line)) {
        openEnd = line + 1;
        if (open.kind == BlockKind.quote &&
            !openHoldsFence &&
            _rules.quoteLineHoldsFence(line)) {
          openHoldsFence = true;
        }
        return;
      }
    }
    final before = previous;
    _close();
    final started = _rules.blockStarting(line, before);
    _open = started;
    openEnd = line + 1;
    openHoldsFence =
        started.kind == BlockKind.quote && _rules.quoteLineHoldsFence(line);
  }

  /// Makes the open paragraph the setext heading of [level] its underline
  /// makes it.
  void headOpen(int level) {
    _open = _open!.headed(level);
  }

  /// The blocks built, the open one closed.
  List<Block> finish() {
    _close();
    return _blocks;
  }

  void _close() {
    final open = _open;
    if (open == null) return;
    var block = open.endLine == openEnd ? open : open.cutAt(openEnd);
    if (openHoldsFence && !block.holdsFence) block = block.withFence();
    _blocks.add(block);
    _open = null;
    openHoldsFence = false;
  }
}
