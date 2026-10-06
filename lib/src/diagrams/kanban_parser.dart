/// The parser behind a `kanban` Mermaid fence (#530).
///
/// A board is told by indentation: a line as far left as the first one is
/// a column, a line further right a card of the column above it. Either is
/// written `id[text]`, `[text]` or plain text, and a card may end in
/// `@{ ticket: …, assigned: …, priority: … }`. Like the other parsers it
/// reports a syntax error as a [MermaidParseException] naming the line.
library;

import 'package:niman/src/diagrams/kanban_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// A node's text: `id[text]` or `[text]`, or the whole line.
final RegExp _bracketed = RegExp(r'^[\w-]*\[(.*)\]$');

/// One `key: value` of a card's metadata, the value quoted or bare.
final RegExp _entry = RegExp(
  r'''(\w+)\s*:\s*(?:'([^']*)'|"([^"]*)"|([^,}]+))''',
);

/// Parses a kanban board (the fence's content, header included).
KanbanBoard parseKanban(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  if (index >= lines.length ||
      stripMermaidComment(lines[index]).trim().toLowerCase() != 'kanban') {
    throw MermaidParseException(index + 1, 'expected "kanban"');
  }
  int? columnIndent;
  final titles = <String>[];
  final cards = <List<KanbanCard>>[];
  for (index++; index < lines.length; index++) {
    final raw = stripMermaidComment(lines[index]);
    final line = raw.trim();
    if (line.isEmpty) continue;
    final indent = raw.length - raw.trimLeft().length;
    columnIndent ??= indent;
    if (indent <= columnIndent) {
      titles.add(_text(line));
      cards.add([]);
    } else {
      cards.last.add(_card(line, index + 1));
    }
  }
  if (titles.isEmpty) {
    throw const MermaidParseException(1, 'a kanban board needs a column');
  }
  return KanbanBoard(
    columns: [
      for (var c = 0; c < titles.length; c++)
        KanbanColumn(title: titles[c], cards: List.unmodifiable(cards[c])),
    ],
  );
}

/// The card [line] (diagram line [number]) writes.
KanbanCard _card(String line, int number) {
  final at = line.indexOf('@{');
  if (at < 0) return KanbanCard(text: _text(line));
  if (!line.endsWith('}')) {
    throw MermaidParseException(number, 'expected "}" to close "@{"');
  }
  final data = <String, String>{
    for (final match in _entry.allMatches(line.substring(at + 2)))
      match.group(1)!.toLowerCase():
          (match.group(2) ?? match.group(3) ?? match.group(4)!).trim(),
  };
  return KanbanCard(
    text: _text(line.substring(0, at).trim()),
    ticket: _decoded(data['ticket']),
    assigned: _decoded(data['assigned']),
    priority: switch (data['priority']?.toLowerCase()) {
      'very high' => KanbanPriority.veryHigh,
      'high' => KanbanPriority.high,
      'low' => KanbanPriority.low,
      'very low' => KanbanPriority.veryLow,
      _ => null,
    },
  );
}

/// A node's text, out of its brackets.
String _text(String written) => decodeMermaidEntities(
  (_bracketed.firstMatch(written)?.group(1) ?? written).trim(),
);

String? _decoded(String? text) =>
    text == null ? null : decodeMermaidEntities(text);
