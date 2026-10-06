/// Code blocks written as HTML, as `cmark` writes them.
library;

import 'package:niman/src/markdown/inline/inline_html.dart';
import 'package:niman/src/markdown/inline/inline_scanners.dart';

/// Writes a code block from its lines.
abstract final class CodeHtml {
  /// A fenced block of [lines] — its opening fence first, its closing one
  /// last when it has one — with the language its info string names.
  static String fenced(List<String> lines) {
    final open = lines.first;
    var indent = 0;
    while (indent < open.length && open.codeUnitAt(indent) == 0x20) {
      indent++;
    }
    final char = open.codeUnitAt(indent);
    var length = 0;
    while (indent + length < open.length &&
        open.codeUnitAt(indent + length) == char) {
      length++;
    }
    final info = InlineScanners.unescape(
      open.substring(indent + length).trim(),
    );
    var end = lines.length;
    if (end > 1 && _closes(lines.last, char, length)) end--;
    final body = StringBuffer();
    for (final line in lines.sublist(1, end)) {
      var cut = 0;
      while (cut < indent &&
          cut < line.length &&
          line.codeUnitAt(cut) == 0x20) {
        cut++;
      }
      body
        ..write(line.substring(cut))
        ..write('\n');
    }
    final language = info.isEmpty ? null : info.split(_space).first;
    final type = language == null
        ? ''
        : ' class="language-${InlineHtml.escape(language)}"';
    return '<pre><code$type>${InlineHtml.escape(body.toString())}'
        '</code></pre>\n';
  }

  static bool _closes(String line, int char, int length) {
    var at = 0;
    while (at < 3 && at < line.length && line.codeUnitAt(at) == 0x20) {
      at++;
    }
    var run = 0;
    while (at + run < line.length && line.codeUnitAt(at + run) == char) {
      run++;
    }
    return run >= length && line.substring(at + run).trim().isEmpty;
  }

  /// An indented block of [lines]: four columns off each, a tab split
  /// when it straddles them; blank lines at its end left out.
  ///
  /// Each line starts at column `starts[i]` of its line in the note — a tab
  /// reaches the next stop of four counted from there — after
  /// `leftOver[i]` columns of a tab its container's prefix ended inside of:
  /// white space that is no character of the line, but is the code's.
  static String indented(
    List<String> lines, {
    List<int> starts = const <int>[],
    List<int> leftOver = const <int>[],
  }) {
    var end = lines.length;
    while (end > 0 && lines[end - 1].trim().isEmpty) {
      end--;
    }
    final body = StringBuffer();
    for (var at = 0; at < end; at++) {
      body
        ..write(
          _dedent(
            lines[at],
            start: at < starts.length ? starts[at] : 0,
            leftOver: at < leftOver.length ? leftOver[at] : 0,
          ),
        )
        ..write('\n');
    }
    return '<pre><code>${InlineHtml.escape(body.toString())}</code></pre>\n';
  }

  /// [line] with four columns of white space off — counted from where its
  /// content starts, [leftOver] columns before [start], the column [line]
  /// starts at — a tab to the next stop of four, the rest of a split tab as
  /// spaces.
  static String _dedent(
    String line, {
    required int start,
    required int leftOver,
  }) {
    final target = start - leftOver + 4;
    var column = start;
    if (column >= target) return ' ' * (column - target) + line;
    var at = 0;
    while (at < line.length && column < target) {
      final char = line.codeUnitAt(at);
      if (char == 0x20) {
        column++;
        at++;
      } else if (char == 0x09) {
        final width = 4 - column % 4;
        if (column + width > target) {
          return ' ' * (column + width - target) + line.substring(at + 1);
        }
        column += width;
        at++;
      } else {
        break;
      }
    }
    return line.substring(at);
  }

  static final RegExp _space = RegExp(r'\s+');
}
