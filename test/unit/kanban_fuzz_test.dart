// #1154: the kanban reader and edits over many random notes: whatever the
// note holds, the invariants of the design hold.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/card_edits.dart';
import 'package:niman/src/kanban/column_edits.dart';
import 'package:niman/src/kanban/kanban_board.dart';

const List<String> _units = <String>[
  '## Todo',
  '## Doing',
  '## C#',
  '### sub',
  '# H1',
  '- [ ] card #tag',
  '- [x] done due:2026-01-02',
  '- plain card',
  '* star card',
  '  body line',
  '  - nested',
  '    deeper',
  '',
  '',
  'prose',
  '> quote',
  '1. numbered',
  '```\n## fake\n- [ ] fake\n```',
  '\$\$\n## math\n- math\n\$\$',
  '  ```\n  - code\n  ```',
  '---',
];

const String _footer =
    '%% kanban:settings\n```\n{"kanban-plugin":"board"}\n```\n%%';

String _note(Random random) {
  final units = <String>[
    if (random.nextInt(4) == 0) '---\ntype: kanban\n---',
    for (var i = random.nextInt(26); i > 0; i--)
      _units[random.nextInt(_units.length)],
    if (random.nextInt(3) == 0) _footer,
  ];
  var text = units.join('\n');
  if (random.nextBool()) text = '$text\n';
  if (random.nextInt(3) == 0) text = text.replaceAll('\n', '\r\n');
  return text;
}

/// [text]'s lines without their `\r` and their indentation, sorted: what a
/// move must leave as it was.
List<String> _bag(String text) =>
    text.split('\n').map((l) => l.replaceAll('\r', '').trimLeft()).toList()
      ..sort();

String _shown(String text) => text.replaceAll('\r', r'\r');

String _footerOf(String text) {
  final at = text.indexOf('%% kanban:settings');
  return at < 0 ? '' : text.substring(at);
}

/// Whether the note opens a frontmatter it never closes: all of it is the
/// frontmatter then, and no column can be added to it.
bool _unclosedFrontmatter(KanbanBoard board) {
  final end = board.frontmatterEnd;
  if (end == 0) return false;
  final last = board.lines[end - 1].trim();
  return end == 1 || (last != '---' && last != '...');
}

int _cardCount(KanbanBoard board) =>
    board.columns.fold(0, (sum, c) => sum + c.cards.length);

void _checkBoard(String text) {
  final board = parseKanban(text);
  expect(board.render(), text);
  final footer = board.settingsLine;
  var previousEnd = 0;
  for (final column in board.columns) {
    expect(column.headingLine, greaterThanOrEqualTo(previousEnd));
    expect(column.endLine, greaterThan(column.headingLine));
    expect(column.insertLine, greaterThan(column.headingLine));
    expect(column.insertLine, lessThanOrEqualTo(column.endLine));
    expect(column.endLine, lessThanOrEqualTo(board.contentEnd));
    var from = column.headingLine + 1;
    for (final card in column.cards) {
      expect(card.line, greaterThanOrEqualTo(from));
      expect(card.end, greaterThan(card.line));
      expect(card.end, lessThanOrEqualTo(column.insertLine));
      from = card.end;
    }
    previousEnd = column.endLine;
  }
  if (footer != null) {
    expect(board.contentEnd, footer);
    expect(text.split('\n')[footer], startsWith('%% kanban:settings'));
  }
}

