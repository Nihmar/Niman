// #1154: the kanban board reader — columns, cards, the settings footer.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/kanban_board.dart';

import '../fakes/kanban_samples.dart';

void main() {
  group('parseKanban: the issue board', () {
    late KanbanBoard board;
    setUp(() => board = parseKanban(issueBoard));

    test('reads the columns in the file order', () {
      expect(board.columns.map((c) => c.name).toList(), [
        'To do',
        'Doing',
        'Done',
      ]);
      expect(board.columns.map((c) => c.headingLine).toList(), [3, 7, 11]);
      expect(board.columns.map((c) => c.cards.length).toList(), [2, 1, 1]);
    });

    test('a card has its line range, title, box and tags', () {
      final card = board.columns[0].cards[0];
      expect(card.line, 4);
      expect(card.end, 5);
      expect(card.title, 'Write the brief #work');
      expect(card.checked, isFalse);
      expect(card.hasBox, isTrue);
      expect(card.marker, '-');
      expect(card.tags, ['work']);
      expect(card.due, isNull);
      expect(card.body, isEmpty);
      expect(card.indent, 0);
    });

    test('a card reads its due date', () {
      final card = board.columns[0].cards[1];
      expect(card.due, DateTime(2026, 11, 10));
      expect(card.title, 'Book the venue due:2026-11-10');
      expect(card.tags, isEmpty);
    });

    test('the indented line under a card is its body', () {
      final card = board.columns[1].cards[0];
      expect(card.line, 8);
      expect(card.end, 10);
      expect(card.lineCount, 2);
      expect(card.title, 'Draft the slides');
      expect(card.body, ['Outline first, then visuals.']);
    });

    test('a ticked card reads as checked', () {
      expect(board.columns[2].cards[0].checked, isTrue);
      expect(board.columns[2].cards[0].title, 'Pick the date');
    });

    test('the frontmatter is not read and is recorded', () {
      expect(board.frontmatterEnd, 3);
      expect(board.hasSettings, isFalse);
      expect(board.settingsLine, isNull);
    });

    test('the end of a column is the line before the next heading', () {
      expect(board.columns[0].endLine, 7);
      expect(board.columns[1].endLine, 11);
      expect(board.columns[2].endLine, board.contentEnd);
      expect(board.contentEnd, 13);
    });

    test('a card is inserted before the blank line that ends a column', () {
      expect(board.columns[0].insertLine, 6);
      expect(board.columns[1].insertLine, 10);
      expect(board.columns[2].insertLine, 13);
    });

    test('render hands the text back as read', () {
      expect(board.render(), issueBoard);
    });
  });

  group('parseKanban: cards', () {
    test('plain items, *, + and ticked boxes are cards', () {
      final board = parseKanban(
        '## A\n- plain\n* star\n+ plus\n- [ ] open\n- [x] done\n- [X] DONE\n',
      );
      final cards = board.columns.single.cards;
      expect(cards.map((c) => c.title).toList(), [
        'plain',
        'star',
        'plus',
        'open',
        'done',
        'DONE',
      ]);
      expect(cards.map((c) => c.marker).toList(), [
        '-',
        '*',
        '+',
        '-',
        '-',
        '-',
      ]);
      expect(cards.map((c) => c.checked).toList(), [
        null,
        null,
        null,
        false,
        true,
        true,
      ]);
      expect(cards.map((c) => c.hasBox).toList(), [
        false,
        false,
        false,
        true,
        true,
        true,
      ]);
    });

    test('a bracket that is not a box stays in the title', () {
      final board = parseKanban('## A\n- [?] odd\n- [x]glued\n');
      final cards = board.columns.single.cards;
      expect(cards[0].title, '[?] odd');
      expect(cards[0].checked, isNull);
      expect(cards[1].title, '[x]glued');
      expect(cards[1].checked, isNull);
    });

    test('an empty item is a card with an empty title', () {
      final board = parseKanban('## A\n-\n- [ ]\n');
      final cards = board.columns.single.cards;
      expect(cards.map((c) => c.title).toList(), ['', '']);
      expect(cards.map((c) => c.checked).toList(), [null, false]);
    });

    test('title offsets index the first line', () {
      final board = parseKanban('## A\n- [ ] one\n-   two\n  * [x] three\n');
      final cards = board.columns.single.cards;
      expect(cards[0].titleStart, 6);
      expect(cards[0].boxStart, 2);
      expect(cards[1].titleStart, 4);
      expect(cards[1].boxStart, isNull);
      // The third is nested under the second: its body.
      expect(cards, hasLength(2));
    });

    test('nested items and indented text are the body', () {
      final board = parseKanban(
        '## A\n'
        '- [ ] parent\n'
        '  - [ ] child\n'
        '    - grandchild\n'
        '  notes\n'
        '- [ ] next\n',
      );
      final cards = board.columns.single.cards;
      expect(cards, hasLength(2));
      expect(cards[0].body, ['- [ ] child', '  - grandchild', 'notes']);
      expect(cards[0].end, 5);
      expect(cards[1].line, 5);
    });

    test('blank lines between body lines belong to the card', () {
      final board = parseKanban(
        '## A\n- [ ] one\n  first\n\n  second\n\n- [ ] two\n',
      );
      final cards = board.columns.single.cards;
      expect(cards[0].line, 1);
      expect(cards[0].end, 5);
      expect(cards[0].body, ['first', '', 'second']);
      expect(cards[1].line, 6);
    });

    test('blank lines after the last body line do not', () {
      final board = parseKanban('## A\n- one\n  body\n\n\n## B\n');
      expect(board.columns[0].cards.single.end, 3);
      expect(board.columns[0].insertLine, 3);
    });

    test('tags and the due date are read from the title line', () {
      final board = parseKanban(
        '## A\n'
        '- [ ] ship it #work #q4 due:2026-12-01\n'
        '  body #ignored due:2030-01-01\n'
        '- [ ] bad due:2026-13-45 and C# and a+b\n',
      );
      final cards = board.columns.single.cards;
      expect(cards[0].tags, ['work', 'q4']);
      expect(cards[0].due, DateTime(2026, 12));
      expect(cards[1].tags, isEmpty);
      expect(cards[1].due, isNull);
    });

    test('an item with an indent of one to three spaces is a card', () {
      final board = parseKanban('## A\n - one\n  - two\n   - three\n');
      // The second and third are nested under the first.
      final cards = board.columns.single.cards;
      expect(cards, hasLength(1));
      expect(cards.single.indent, 1);
      expect(cards.single.end, 4);
    });

    test('an item indented four spaces outside a card is not a card', () {
      final board = parseKanban('## A\n    - code-ish\n- real\n');
      expect(board.columns.single.cards.map((c) => c.title).toList(), ['real']);
    });

    test('a numbered list is not a card', () {
      final board = parseKanban('## A\n1. one\n2) two\n- card\n');
      expect(board.columns.single.cards.map((c) => c.title).toList(), ['card']);
    });

    test('a horizontal rule is not a card', () {
      final board = parseKanban('## A\n- a\n---\n***\n- b\n');
      expect(board.columns.single.cards.map((c) => c.title).toList(), [
        'a',
        'b',
      ]);
    });
  });

  group('parseKanban: prose and other headings', () {
    test('text and items before the first column are not cards', () {
      final board = parseKanban(
        'Intro line\n- not a card\n- [ ] nor this\n\n## A\n- [ ] yes\n',
      );
      expect(board.columns, hasLength(1));
      expect(board.columns.single.headingLine, 4);
      expect(board.columns.single.cards.single.title, 'yes');
    });

    test('a board with no column has none', () {
      expect(parseKanban('').columns, isEmpty);
      expect(parseKanban('\n').columns, isEmpty);
      expect(parseKanban('- [ ] loose\n').columns, isEmpty);
      expect(parseKanban('# Title\nprose\n').columns, isEmpty);
    });

    test('prose between cards ends a card and is not one', () {
      final board = parseKanban(
        '## A\n- [ ] one\n  body\nA paragraph.\n- [ ] two\n> quote\n'
        '- [ ] three\n',
      );
      final cards = board.columns.single.cards;
      expect(cards.map((c) => c.title).toList(), ['one', 'two', 'three']);
      expect(cards[0].end, 3);
      expect(cards[1].end, 5);
    });

    test('other heading levels are prose, not columns', () {
      final board = parseKanban(
        '# Board\n'
        '## A\n'
        '- [ ] one\n'
        '### Sub\n'
        '- [ ] two\n'
        '#### Deeper\n'
        '###### Deepest\n'
        '## B\n'
        '- [ ] three\n',
      );
      expect(board.columns.map((c) => c.name).toList(), ['A', 'B']);
      expect(board.columns[0].cards.map((c) => c.title).toList(), [
        'one',
        'two',
      ]);
      expect(board.columns[1].cards.single.title, 'three');
    });

    test('a column name drops a closing run of # and keeps C#', () {
      final board = parseKanban('## Done ##\n## C#\n##\n## In  progress  \n');
      expect(board.columns.map((c) => c.name).toList(), [
        'Done',
        'C#',
        '',
        'In  progress',
      ]);
    });

    test('a heading nested under a card is its body, not a column', () {
      final board = parseKanban('## A\n- one\n  ## not a column\n- two\n');
      expect(board.columns, hasLength(1));
      expect(board.columns.single.cards.first.body, ['## not a column']);
    });

    test('an empty column has nothing and inserts under its heading', () {
      final board = parseKanban('## A\n\n## B\n- b\n');
      expect(board.columns[0].cards, isEmpty);
      expect(board.columns[0].insertLine, 1);
      expect(board.columns[0].endLine, 2);
    });

    test('the last column with no newline at the end of the note', () {
      final board = parseKanban('## A\n- a');
      expect(board.contentEnd, 2);
      expect(board.columns.single.cards.single.end, 2);
      expect(board.columns.single.insertLine, 2);
    });
  });

  group('parseKanban: protected blocks', () {
    test('headings and items inside a code fence are neither', () {
      final board = parseKanban(
        '## A\n'
        '- [ ] one\n'
        '```\n'
        '## fake column\n'
        '- [ ] fake card\n'
        '```\n'
        '- [ ] two\n',
      );
      expect(board.columns, hasLength(1));
      expect(board.columns.single.cards.map((c) => c.title).toList(), [
        'one',
        'two',
      ]);
    });

    test('a tilde fence and an unclosed fence protect too', () {
      final board = parseKanban(
        '## A\n- a\n~~~\n## x\n- y\n~~~\n## B\n```\n## z',
      );
      expect(board.columns.map((c) => c.name).toList(), ['A', 'B']);
      expect(board.columns[0].cards, hasLength(1));
      expect(board.columns[1].cards, isEmpty);
    });

    test('math block lines are neither', () {
      final board = parseKanban('## A\n\$\$\n## no\n- no\n\$\$\n- yes\n');
      expect(board.columns.single.cards.map((c) => c.title).toList(), ['yes']);
    });

    test('a fence indented under a card belongs to its body', () {
      final board = parseKanban(
        '## A\n'
        '- [ ] snippet\n'
        '  ```dart\n'
        'unindented code\n'
        '## still code\n'
        '  ```\n'
        '- [ ] next\n',
      );
      final cards = board.columns.single.cards;
      expect(cards, hasLength(2));
      expect(cards[0].line, 1);
      expect(cards[0].end, 6);
      expect(cards[1].title, 'next');
    });

    test('an unindented fence between cards is prose', () {
      final board = parseKanban(
        '## A\n- one\n  body\n```\ncode\n```\n  stray\n- two\n',
      );
      final cards = board.columns.single.cards;
      expect(cards[0].end, 3);
      expect(cards.map((c) => c.title).toList(), ['one', 'two']);
    });

    test('frontmatter lines are never columns or cards', () {
      final board = parseKanban(
        '---\n## fm\n- [ ] fm card\ntype: kanban\n---\n## A\n- [ ] a\n',
      );
      expect(board.columns.map((c) => c.name).toList(), ['A']);
      expect(board.frontmatterEnd, 5);
    });

    test('a note without a frontmatter has frontmatterEnd 0', () {
      expect(parseKanban('## A\n').frontmatterEnd, 0);
      expect(parseKanban('text\n---\n## A\n').frontmatterEnd, 0);
    });
  });

  group('parseKanban: the Obsidian settings footer', () {
    late KanbanBoard board;
    setUp(() => board = parseKanban(obsidianBoard));

    test('is found and ends the board', () {
      expect(board.hasSettings, isTrue);
      final lines = obsidianBoard.split('\n');
      expect(lines[board.settingsLine!], '%% kanban:settings');
      expect(board.contentEnd, board.settingsLine);
    });

    test('is never read into columns or cards', () {
      expect(board.columns.map((c) => c.name).toList(), [
        'To do',
        'Doing',
        'Done',
      ]);
      final cards = board.columns.expand((c) => c.cards).toList();
      expect(cards.map((c) => c.title).toList(), [
        'Write the brief #work',
        'Book the venue due:2026-11-10',
        'Draft the slides',
        'Pick the date',
      ]);
      for (final column in board.columns) {
        expect(column.endLine, lessThanOrEqualTo(board.settingsLine!));
        expect(column.insertLine, lessThanOrEqualTo(board.settingsLine!));
        for (final card in column.cards) {
          expect(card.end, lessThanOrEqualTo(board.settingsLine!));
        }
      }
    });

    test('the Obsidian frontmatter and layout read', () {
      expect(board.frontmatterEnd, 5);
      expect(board.columns[0].cards.map((c) => c.line).toList(), [8, 9]);
      final doing = board.columns[1].cards.single;
      expect(doing.body, ['Outline first, then visuals.']);
      expect(doing.end - doing.line, 2);
    });

    test('a prose line in a column stays prose, the card after it reads', () {
      final done = board.columns[2];
      expect(done.cards.single.title, 'Pick the date');
      expect(done.insertLine, done.cards.single.end);
    });

    test('headings and items inside the footer fence are ignored', () {
      final tricky = parseKanban(
        '## A\n- a\n\n%% kanban:settings\n```\n## fake\n- [ ] fake\n```\n%%\n',
      );
      expect(tricky.columns, hasLength(1));
      expect(tricky.columns.single.cards, hasLength(1));
      expect(tricky.settingsLine, 3);
    });

    test('the marker inside a code fence is not a footer', () {
      const text = '## A\n- a\n```\n%% kanban:settings\n```\n- b\n';
      final fenced = parseKanban(text);
      expect(fenced.hasSettings, isFalse);
      expect(fenced.columns.single.cards, hasLength(2));
    });

    test('an indented marker is not the footer', () {
      final indented = parseKanban('## A\n- a\n  %% kanban:settings\n- b\n');
      expect(indented.hasSettings, isFalse);
    });
  });

  group('parseKanban: line endings', () {
    test('a CRLF board reads the same as an LF one', () {
      final lf = parseKanban(issueBoard);
      final crlfBoard = parseKanban(crlf(issueBoard));
      expect(crlfBoard.lineEnding, '\r\n');
      expect(lf.lineEnding, '\n');
      expect(crlfBoard.columns.map((c) => c.name).toList(), [
        'To do',
        'Doing',
        'Done',
      ]);
      for (var c = 0; c < lf.columns.length; c++) {
        expect(
          crlfBoard.columns[c].cards.map(
            (k) => (k.line, k.end, k.title, k.checked),
          ),
          lf.columns[c].cards.map((k) => (k.line, k.end, k.title, k.checked)),
        );
        expect(crlfBoard.columns[c].insertLine, lf.columns[c].insertLine);
      }
      expect(crlfBoard.columns[1].cards.single.body, [
        'Outline first, then visuals.',
      ]);
    });

    test(r'the lines keep their \r and render hands the text back', () {
      final text = crlf(issueBoard);
      final board = parseKanban(text);
      expect(board.lines[3], '## To do\r');
      expect(board.render(), text);
      expect(board.endLine('x'), 'x\r');
    });

    test('an Obsidian board in CRLF finds its footer', () {
      final board = parseKanban(crlf(obsidianBoard));
      expect(board.hasSettings, isTrue);
      expect(board.columns, hasLength(3));
    });

    test('the dominant ending wins in a mixed note', () {
      expect(parseKanban('a\r\nb\r\nc\n').lineEnding, '\r\n');
      expect(parseKanban('a\nb\nc\r\n').lineEnding, '\n');
      expect(parseKanban('a\nb').lineEnding, '\n');
      expect(parseKanban('').lineEnding, '\n');
    });
  });

  group('parseKanban: round trip', () {
    final samples = <String, String>{
      'empty': '',
      'newline': '\n',
      'issue': issueBoard,
      'obsidian': obsidianBoard,
      'crlf': crlf(issueBoard),
      'no trailing newline': '## A\n- a',
      'mixed': '## A\r\n- a\n- b\r\n',
      'prose': 'intro\n\n## A\ntext\n- a\nmore\n\n# H1\n',
    };
    for (final MapEntry(key: name, value: text) in samples.entries) {
      test('$name: render is the text, the line count matches', () {
        final board = parseKanban(text);
        expect(board.render(), text);
        expect(board.lines.length, text.split('\n').length);
      });
    }

    test('lines of the board are unmodifiable', () {
      final board = parseKanban(issueBoard);
      expect(() => board.lines.add('x'), throwsUnsupportedError);
    });
  });
}
