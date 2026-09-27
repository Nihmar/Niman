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
import 'package:niman/src/markdown/source_buffer.dart';

/// The list-item blocks a tick on [line] carries: the item on [line] and
/// every item nested under it, at any depth, in document order.
///
/// Empty when [line] does not start a list item — a box tapped in the
/// live editor or the read view is always on an item's first line.
List<Block> checklistBranch(List<Block> blocks, int line) {
  final index = _indexOfLine(blocks, line);
  if (index < 0) return const <Block>[];
  final parent = blocks[index];
  if (parent.kind != BlockKind.listItem || parent.startLine != line) {
    return const <Block>[];
  }
  final branch = <Block>[parent];
  for (var at = index + 1; at < blocks.length; at++) {
    final block = blocks[at];
    if (block.quoteDepth != parent.quoteDepth) break;
    // A continuation, a code block, a paragraph inside a child: not an
    // item, and not the end of the branch either.
    if (block.kind != BlockKind.listItem) continue;
    // The first item that is not deeper is a sibling or the next list:
    // the branch ends there.
    if (block.listDepth <= parent.listDepth) break;
    branch.add(block);
  }
  return branch;
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
  final branch = checklistBranch(blocks, line);
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
