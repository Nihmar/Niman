/// Carrying a checklist tick down a branch (#326): the list items a tick on
/// one line takes with it, and the edit that writes the whole branch at
/// once.
///
/// The nesting is the scanner's, not a guess from indentation: every line
/// knows its [Block.listDepth], so a checklist-looking line inside a fenced
/// code block is a code block and never a child, and a list that merely sits
/// under the parent's indent but belongs to another container ends the walk.
library;

import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The task items a tick on [line] carries: the item on [line] and every item
/// nested under it, at any depth, in document order.
///
/// Empty when [line] does not start a task item — a box tapped in the live
/// editor or the read view is always on an item's first line.
///
/// A list whose items are blocks of their own — a plain list, or a quoted head
/// with its indented children — is walked block by block. A quoted list is one
/// `quote` block however deep its items nest, so an item on any of its lines
/// has its branch read from the quote's own lines ([_quotedBranch]); the block
/// walk after the quote still catches the items that are blocks of their own,
/// when nothing in the quote ended the branch first.
List<Block> checklistBranch({
  required SourceBuffer buffer,
  required List<Block> blocks,
  required int line,
}) => _branch(buffer, blocks, line)?.items ?? const <Block>[];

/// The branch of the item on [line] among [blocks], and whether it is still
/// open where [blocks] end — no sibling, no shallower item, no other quote
/// level closed it — so that what follows the container they are read from
/// can still belong to it. Null when [line] does not start a task item.
({List<Block> items, bool open})? _branch(
  SourceBuffer buffer,
  List<Block> blocks,
  int line,
) {
  final index = _indexOfLine(blocks, line);
  if (index < 0) return null;
  final parent = blocks[index];
  final items = <Block>[];
  if (parent.kind == BlockKind.quote) {
    final quoted = _quotedBranch(buffer, parent, line);
    if (quoted == null) return null;
    items.addAll(quoted.items);
    if (!quoted.open) return (items: items, open: false);
  } else if (parent.kind == BlockKind.listItem && parent.startLine == line) {
    items.add(parent);
  } else {
    return null;
  }
  for (var at = index + 1; at < blocks.length; at++) {
    final block = blocks[at];
    if (block.quoteDepth != parent.quoteDepth) {
      return (items: items, open: false);
    }
    // A continuation, a code block, a paragraph inside a child: not an
    // item, and not the end of the branch either.
    if (block.kind != BlockKind.listItem) continue;
    // The first item that is not deeper is a sibling or the next list:
    // the branch ends there.
    if (block.listDepth <= parent.listDepth) {
      return (items: items, open: false);
    }
    items.add(block);
  }
  return (items: items, open: true);
}

/// The branch of the item on [line], a line of [quote], as blocks of the
/// note: the quote's own lines with their marks off, read again as a note —
/// the way the renderer reads a quote — and the branch taken from that
/// reading, a quote nested in it read through the same way.
({List<Block> items, bool open})? _quotedBranch(
  SourceBuffer buffer,
  Block quote,
  int line,
) {
  final content = <String>[
    for (var at = quote.startLine; at < quote.endLine; at++)
      buffer
          .lineAt(at)
          .substring(
            BlockParser.quotePrefixLength(
              buffer.lineAt(at),
              quote.quoteDepth,
              BlockParser.itemColumnOf(quote),
            ),
          ),
  ].join('\n');
  final inner = SourceBuffer.fromText(content);
  final branch = _branch(
    inner,
    BlockScanner(inner).index.blocks,
    line - quote.startLine,
  );
  if (branch == null || branch.items.isEmpty) return null;
  return (
    items: [
      for (final block in branch.items)
        Block(
          kind: block.kind,
          startLine: block.startLine + quote.startLine,
          endLine: block.endLine + quote.startLine,
          quoteDepth: quote.quoteDepth + block.quoteDepth,
          listDepth: block.listDepth,
          listOrdinal: block.listOrdinal,
        ),
    ],
    open: branch.open,
  );
}

/// The span of [buffer] that carries the tick of [line] down its branch,
/// and what it becomes: every task box in [checklistBranch] set to
/// [ticked], the item itself included.
///
/// One span, so the whole cascade is one edit and one undo step. Null when
/// [line] is not an item's first line or nothing in the branch changes.
({int start, int end, String text})? checklistTickEdit({
  required SourceBuffer buffer,
  required List<Block> blocks,
  required int line,
  required bool ticked,
}) {
  final branch = checklistBranch(buffer: buffer, blocks: blocks, line: line);
  if (branch.isEmpty) return null;
  final first = branch.first.startLine;
  final last = branch.last.endLine - 1;
  final start = buffer.offsetOfLine(first);
  final end = buffer.offsetOfLine(last) + buffer.lineLengthAt(last);
  final lines = buffer.substring(start, end).split('\n');
  var changed = false;
  for (final item in branch) {
    final at = item.startLine - first;
    if (at < 0 || at >= lines.length) continue;
    final box = taskBoxOffset(lines[at]);
    if (box == null) continue;
    final want = ticked ? 'x' : ' ';
    if (lines[at].codeUnitAt(box) == want.codeUnitAt(0)) continue;
    lines[at] = lines[at].replaceRange(box, box + 1, want);
    changed = true;
  }
  if (!changed) return null;
  return (start: start, end: end, text: lines.join('\n'));
}

/// The index of the block covering [line], by [Block.startLine] order.
int _indexOfLine(List<Block> blocks, int line) {
  var low = 0;
  var high = blocks.length - 1;
  while (low <= high) {
    final middle = (low + high) >> 1;
    final block = blocks[middle];
    if (line < block.startLine) {
      high = middle - 1;
    } else if (line >= block.endLine) {
      low = middle + 1;
    } else {
      return middle;
    }
  }
  return -1;
}
