/// A fenced code block taken apart: the language its info string names,
/// and its code.
///
/// The one reading of a fence's lines that the read view, `live` and the
/// export share, so a Mermaid fence is the same source to all three (#530):
/// they each had their own, and only the export took the fence's indent
/// off its code.
library;

/// A fenced block's language — its info string's first word, empty when it
/// has none — its code, and whether a closing fence ends it.
typedef FenceBody = ({String language, String code, bool closed});

/// A fence's opening line: its indent, its run and its info string.
final RegExp _opening = RegExp(r'^([ \t]*)(`{3,}|~{3,})(.*)$');

/// [lines] — a fenced block's as the note writes them, fences included —
/// taken apart, or null when the first is not a fence's opening.
///
/// The opening line's indent — a list item's, and the fence's own three
/// spaces at most — comes off every line of the code, as far as the line
/// has it (CommonMark 4.5). The last line closes the fence when it is a run
/// of the opening's character, at least as long, and nothing else.
FenceBody? fenceBody(List<String> lines) {
  final open = lines.isEmpty ? null : _opening.firstMatch(lines.first);
  if (open == null) return null;
  final indent = _columns(open.group(1)!);
  final fence = open.group(2)!;
  final language = open.group(3)!.trim().split(RegExp(r'\s+')).first;
  final closing = RegExp(
    '^[ \\t]*${RegExp.escape(fence[0])}{${fence.length},}[ \\t]*\$',
  );
  final closed = lines.length > 1 && closing.hasMatch(lines.last);
  final body = lines.sublist(1, closed ? lines.length - 1 : lines.length);
  return (
    language: language,
    code: [for (final line in body) _dedent(line, indent)].join('\n'),
    closed: closed,
  );
}

/// How many columns [indent] takes, a tab to the next multiple of four.
int _columns(String indent) {
  var column = 0;
  for (final char in indent.codeUnits) {
    column = char == 0x09 ? (column ~/ 4 + 1) * 4 : column + 1;
  }
  return column;
}

/// [line] with up to [indent] columns of leading space taken off.
String _dedent(String line, int indent) {
  var column = 0;
  var at = 0;
  while (column < indent && at < line.length) {
    final char = line.codeUnitAt(at);
    if (char == 0x20) {
      column++;
      at++;
    } else if (char == 0x09) {
      // A tab advances to the next multiple of four, as CommonMark
      // counts indentation.
      column = (column ~/ 4 + 1) * 4;
      at++;
    } else {
      break;
    }
  }
  // A tab that reached past the fence's indent is partly that indent and
  // partly code: the columns past it stay, as spaces.
  final extra = column > indent ? column - indent : 0;
  return '${' ' * extra}${line.substring(at)}';
}
