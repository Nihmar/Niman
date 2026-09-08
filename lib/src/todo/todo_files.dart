/// Line/ending model for one todo.txt-style file (T-TD-02 helper).
///
/// Splits raw bytes into content lines for the todo store and joins them
/// back for a byte-stable rewrite: each file keeps its dominant line
/// ending and its trailing-newline state, so untouched lines round-trip
/// byte-identical.
library;

import 'dart:convert';
import 'dart:typed_data';

/// One file's content lines with the formatting needed for a byte-stable
/// rewrite.
final class TodoFileContent {
  /// Creates a file view over [lines] ([exists] false = missing file).
  const TodoFileContent({
    required this.lines,
    required this.ending,
    required this.endsWithNewline,
    required this.exists,
  });

  /// The content lines (no terminators; a CRLF file's `\r`s are stripped
  /// by the split and restored by the join).
  final List<String> lines;

  /// The dominant line ending (`\r\n` or `\n`; `\n` for new files).
  final String ending;

  /// Whether the file ends with a newline.
  final bool endsWithNewline;

  /// Whether the file exists on disk.
  final bool exists;

  /// Copies the view with new [lines].
  TodoFileContent copyWith({required List<String> lines}) {
    return TodoFileContent(
      lines: lines,
      ending: ending,
      endsWithNewline: endsWithNewline,
      exists: exists,
    );
  }
}

/// Splits raw [bytes] (null = missing file) into content.
TodoFileContent splitTodoFile(Uint8List? bytes) {
  if (bytes == null) {
    return const TodoFileContent(
      lines: <String>[],
      ending: '\n',
      endsWithNewline: false,
      exists: false,
    );
  }
  final content = utf8.decode(bytes);
  if (content.isEmpty) {
    return const TodoFileContent(
      lines: <String>[],
      ending: '\n',
      endsWithNewline: false,
      exists: true,
    );
  }
  final lines = content.split('\n');
  var endsWithNewline = false;
  if (lines.last == '') {
    endsWithNewline = true;
    lines.removeLast();
  }
  // Dominant ending wins (ties keep CRLF, so a Windows file with one
  // stray LF stays CRLF); files without newlines default to `\n`.
  final crlf = '\r\n'.allMatches(content).length;
  final loneLf = '\n'.allMatches(content).length - crlf;
  final ending = crlf > 0 && crlf >= loneLf ? '\r\n' : '\n';
  return TodoFileContent(
    lines: [for (final line in lines) _stripCarriageReturn(line)],
    ending: ending,
    endsWithNewline: endsWithNewline,
    exists: true,
  );
}

/// Joins [file]'s lines back, restoring the dominant ending and the
/// trailing-newline state (an empty file writes zero bytes).
String joinTodoFile(TodoFileContent file) {
  if (file.lines.isEmpty) {
    return '';
  }
  final body = file.lines.join(file.ending);
  return file.endsWithNewline ? '$body${file.ending}' : body;
}

/// Strips the `\r` a CRLF split leaves at the line end (the parser also
/// tolerates it, but the store canonicalizes before parsing so parsed
/// tasks round-trip with no stray carriage returns).
String _stripCarriageReturn(String line) {
  return line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
}
