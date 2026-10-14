/// The edits the deck view makes to a deck note (#533): rewrite, delete and
/// add a card, each a function from the note's text to the new text.
///
/// The disk is the source of truth, so a card edit is an edit of the note,
/// and it touches the card's own characters and nothing else: the other
/// cells of a row keep their bytes, a table keeps its padding as far as the
/// new words fit it, a line ending stays what it was. The deck view gives
/// the result to the note's host as one undoable edit.
library;

import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// The head a table made for a deck has: the words of the issue, kept
/// English the way a note's own `type: flashcard` is.
const String _questionHead = 'Question';
const String _answerHead = 'Answer';

/// What splits a `::` line into its question and its answer.
const String _divider = ' :: ';

/// The text a new deck note is created with: the type, an empty `deck:`
/// and a two-column table with its head and no row.
String flashcardNoteContent() =>
    '---\ntype: flashcard\ndeck: \n---\n\n'
    '| $_questionHead | $_answerHead |\n|---|---|\n';

/// [text] with the table row or `::` line [card] rewritten to ask
/// [question] and answer [answer], as Markdown. A piece equal to what the
/// card has is left as written.
///
/// A cloze is rewritten whole by [rewriteCloze]; this throws for one.
String rewriteCard(
  String text,
  FlashCard card, {
  required String question,
  required String answer,
}) {
  final asked = question.trim();
  final replied = answer.trim();
  return switch (card.kind) {
    CardKind.tableRow => _rewriteRow(text, card, asked, replied),
    CardKind.line => _rewriteLine(text, card, asked, replied),
    CardKind.cloze => throw ArgumentError.value(
      card,
      'card',
      'a cloze is rewritten as a sentence',
    ),
  };
}

/// What a cloze card's editor shows: the paragraph or list item around the
/// highlight, as written, line endings as `\n`.
String clozeSentence(String text, FlashCard card) => text
    .substring(card.source.content.start, card.source.content.end)
    .replaceAll('\r\n', '\n');

/// [text] with the paragraph of the cloze [card] replaced by [sentence]:
/// one line when the paragraph was one, its line endings the note's.
String rewriteCloze(String text, FlashCard card, String sentence) {
  final multiple = card.source.firstLine != card.source.lastLine;
  var next = sentence.replaceAll('\r\n', '\n').trim();
  if (!multiple) {
    next = next.replaceAll('\n', ' ');
  } else if (text.contains('\r\n')) {
    next = next.replaceAll('\n', '\r\n');
  }
  return _replace(text, card.source.content, next);
}

/// [text] without [card]: its line for a table row or a `::` line, its
/// highlight's marks for a cloze, whose words stay.
String deleteCard(String text, FlashCard card) {
  final source = card.source;
  if (card.kind == CardKind.cloze) {
    final range = source.answer;
    if (range == null) return text;
    final marked = text.substring(range.start, range.end);
    var marks = 0;
    while (marks < marked.length && marked.codeUnitAt(marks) == 0x3D) {
      marks++;
    }
    if (marks == 0 || marked.length < marks * 2) return text;
    return _replace(
      text,
      range,
      marked.substring(marks, marked.length - marks),
    );
  }
  return _removeLines(
    text,
    source.lines,
    tidyBlanks: card.kind == CardKind.line,
  );
}

/// [text] of [deck] with a card asking [question] and answering [answer]
/// added: a row at the end of the deck's first table, or, when it has none,
/// a table made for it at the end of the note.
String addCard(
  String text,
  Deck deck, {
  required String question,
  required String answer,
}) {
  final asked = _cellText(question);
  final replied = _cellText(answer);
  final eol = text.contains('\r\n') ? '\r\n' : '\n';
  if (deck.tables.isEmpty) {
    final table =
        '| $_questionHead | $_answerHead |$eol|---|---|$eol'
        '| $asked | $replied |$eol';
    final body = text.trimRight();
    return body.isEmpty ? table : '$body$eol$eol$table';
  }
  final table = deck.tables.first;
  final parts = _RowParts.of(
    text.substring(table.template.start, table.template.end),
  );
  final cells = <String>[
    for (var at = 0; at < table.columns; at++)
      if (at == table.question)
        _refit(parts.cell(at), asked)
      else if (at == table.answer)
        _refit(parts.cell(at), replied)
      else
        _blank(parts.cell(at)),
  ];
  final row = _RowParts(
    lead: parts.lead,
    trail: parts.trail,
    cells: cells,
  ).text;
  final prefix = text.substring(
    table.last.lines.start,
    table.last.content.start,
  );
  final at = table.last.lines.end;
  return '${text.substring(0, at)}$eol$prefix$row${text.substring(at)}';
}

String _rewriteRow(String text, FlashCard card, String asked, String replied) {
  final source = card.source;
  final questionAt = source.questionColumn;
  final answerAt = source.answerColumn;
  if (questionAt == null || answerAt == null) return text;
  final parts = _RowParts.of(
    text.substring(source.content.start, source.content.end),
  );
  final cells = [...parts.cells];
  while (cells.length <= answerAt || cells.length <= questionAt) {
    cells.add(' ');
  }
  if (asked != card.question) {
    cells[questionAt] = _refit(cells[questionAt], _cellText(asked));
  }
  if (replied != card.answer) {
    cells[answerAt] = _refit(cells[answerAt], _cellText(replied));
  }
  return _replace(
    text,
    source.content,
    _RowParts(lead: parts.lead, trail: parts.trail, cells: cells).text,
  );
}

