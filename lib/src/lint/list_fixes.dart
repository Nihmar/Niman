/// The list rules of the Markdown corrector (#72).
///
/// A list is the one construct whose *shape* — where the text starts, which
/// lines are the same item — depends on whitespace the writer cannot see.
/// These are the rules that settle it: one space after the marker, the
/// item's own lines following that, and no blank lines between items.
library;

/// `- `, `* `, `+ `, `1. `, `1) ` — a list item's marker, with the indent
/// it sits at and the whitespace after it.
final RegExp listMarker = RegExp(r'^(\s*)([-*+]|\d{1,9}[.)])([ \t]+)');

/// `[ ]`, `[x]`, `[X]`, `[x ]`, `[]` right after an item's marker: a task
/// box, however it was spelled, and the spaces after it.
///
/// Not when a `(`, a `[` or a `:` follows the bracket: then it is a link's
/// text — `[](url)`, `[x][ref]` — or a reference's label (`[x]: url`), and
/// spacing it out as a box would break the link.
final RegExp _taskBox = RegExp(
  r'^(\s*(?:[-*+]|\d{1,9}[.)]))([ \t]+)\[([ xX]*)\](?![(\[:])[ \t]*',
);

/// A list block's lines, tidied.
///
/// Every item keeps its marker and its own indent; the marker is followed
/// by exactly one space ([spacing]); a line that continues an item is
/// indented to that item's text, so a wrapped item stays one item
/// (#227); and — with [tight] — the blank lines between items go, deep
/// sublists included, so a list written loose comes back tight (#72).
///
/// A blank line whose next content is not another item is kept: it is an
/// item's own second paragraph, and joining it to the first would rewrite
/// what the item says.
List<String> tidyList(
  List<String> lines, {
  required bool spacing,
  required bool tight,
}) {
  final out = <String>[];
  // The open items, innermost last: the text column each item's marker
  // left, and the column it leaves once the padding is one space.
  final open = <({int was, int now})>[];
  for (var at = 0; at < lines.length; at++) {
    final raw = lines[at];
    if (raw.trim().isEmpty) {
      if (tight && _blankJoinsItem(lines, at)) continue;
      out.add('');
      continue;
    }
    final marker = listMarker.firstMatch(raw);
    if (marker != null) {
      final indent = marker.group(1)!.length;
      final mark = marker.group(2)!;
      final gap = marker.group(3)!;
      while (open.isNotEmpty && indent < open.last.was) {
        open.removeLast();
      }
      final shift = open.isEmpty ? 0 : open.last.now - open.last.was;
      final column = indent + shift;
      final rest = raw.substring(marker.end);
      // Five columns or more after the marker are one space and then an
      // indented code block (CommonMark 5.2): the item's text starts one
      // column in, and the rest of the gap is the code's own indent, which
      // one space would turn into a paragraph.
      final code = _startsCode(gap, from: indent + mark.length);
      // The gap is kept as written when it holds code, or when the rule
      // is off; otherwise it becomes the one space.
      final asWritten = code || !spacing;
      final textAt = code ? 1 : gap.length;
      out.add(
        rest.isEmpty
            ? '${' ' * column}$mark'
            : '${' ' * column}$mark${asWritten ? gap : ' '}$rest',
      );
      open.add((
        was: indent + mark.length + textAt,
        now: column + mark.length + (asWritten ? textAt : 1),
      ));
      continue;
    }
    if (open.isEmpty) {
      out.add(raw);
      continue;
    }
    // A line that continues an item: to the item's text column, its own
    // extra indent — a nested block's — kept.
    final indent = raw.length - raw.trimLeft().length;
    final item = open.last;
    final column = indent >= item.was
        ? indent + (item.now - item.was)
        : item.now;
    out.add('${' ' * column}${raw.trimLeft()}');
  }
  return out;
}

/// Whether [gap], the whitespace after a marker ending at column [from],
/// spans five columns or more: then the item's text is one column in and
/// the rest of the gap indents a code block (CommonMark 5.2). A tab runs
/// to the next multiple of four, as CommonMark counts it.
bool _startsCode(String gap, {required int from}) {
  var column = from;
  for (final unit in gap.codeUnits) {
    column = unit == 0x09 ? column + 4 - column % 4 : column + 1;
  }
  return column - from >= 5;
}

/// Whether the blank line at [at] sits between two items: the next line
/// that is not blank is another item's marker.
bool _blankJoinsItem(List<String> lines, int at) {
  for (var next = at + 1; next < lines.length; next++) {
    if (lines[next].trim().isEmpty) continue;
    return listMarker.hasMatch(lines[next]);
  }
  return false;
}

/// [lines] with their task boxes written canonically — `[x]` for a ticked
/// one, whatever case it was, `[ ]` for an empty one, `[]` and `[  ]`
/// included — and one space between the box and its text. With [enabled]
/// false the lines come back untouched.
List<String> normalizeTaskBoxes(List<String> lines, {required bool enabled}) {
  if (!enabled) return lines;
  return <String>[for (final line in lines) _boxed(line) ?? line];
}

String? _boxed(String line) {
  final match = _taskBox.firstMatch(line);
  if (match == null) return null;
  final marker = match.group(1)!;
  final gap = match.group(2)!;
  // Past five columns the bracket is code, not a box.
  if (_startsCode(gap, from: marker.length)) return null;
  final checked = match.group(3)!.toLowerCase().contains('x');
  final rest = line.substring(match.end);
  return '$marker$gap${checked ? '[x]' : '[ ]'}'
      '${rest.isEmpty ? '' : ' $rest'}';
}
