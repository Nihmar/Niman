/// Code blocks written as HTML, as `cmark` writes them.
library;

import 'package:niman/src/markdown/inline/inline_html.dart';
import 'package:niman/src/markdown/inline/inline_scanners.dart';

/// The code a code block holds: the HTML writer's and the read view's.
abstract final class CodeHtml {
  /// A fenced block of [lines] — its opening fence first, its closing one
  /// last when it has one — with the language its info string names.
  static String fenced(List<String> lines) {
    final parts = fenceParts(lines);
    final body = StringBuffer();
    for (final line in parts.code) {
      body
        ..write(line)
        ..write('\n');
    }
    final info = parts.info;
    final language = info.isEmpty ? null : info.split(_space).first;
    final type = language == null
        ? ''
        : ' class="language-${InlineHtml.escape(language)}"';
    return '<pre><code$type>${InlineHtml.escape(body.toString())}'
        '</code></pre>\n';
  }

  /// A fenced block's parts, from its [lines]: its info string, its code
  /// lines — each without as many spaces as the opening fence stood in —
  /// and whether its last line closes it.
  ///
  /// [open] is the opening fence of lines that go on with a fence a block
  /// above them opened — an item's marker line, read as a block of its own
  /// — and have none of their own: `(char, length, indent)`.
  static ({String info, List<String> code, bool closed}) fenceParts(
    List<String> lines, {
    (int, int, int)? open,
  }) {
    var from = 0;
    var info = '';
    final int char;
    final int length;
    final int indent;
    if (open != null) {
      (char, length, indent) = open;
    } else {
      final line = lines.first;
      var at = 0;
      while (at < line.length && line.codeUnitAt(at) == 0x20) {
        at++;
      }
      indent = at;
      char = line.codeUnitAt(at);
      var run = 0;
      while (at + run < line.length && line.codeUnitAt(at + run) == char) {
        run++;
      }
      length = run;
      info = InlineScanners.unescape(line.substring(at + run).trim());
      from = 1;
    }
    var end = lines.length;
    final closed = end > from && _closes(lines.last, char, length);
    if (closed) end--;
    return (
      info: info,
      code: [
        for (final line in lines.sublist(from, end))
          line.substring(_spacesUpTo(line, indent)),
      ],
      closed: closed,
    );
  }

  /// How many of the spaces [line] starts with, up to [indent].
  static int _spacesUpTo(String line, int indent) {
    var cut = 0;
    while (cut < indent && cut < line.length && line.codeUnitAt(cut) == 0x20) {
      cut++;
    }
    return cut;
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
    final body = StringBuffer();
    for (final line in indentedCode(
      lines,
      starts: starts,
      leftOver: leftOver,
    )) {
      body
        ..write(line)
        ..write('\n');
    }
    return '<pre><code>${InlineHtml.escape(body.toString())}</code></pre>\n';
  }

  /// An indented block's code lines, as [indented] writes them.
  static List<String> indentedCode(
    List<String> lines, {
    List<int> starts = const <int>[],
    List<int> leftOver = const <int>[],
  }) {
    var end = lines.length;
    while (end > 0 && lines[end - 1].trim().isEmpty) {
      end--;
    }
    return [
      for (var at = 0; at < end; at++)
        _dedent(
          lines[at],
          start: at < starts.length ? starts[at] : 0,
          leftOver: at < leftOver.length ? leftOver[at] : 0,
        ),
    ];
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