String _rewriteLine(String text, FlashCard card, String asked, String replied) {
  final source = card.source;
  final question = _lineText(asked).replaceAll(_divider, ' : ');
  final answer = _lineText(replied);
  final questionAt = source.question;
  final answerAt = source.answer;
  if (questionAt == null || answerAt == null) {
    return _replace(text, source.content, '$question$_divider$answer');
  }
  var out = text;
  // The later range first, so the earlier one is still where it was.
  if (replied != card.answer) out = _replace(out, answerAt, answer);
  if (asked != card.question) out = _replace(out, questionAt, question);
  return out;
}

String _replace(String text, NoteRange range, String with_) =>
    '${text.substring(0, range.start)}$with_${text.substring(range.end)}';

/// [text] without [lines] and one line ending, so no empty line is left in
/// its place; with [tidyBlanks], a blank line that would stand beside
/// another goes too.
String _removeLines(String text, NoteRange lines, {required bool tidyBlanks}) {
  var start = lines.start;
  var end = lines.end;
  if (text.startsWith('\r\n', end)) {
    end += 2;
  } else if (text.startsWith('\n', end)) {
    end += 1;
  } else if (start > 0 && text.codeUnitAt(start - 1) == 0x0A) {
    // The note's last line: the line ending before it goes instead.
    start -= start > 1 && text.codeUnitAt(start - 2) == 0x0D ? 2 : 1;
  }
  if (tidyBlanks && end < text.length) {
    final previousBlank = start == 0 || _blankLineBefore(text, start);
    final next = _lineEndAfter(text, end);
    if (previousBlank && text.substring(end, next.end).trim().isEmpty) {
      end = next.after;
    }
  }
  return text.substring(0, start) + text.substring(end);
}

/// Whether the line that ends just before [at] (a line start) is blank.
bool _blankLineBefore(String text, int at) {
  var end = at - 1;
  if (end > 0 && text.codeUnitAt(end - 1) == 0x0D) end--;
  var from = end;
  while (from > 0 && text.codeUnitAt(from - 1) != 0x0A) {
    from--;
  }
  return text.substring(from, end).trim().isEmpty;
}

/// Where the line starting at [from] ends and where the next one starts.
({int end, int after}) _lineEndAfter(String text, int from) {
  var end = from;
  while (end < text.length && text.codeUnitAt(end) != 0x0A) {
    end++;
  }
  final after = end < text.length ? end + 1 : end;
  if (end > from && text.codeUnitAt(end - 1) == 0x0D) end--;
  return (end: end, after: after);
}

/// [text] as the content of a table cell: one line, its pipes escaped.
String _cellText(String text) => text
    .trim()
    .replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ')
    .replaceAllMapped(
      RegExp(r'(\\*)\|'),
      (match) => match[1]!.length.isEven ? '${match[1]}\\|' : match[0]!,
    );

/// [text] as the words of a `::` line side: one line.
String _lineText(String text) =>
    text.trim().replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ');

/// The cell [raw] with [text] in it: the space either side of the words as
/// the cell had it, and, in a padded table, the cell's width kept for as
/// long as the words fit it.
String _refit(String raw, String text) {
  final words = raw.trim();
  final blank = words.isEmpty;
  final lead = blank
      ? (raw.isEmpty ? 0 : 1)
      : raw.length - raw.trimLeft().length;
  var trail = blank
      ? (raw.length > 1 ? raw.length - 1 : (raw.isEmpty ? 0 : 1))
      : raw.length - raw.trimRight().length;
  if (trail > 1) {
    final growth = text.runes.length - words.runes.length;
    trail = trail - growth < 1 ? 1 : trail - growth;
  }
  // A backslash right before the closing pipe would escape it.
  if (text.endsWith(r'\') && trail == 0) trail = 1;
  if (text.isEmpty) return ' ' * (lead + trail);
  return '${' ' * lead}$text${' ' * trail}';
}

/// The cell [raw] with nothing in it, as wide.
String _blank(String raw) => ' ' * raw.length;

/// A table row taken apart: whether it opens and closes with a pipe, and
/// the cells between, each as written.
final class _RowParts {
  const new({required this.lead, required this.trail, required this.cells});

  factory of(String row) {
    final ranges = MarkdownTable.cellRangesOf(row);
    return _RowParts(
      lead: ranges.first.$1 > 0,
      trail: ranges.last.$2 < row.trimRight().length,
      cells: [for (final (start, end) in ranges) row.substring(start, end)],
    );
  }

  final bool lead;
  final bool trail;
  final List<String> cells;

  /// Cell [at], or one space where the row has fewer cells.
  String cell(int at) => at < cells.length ? cells[at] : ' ';

  String get text => '${lead ? '|' : ''}${cells.join('|')}${trail ? '|' : ''}';
}