void main() {
  test('random notes: the reader holds its invariants', () {
    final random = Random(1154);
    for (var i = 0; i < 600; i++) {
      _checkBoard(_note(random));
    }
  });

  test('random notes: every edit does what it says and nothing more', () {
    final random = Random(2026);
    var moves = 0;
    for (var i = 0; i < 600; i++) {
      final text = _note(random);
      final board = parseKanban(text);
      if (_unclosedFrontmatter(board)) continue;
      final footer = _footerOf(text);
      final lineCount = text.split('\n').length;

      void check(String out, {String? reason}) {
        _checkBoard(out);
        expect(_footerOf(out), footer, reason: reason ?? 'the footer');
      }

      // Move.
      final sources = <(int, int)>[
        for (var c = 0; c < board.columns.length; c++)
          for (var k = 0; k < board.columns[c].cards.length; k++) (c, k),
      ];
      if (sources.isNotEmpty) {
        final (fromColumn, fromCard) = sources[random.nextInt(sources.length)];
        final toColumn = random.nextInt(board.columns.length);
        final room =
            board.columns[toColumn].cards.length -
            (toColumn == fromColumn ? 1 : 0);
        final toIndex = random.nextInt(room + 1);
        final title = board.columns[fromColumn].cards[fromCard].title;
        final out = moveCard(
          text,
          fromColumn: fromColumn,
          fromCard: fromCard,
          toColumn: toColumn,
          toIndex: toIndex,
        );
        check(out, reason: 'move\n$text');
        expect(_bag(out), _bag(text), reason: 'move keeps the lines\n$text');
        expect(out.split('\n').length, lineCount);
        final after = parseKanban(out);
        expect(_cardCount(after), _cardCount(board));
        expect(
          after.columns[toColumn].cards[toIndex].title,
          title,
          reason:
              'move lands at the index ($fromColumn,$fromCard) to '
              '($toColumn,$toIndex)\n$text',
        );
        moves++;

        // Toggle: one character.
        final card = board.columns[fromColumn].cards[fromCard];
        final toggled = toggleCard(text, fromColumn, fromCard);
        check(toggled);
        expect(toggled.length, text.length);
        if (card.hasBox) {
          var diff = 0;
          for (var c = 0; c < text.length; c++) {
            if (text[c] != toggled[c]) diff++;
          }
          expect(diff, 1);
        } else {
          expect(toggled, same(text));
        }

        // Retitle.
        final retitled = editCardTitle(text, fromColumn, fromCard, 'renamed');
        check(retitled);
        expect(retitled.split('\n').length, lineCount);
        expect(
          parseKanban(retitled).columns[fromColumn].cards[fromCard].title,
          'renamed',
        );
        expect(_cardCount(parseKanban(retitled)), _cardCount(board));

        // Delete.
        final deleted = deleteCard(text, fromColumn, fromCard);
        check(deleted);
        expect(deleted.split('\n').length, lineCount - card.lineCount);
        expect(_cardCount(parseKanban(deleted)), _cardCount(board) - 1);
      }

      // Add a card.
      if (board.columns.isNotEmpty) {
        final column = random.nextInt(board.columns.length);
        final added = addCard(text, column, 'brand new');
        check(added);
        final after = parseKanban(added);
        expect(after.columns[column].cards.last.title, 'brand new');
        expect(
          after.columns[column].cards.length,
          board.columns[column].cards.length + 1,
        );
        expect(_cardCount(after), _cardCount(board) + 1);
        expect(added.split('\n').length, lineCount + 1);
      }

      // Columns.
      final withColumn = addColumn(text, 'Fresh');
      check(withColumn);
      final grown = parseKanban(withColumn);
      expect(grown.columns.length, board.columns.length + 1, reason: text);
      expect(grown.columns.last.name, 'Fresh');
      expect(_cardCount(grown), _cardCount(board));

      if (board.columns.isNotEmpty) {
        final column = random.nextInt(board.columns.length);
        final renamed = renameColumn(text, column, 'Renamed');
        check(renamed);
        final after = parseKanban(renamed);
        expect(after.columns[column].name, 'Renamed');
        expect(after.columns.length, board.columns.length);
        expect(_cardCount(after), _cardCount(board));

        final removed = deleteColumn(text, column);
        check(removed);
        final left = parseKanban(removed);
        // A prose `---` left at the top by the removal opens a frontmatter:
        // the one way an edit can change what the rest of the note is.
        if (left.frontmatterEnd == board.frontmatterEnd) {
          expect(
            left.columns.length,
            board.columns.length - 1,
            reason: 'column $column of ${_shown(text)} -> ${_shown(removed)}',
          );
          expect(
            _cardCount(left),
            _cardCount(board) - board.columns[column].cards.length,
          );
        }
      }
    }
    expect(moves, greaterThan(100), reason: 'the samples exercise moves');
  });

  test('a big board reads and takes a move', () {
    final text = StringBuffer('---\ntype: kanban\n---\n');
    for (var c = 0; c < 20; c++) {
      text.writeln('## Column $c');
      for (var k = 0; k < 2000; k++) {
        text.writeln('- [ ] Card $c-$k #tag due:2026-01-01');
        if (k % 10 == 0) text.writeln('  body of $c-$k');
      }
      text.writeln();
    }
    final source = text.toString();
    final watch = Stopwatch()..start();
    final board = parseKanban(source);
    final out = moveCard(
      source,
      fromColumn: 0,
      fromCard: 5,
      toColumn: 19,
      toIndex: 1500,
    );
    watch.stop();
    expect(board.columns, hasLength(20));
    expect(_cardCount(board), 40000);
    expect(
      parseKanban(out).columns[19].cards[1500].title,
      'Card 0-5 #tag due:2026-01-01',
    );
    // Printed, not held to a bar: the clock of a shared runner says nothing
    // about the code (AGENTS.md, performance tests).
    // ignore: avoid_print
    print(
      'kanban: 40000 cards, read twice and one move: '
      '${watch.elapsedMilliseconds} ms',
    );
  });
}
