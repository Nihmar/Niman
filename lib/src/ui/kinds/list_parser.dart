import 'package:copist/src/editor/highlighting.dart';

/// One task-list item parsed from a note's text.
final class ListItem {
  /// Creates an item.
  const ListItem({
    required this.line,
    required this.depth,
    required this.indent,
    required this.boxStart,
    required this.textStart,
    required this.checked,
    required this.text,
  });

  /// The 0-based index of the item's line in the note text (split on
  /// `\n`).
  final int line;

  /// The nesting level (0 = top); indentation defines nesting.
  final int depth;

  /// The item's leading spaces (its indentation in the file).
  final int indent;

  /// The offset of the task box's `[` within the line.
  final int boxStart;

  /// The offset within the line where the item text begins (after the
  /// box and the space following it).
  final int textStart;

  /// Whether the box is checked (`[x]`/`[X]`).
  final bool checked;

  /// The item text after the box (trimmed).
  final String text;
}

/// A drop zone of a list drag (T-TK-09): where the dragged item lands
/// relative to the target item.
enum ListDropMode {
  /// Before the target (the dragged item becomes its preceding sibling).
  before,

  /// After the target's subtree (the dragged item becomes its following
  /// sibling).
  after,

  /// Under the target (the dragged item becomes its first child).
  under,
}

/// The task-list items of [text], in document order.
///
/// An item is a line the editor tokenizer marks with a
/// [TokenKind.taskBox] — a list marker (`-`, `*`, `+`, or `N.`/`N)`)
/// followed by a `[ ]`/`[x]` box — so the list GUI and the editor agree
/// on what an item is, including that lines inside code fences, math
/// blocks and the frontmatter are not items. Everything else (prose,
/// headings, tables, code) is ignored: an item keeps only its line index,
/// so the parser never rewrites the note.
///
/// [ListItem.line] indexes [text] split on `\n` and [ListItem.boxStart]
/// indexes the line, so [flipListItem] can edit the text without
/// re-parsing it.
List<ListItem> parseListItems(String text) {
  final out = <ListItem>[];
  final doc = HighlightDocument.fromText(text);
  final indents = <int>[];
  for (var i = 0; i < doc.lines.length; i++) {
    final line = doc.lines[i];
    int? box;
    for (final token in line.tokens) {
      if (token.kind == TokenKind.taskBox) {
        box = token.start;
        break;
      }
    }
    if (box == null) continue;
    final text0 = line.text;
    var indent = 0;
    while (indent < text0.length && _isSpace(text0.codeUnitAt(indent))) {
      indent++;
    }
    // Nesting: the item's ancestors are the previous items with strictly
    // smaller indent, in document order.
    while (indents.isNotEmpty && indents.last >= indent) {
      indents.removeLast();
    }
    final depth = indents.length;
    indents.add(indent);
    var from = box + 3;
    if (from < text0.length && _isSpace(text0.codeUnitAt(from))) from++;
    out.add(
      ListItem(
        line: i,
        depth: depth,
        indent: indent,
        boxStart: box,
        textStart: from,
        checked: text0.codeUnitAt(box + 1) != 0x20,
        text: text0.substring(from).trim(),
      ),
    );
  }
  return out;
}

/// The number of content lines of [text]: the phantom line a trailing
/// newline produces in `text.split('\n')` is not a line.
int listLineCount(String text) {
  final lines = text.split('\n');
  return lines.last.isEmpty ? lines.length - 1 : lines.length;
}

/// The exclusive end line of the item at [index]'s subtree: the item plus
/// every line up to (not including) the next item with a smaller or equal
/// indent — prose lines in between belong to the subtree.
int subtreeEnd(List<ListItem> items, int index, int lineCount) {
  final item = items[index];
  for (var i = index + 1; i < items.length; i++) {
    if (items[i].indent <= item.indent) return items[i].line;
  }
  return lineCount;
}

