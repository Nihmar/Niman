/// The checkbox items of a note that Move to tasks can turn into tasks
/// (#1152).
///
/// An item is found the way the editor knows a list item: off the block scan,
/// so a `- [ ]` line inside a fenced or indented code block, a front matter
/// or an HTML block is code and never an item, and an item's continuation
/// lines are part of it. Only the box and the marker are read off the item's
/// first line ([listItemHead], [taskBoxOffset]) — the one place the scan
/// does not already say.
///
/// Items inside a blockquote are left alone: lifting a line out of a quote
/// would leave the quote's marks behind.
library;

import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// One checkbox item: the lines it takes up, its box and its words.
final class TaskItem {
  /// An item of lines `[line, endLine)` saying [text].
  const new({
    required this.line,
    required this.endLine,
    required this.checked,
    required this.text,
    required this.raw,
    required this.hasSubItems,
  });

  /// Its first line.
  final int line;

  /// One past its last line.
  final int endLine;

  /// Whether its box is ticked.
  final bool checked;

  /// What it says, as written: the words after the marker and the box, then
  /// its continuation lines, on one line.
  final String text;

  /// Its lines as the note has them, for telling later whether the note
  /// still holds the item where it was.
  final List<String> raw;

  /// Whether items nest under it, or it holds more than its own lines (a
  /// paragraph, a code block): it is not moved while it does.
  final bool hasSubItems;

  /// Whether the item can be moved: it has words, and nothing under it.
  bool get movable => !hasSubItems && text.isNotEmpty;
}

/// The checkbox items among lines `[first, last]` of [buffer]: every item
/// whose lines the range touches, in order.
///
/// [blockAt] is the block holding a line, from the scan the caller already
/// keeps; without one the note is scanned as far as [last] and the item
/// after it. Reads the range's blocks and the one block after each item,
/// never the note. With [untilMovable], the first item that can be moved
/// ends the walk: what a menu asks before it offers the command.
List<TaskItem> taskItemsIn({
  required SourceBuffer buffer,
  required int first,
  required int last,
  Block? Function(int line)? blockAt,
  bool untilMovable = false,
}) {
  final blockOf = blockAt ?? BlockScanner(buffer).blockAt;
  final items = <TaskItem>[];
  var line = first < 0 ? 0 : first;
  final end = last >= buffer.lineCount ? buffer.lineCount - 1 : last;
  while (line <= end) {
    final block = blockOf(line);
    if (block == null) break;
    final item = _itemOf(buffer, block, blockOf);
    if (item != null) items.add(item);
    if (untilMovable && (item?.movable ?? false)) break;
    line = block.endLine;
  }
  return items;
}

/// What Move to tasks can do with the items under the selection.
enum MoveAvailability {
  /// No checkbox item with words is there.
  none,

  /// Items are there, and each one has sub-items.
  blocked,

  /// At least one item can be moved.
  ready;

  /// The availability [items] make.
  static MoveAvailability of(List<TaskItem> items) {
    if (items.any((item) => item.movable)) return ready;
    return items.any((item) => item.hasSubItems) ? blocked : none;
  }
}

/// The item [block] is, or null when it is not a checkbox item.
TaskItem? _itemOf(
  SourceBuffer buffer,
  Block block,
  Block? Function(int line) blockOf,
) {
  if (block.kind != BlockKind.listItem || block.quoteDepth != 0) return null;
  final first = buffer.lineAt(block.startLine);
  final box = taskBoxOffset(first);
  final head = listItemHead(first);
  if (box == null || head == null || !head.box) return null;
  final words = <String>[
    head.content,
    for (var at = block.startLine + 1; at < block.endLine; at++)
      buffer.lineAt(at),
  ];
  return TaskItem(
    line: block.startLine,
    endLine: block.endLine,
    checked: first.codeUnitAt(box) != 0x20,
    text: oneLine(words.join(' ')),
    raw: [
      for (var at = block.startLine; at < block.endLine; at++)
        buffer.lineAt(at),
    ],
    hasSubItems: _holdsMore(block, blockOf),
  );
}

/// Whether what follows [item] belongs to it: an item nested deeper, or a
/// paragraph or a code block it holds (the scan gives those the item's own
/// list depth; the text after the list has none), past any blank lines.
bool _holdsMore(Block item, Block? Function(int line) blockOf) {
  for (var next = blockOf(item.endLine); next != null;) {
    if (next.kind != BlockKind.blank) {
      if (next.quoteDepth != 0 || next.listDepth < 0) return false;
      return next.kind != BlockKind.listItem || next.listDepth > item.listDepth;
    }
    next = blockOf(next.endLine);
  }
  return false;
}

/// [text] on one line: its runs of white space collapsed to one space, the
/// ends trimmed (a task is one line of `todo.txt`).
String oneLine(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
