import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/kanban/line_ending.dart';

/// Runs one board edit over [text] and gives the new text.
///
/// [edit] gets the board read from [text] and a growable copy of its lines
/// to splice, and says whether it changed anything: when it did not, [text]
/// comes back as the very same string. The lines are joined with `\n`, so
/// every line the edit did not touch keeps its bytes, `\r` included.
///
/// A note that does not end with a newline has an unterminated last line,
/// which a splice at the end would otherwise leave glued to the new ones:
/// it is given its terminator for the edit and loses it again after, so
/// the result ends the way the note did.
String editBoard(
  String text,
  bool Function(KanbanBoard board, List<String> lines) edit,
) {
  final pad = text.isNotEmpty && !text.endsWith('\n');
  final ending = pad ? lineEndingOf(text) : '';
  final source = pad ? '$text$ending' : text;
  final board = parseKanban(source);
  final lines = List<String>.of(board.lines);
  if (!edit(board, lines)) return text;
  final out = lines.join('\n');
  return pad && out.endsWith(ending)
      ? out.substring(0, out.length - ending.length)
      : out;
}

/// [text] as one line of a title or a name: its line breaks become a space
/// and its ends are trimmed.
String oneLine(String text) =>
    text.replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ').trim();

/// [lines] with the leading spaces of each moved by [delta]: that many
/// added when positive, up to that many removed when negative (only spaces
/// are removed). A delta of zero hands back the same bytes.
List<String> reindent(List<String> lines, int delta) {
  if (delta == 0) return lines;
  if (delta > 0) {
    final pad = ' ' * delta;
    return <String>[for (final line in lines) '$pad$line'];
  }
  return <String>[for (final line in lines) _dedent(line, -delta)];
}

String _dedent(String line, int n) {
  var at = 0;
  while (at < line.length && at < n && line.codeUnitAt(at) == 0x20) {
    at++;
  }
  return line.substring(at);
}
