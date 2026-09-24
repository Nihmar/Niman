/// The colours of a todo.txt line in the editor: where its priority, its
/// dates, its projects, contexts, tags and `key:value` tags are.
///
/// Read by the grammar the Todo tab parses the file with ([parseTodoLine]):
/// the same prefix — completion mark, priority, dates — and the same
/// tokens, which open a line or follow whitespace, so `a+b` and `C#` stay
/// text here as they do there.
library;

import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/todo/parser.dart';

/// Whether the file named [name] is one the editor colours as todo.txt:
/// the Todo tab's `todo.txt` and its archive, `done.txt`.
bool isTodoTxtFile(String name) {
  final lower = name.toLowerCase();
  return lower == 'todo.txt' || lower == 'done.txt';
}

/// The runs of todo.txt [line], disjoint and in order.
///
/// A completed task is one run, the whole line: it has stepped back, and
/// its projects and dates with it.
List<Token> todoTxtTokens(String line) {
  final task = parseTodoLine(line);
  if (task.completed) {
    return line.trim().isEmpty
        ? const <Token>[]
        : <Token>[Token(TokenKind.todoDone, 0, line.length)];
  }
  final tokens = <Token>[];
  // The head, as the parser reads it: blank space, a priority, a date.
  var at = _blankFrom(line, 0);
  final priority = _priority.matchAsPrefix(line, at);
  if (priority != null) {
    tokens.add(Token(TokenKind.todoPriority, at, priority.end));
    at = _blankFrom(line, priority.end);
  }
  final date = _date.matchAsPrefix(line, at);
  if (date != null && task.creationDate != null) {
    tokens.add(Token(TokenKind.todoDate, at, date.end));
  }
  // The description's tokens, wherever they are.
  final spans = <Token>[
    for (final match in _word.allMatches(line))
      if (_kindOf(match.group(0)!) case final kind?)
        Token(kind, match.start, match.end),
  ];
  for (final span in spans) {
    if (tokens.isNotEmpty && span.start < tokens.last.end) continue;
    tokens.add(span);
  }
  return tokens;
}

/// The run a description word is, or null for plain text.
TokenKind? _kindOf(String word) {
  if (word.length < 2) return null;
  return switch (word[0]) {
    '+' => TokenKind.todoProject,
    '@' => TokenKind.todoContext,
    '#' => TokenKind.tag,
    _ => _keyValue.hasMatch(word) ? TokenKind.todoKeyValue : null,
  };
}

int _blankFrom(String line, int from) {
  var at = from;
  while (at < line.length &&
      (line.codeUnitAt(at) == 0x20 || line.codeUnitAt(at) == 0x09)) {
    at++;
  }
  return at;
}

/// A whitespace-delimited word.
final RegExp _word = RegExp(r'\S+');

/// A priority, `(A)`…`(Z)`, followed by blank space or the line's end.
final RegExp _priority = RegExp(r'\([A-Z]\)(?=\s|$)');

/// A `YYYY-MM-DD` date, followed by blank space or the line's end.
final RegExp _date = RegExp(r'\d{4}-\d{2}-\d{2}(?=\s|$)');

/// A `key:value` tag, as the parser reads one.
final RegExp _keyValue = RegExp(r'^[A-Za-z][A-Za-z0-9_-]*:\S+$');
