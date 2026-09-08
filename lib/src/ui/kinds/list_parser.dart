import 'package:copist/src/editor/highlighting.dart';

/// One task-list item parsed from a note's text.
final class ListItem {
  /// Creates an item.
  const ListItem({
    required this.line,
    required this.depth,
    required this.boxStart,
    required this.checked,
    required this.text,
  });

  /// The 0-based index of the item's line in the note text (split on
  /// `\n`).
  final int line;

  /// The nesting level (0 = top); indentation defines nesting.
  final int depth;

  /// The offset of the task box's `[` within the line.
  final int boxStart;

  /// Whether the box is checked (`[x]`/`[X]`).
  final bool checked;

  /// The item text after the box (trimmed).
  final String text;
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
        boxStart: box,
        checked: text0.codeUnitAt(box + 1) != 0x20,
        text: text0.substring(from).trim(),
      ),
    );
  }
  return out;
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