/// Resolves a drop of the item at [index] onto the item at [target] in
/// [mode] to the [moveSubtree] coordinates, or null when the drop changes
/// nothing (the target is the dragged item or one of its own children).
///
/// A [target] of `-1` is the zone above the list (the item becomes the
/// first root item); the item count is the zone below it (last root
/// item).
({int insertLine, int indent})? resolveListDrop(
  List<ListItem> items,
  int index,
  int target,
  ListDropMode mode,
  int lineCount,
) {
  if (target == -1) {
    return items.isEmpty
        ? null
        : (insertLine: items.first.line, indent: 0);
  }
  if (target == items.length) {
    return items.isEmpty
        ? null
        : (insertLine: subtreeEnd(items, items.length - 1, lineCount),
          indent: 0);
  }
  if (target == index) return null;
  final end = subtreeEnd(items, index, lineCount);
  if (items[target].line > items[index].line && items[target].line < end) {
    // Dropping onto one of its own children: the whole block would land
    // on itself.
    return null;
  }
  switch (mode) {
    case ListDropMode.before:
      return (insertLine: items[target].line, indent: items[target].indent);
    case ListDropMode.after:
      return (
        insertLine: subtreeEnd(items, target, lineCount),
        indent: items[target].indent,
      );
    case ListDropMode.under:
      return (
        insertLine: items[target].line + 1,
        indent: items[target].indent + 2,
      );
  }
}

/// The note text with the item at [index]'s whole subtree (item plus
/// children and the prose between them) moved to before line [insertLine]
/// (in [text]'s original coordinates) and re-indented to [indent]
/// leading spaces. Every other line keeps its bytes; the moved lines keep
/// their bytes apart from the leading spaces (the delta is applied to
/// the whole subtree, clamped at zero).
String moveSubtree(
  String text,
  List<ListItem> items,
  int index, {
  required int insertLine,
  required int indent,
}) {
  final lines = text.split('\n');
  final item = items[index];
  final end = subtreeEnd(items, index, listLineCount(text));
  if (insertLine > item.line && insertLine < end) return text;
  final moved = lines.sublist(item.line, end);
  final delta = indent - item.indent;
  if (delta > 0) {
    for (var i = 0; i < moved.length; i++) {
      moved[i] = '${' ' * delta}${moved[i]}';
    }
  } else if (delta < 0) {
    for (var i = 0; i < moved.length; i++) {
      moved[i] = _dedent(moved[i], -delta);
    }
  }
  final rest = [
    ...lines.sublist(0, item.line),
    ...lines.sublist(end, lines.length),
  ];
  final at = insertLine > item.line
      ? insertLine - (end - item.line)
      : insertLine;
  rest.insertAll(at, moved);
  return rest.join('\n');
}

/// The note text with [item]'s text replaced by [newText] (everything
/// else, frontmatter included, keeps its bytes).
String editItemText(String text, ListItem item, String newText) {
  final lines = text.split('\n');
  final line = lines[item.line];
  lines[item.line] = '${line.substring(0, item.textStart)}$newText';
  return lines.join('\n');
}

String _dedent(String line, int n) {
  var i = 0;
  while (i < line.length && i < n && line.codeUnitAt(i) == 0x20) {
    i++;
  }
  return line.substring(i);
}

/// Flips [item]'s task box in [text] (the text [parseListItems] parsed).
///
/// Byte-stable: only the box character changes (` ` to `x` or back);
/// every other byte of the note is untouched, so prose, code and
/// frontmatter are never rewritten.
String flipListItem(String text, ListItem item) {
  final lines = text.split('\n');
  final line = lines[item.line];
  final at = item.boxStart + 1;
  lines[item.line] = line.replaceRange(
    at,
    at + 1,
    line.codeUnitAt(at) == 0x20 ? 'x' : ' ',
  );
  return lines.join('\n');
}

/// Appends `- [ ] <item>` as a new line at the end of [text] (byte-stable
/// otherwise).
String appendListItem(String text, String item) {
  final prefix = text.isEmpty || text.endsWith('\n') ? text : '$text\n';
  return '$prefix- [ ] $item\n';
}

bool _isSpace(int c) => c == 0x20 || c == 0x09;
