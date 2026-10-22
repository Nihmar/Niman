// #1154: the kanban card edits — move, add, retitle, tick, delete — are
// byte-stable: they rewrite only the lines they touch.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/card_edits.dart';

import '../fakes/kanban_samples.dart';

/// How many lines of [after] differ from [before] once the lines both share
/// at the start and the end are set aside: the width of what an edit
/// rewrote.
int changedWidth(String before, String after) {
  final a = before.split('\n');
  final b = after.split('\n');
  var head = 0;
  while (head < a.length && head < b.length && a[head] == b[head]) {
    head++;
  }
  var tail = 0;
  while (tail < a.length - head &&
      tail < b.length - head &&
      a[a.length - 1 - tail] == b[b.length - 1 - tail]) {
    tail++;
  }
  final left = a.length - head - tail;
  final right = b.length - head - tail;
  return left > right ? left : right;
}

/// The settings footer of [text], from its marker to the end.
String footerOf(String text) => text.substring(text.indexOf('%% kanban'));

void main() {
  group('moveCard', () {
    test('to the end of another column, before its trailing blank line', () {
      final out = moveCard(
        issueBoard,
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 1,
      );
      expect(
        out,
        '---\n'
        'type: kanban\n'
        '---\n'
        '## To do\n'
        '- [ ] Book the venue due:2026-11-10\n'
        '\n'
        '## Doing\n'
        '- [ ] Draft the slides\n'
        '  Outline first, then visuals.\n'
        '- [ ] Write the brief #work\n'
        '\n'
        '## Done\n'
        '- [x] Pick the date\n',
      );
    });

    test('to the top of another column', () {
      final out = moveCard(
        issueBoard,
        fromColumn: 2,
        fromCard: 0,
        toColumn: 0,
        toIndex: 0,
      );
      expect(
        out,
        '---\n'
        'type: kanban\n'
        '---\n'
        '## To do\n'
        '- [x] Pick the date\n'
        '- [ ] Write the brief #work\n'
        '- [ ] Book the venue due:2026-11-10\n'
        '\n'
        '## Doing\n'
        '- [ ] Draft the slides\n'
        '  Outline first, then visuals.\n'
        '\n'
        '## Done\n',
      );
    });

    test('to the middle of another column', () {
      final out = moveCard(
        issueBoard,
        fromColumn: 1,
        fromCard: 0,
        toColumn: 0,
        toIndex: 1,
      );
      expect(
        out,
        '---\n'
        'type: kanban\n'
        '---\n'
        '## To do\n'
        '- [ ] Write the brief #work\n'
        '- [ ] Draft the slides\n'
        '  Outline first, then visuals.\n'
        '- [ ] Book the venue due:2026-11-10\n'
        '\n'
        '## Doing\n'
        '\n'
        '## Done\n'
        '- [x] Pick the date\n',
      );
    });

    test('into an empty column: right under its heading', () {
      final out = moveCard(
        '## A\n- a\n\n## B\n\n## C\n- c\n',
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 0,
      );
      expect(out, '## A\n\n## B\n- a\n\n## C\n- c\n');
    });

    test('into an empty column that ends the note', () {
      final out = moveCard(
        '## A\n- a\n- b\n\n## B\n',
        fromColumn: 0,
        fromCard: 1,
        toColumn: 1,
        toIndex: 0,
      );
      expect(out, '## A\n- a\n\n## B\n- b\n');
    });

    test('into an empty column with no blank line before the next one', () {
      final out = moveCard(
        '## A\n- a\n## B\n## C\n',
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 0,
      );
      expect(out, '## A\n## B\n- a\n## C\n');
    });

    test('a column left empty keeps its heading and its blank line', () {
      final out = moveCard(
        '## A\n- a\n\n## B\n- b\n',
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 1,
      );
      expect(out, '## A\n\n## B\n- b\n- a\n');
    });

    test('within a column: down, up and to the end', () {
      const text = '## A\n- a\n- b\n- c\n\n## B\n- x\n';
      String move(int from, int to) => moveCard(
        text,
        fromColumn: 0,
        fromCard: from,
        toColumn: 0,
        toIndex: to,
      );
      expect(move(0, 1), '## A\n- b\n- a\n- c\n\n## B\n- x\n');
      expect(move(0, 2), '## A\n- b\n- c\n- a\n\n## B\n- x\n');
      expect(move(2, 0), '## A\n- c\n- a\n- b\n\n## B\n- x\n');
      expect(move(2, 1), '## A\n- a\n- c\n- b\n\n## B\n- x\n');
      expect(move(1, 2), '## A\n- a\n- c\n- b\n\n## B\n- x\n');
      expect(move(1, 0), '## A\n- b\n- a\n- c\n\n## B\n- x\n');
    });

    test('within a column: a card put where it is leaves the text alone', () {
      for (var i = 0; i < 2; i++) {
        const text = '## A\n- a\nprose\n- b\n';
        final out = moveCard(
          text,
          fromColumn: 0,
          fromCard: i,
          toColumn: 0,
          toIndex: i,
        );
        expect(out, same(text));
      }
    });

    test('within a column: the body goes with the card', () {
      final out = moveCard(
        '## A\n- a\n  body a\n  - nested\n- b\n  body b\n',
        fromColumn: 0,
        fromCard: 0,
        toColumn: 0,
        toIndex: 1,
      );
      expect(out, '## A\n- b\n  body b\n- a\n  body a\n  - nested\n');
    });

    test('prose between cards stays where it is', () {
      final out = moveCard(
        '## A\n- a\nprose\n- b\n',
        fromColumn: 0,
        fromCard: 1,
        toColumn: 0,
        toIndex: 0,
      );
      expect(out, '## A\n- b\n- a\nprose\n');
    });

    test('a moved card is indented like the destination first card', () {
      final out = moveCard(
        '## A\n- a\n  body\n\n## B\n  - b\n',
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 0,
      );
      expect(out, '## A\n\n## B\n  - a\n    body\n  - b\n');
    });

    test('a moved card is dedented to the destination first card', () {
      final out = moveCard(
        '## A\n  - a\n    body\n\n## B\n- b\n',
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 1,
      );
      expect(out, '## A\n\n## B\n- b\n- a\n  body\n');
    });

    test('a moved card keeps its bytes apart from leading spaces', () {
      const card = '- [x] A #tag due:2026-01-02 \t [[link]] éè \n';
      final out = moveCard(
        '## A\n$card\n## B\n- b\n',
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 0,
      );
      expect(out, '## A\n\n## B\n$card- b\n');
    });

    test('a CRLF board stays CRLF, line by line', () {
      final out = moveCard(
        crlf(issueBoard),
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 1,
      );
      expect(
        out,
        crlf(
          moveCard(
            issueBoard,
            fromColumn: 0,
            fromCard: 0,
            toColumn: 1,
            toIndex: 1,
          ),
        ),
      );
    });

    test('a note without a final newline ends the way it did', () {
      expect(
        moveCard(
          '## A\n- a\n## B',
          fromColumn: 0,
          fromCard: 0,
          toColumn: 1,
          toIndex: 0,
        ),
        '## A\n## B\n- a',
      );
      expect(
        moveCard(
          '## A\n- a\n## B\n- b',
          fromColumn: 0,
          fromCard: 0,
          toColumn: 1,
          toIndex: 1,
        ),
        '## A\n## B\n- b\n- a',
      );
      expect(
        moveCard(
          '## A\r\n- a\r\n## B\r\n- b',
          fromColumn: 0,
          fromCard: 0,
          toColumn: 1,
          toIndex: 1,
        ),
        '## A\r\n## B\r\n- b\r\n- a',
      );
      expect(
        moveCard(
          '## A\r\n- a\r\n- z\r\n## B\r\n- b',
          fromColumn: 1,
          fromCard: 0,
          toColumn: 0,
          toIndex: 2,
        ),
        '## A\r\n- a\r\n- z\r\n- b\r\n## B',
      );
    });

    test('the settings footer stays last and untouched', () {
      final footer = footerOf(obsidianBoard);
      for (var from = 0; from < 3; from++) {
        final board = parseKanban(obsidianBoard);
        for (var to = 0; to < 3; to++) {
          for (var card = 0; card < board.columns[from].cards.length; card++) {
            final others =
                board.columns[to].cards.length - (from == to ? 1 : 0);
            for (var at = 0; at <= others; at++) {
              final out = moveCard(
                obsidianBoard,
                fromColumn: from,
                fromCard: card,
                toColumn: to,
                toIndex: at,
              );
              expect(footerOf(out), footer);
              expect(parseKanban(out).settingsLine, isNotNull);
            }
          }
        }
      }
    });

    test('into the last column of an Obsidian board: before the blanks', () {
      final out = moveCard(
        obsidianBoard,
        fromColumn: 0,
        fromCard: 0,
        toColumn: 2,
        toIndex: 1,
      );
      expect(
        out,
        obsidianBoard
            .replaceFirst('- [ ] Write the brief #work\n', '')
            .replaceFirst(
              '- [x] Pick the date\n',
              '- [x] Pick the date\n- [ ] Write the brief #work\n',
            ),
      );
    });

    test('an Obsidian tab-indented body goes with its card', () {
      final out = moveCard(
        obsidianBoard,
        fromColumn: 1,
        fromCard: 0,
        toColumn: 0,
        toIndex: 0,
      );
      expect(out, contains('## To do\n\n'));
      expect(
        out,
        contains(
          '- [ ] Draft the slides\n\tOutline first, then visuals.\n'
          '- [ ] Write the brief',
        ),
      );
    });

    test('rewrites only the lines it moves', () {
      final out = moveCard(
        issueBoard,
        fromColumn: 0,
        fromCard: 0,
        toColumn: 2,
        toIndex: 1,
      );
      // The card and the lines it crossed: nothing before it, nothing after.
      expect(changedWidth(issueBoard, out), lessThanOrEqualTo(9));
      expect(out.split('\n').length, issueBoard.split('\n').length);
      expect(
        out.split('\n')..sort(),
        issueBoard.split('\n')..sort(),
        reason: 'the same lines, only in another order',
      );
    });

    test('moving a card away and back restores the text', () {
      for (final text in <String>[
        issueBoard,
        crlf(issueBoard),
        '## A\n- a\n- b\n  body\n\n## B\n- c\n',
      ]) {
        final board = parseKanban(text);
        for (var from = 0; from < board.columns.length; from++) {
          for (var card = 0; card < board.columns[from].cards.length; card++) {
            for (var to = 0; to < board.columns.length; to++) {
              if (to == from) continue;
              final away = moveCard(
                text,
                fromColumn: from,
                fromCard: card,
                toColumn: to,
                toIndex: board.columns[to].cards.length,
              );
              final back = moveCard(
                away,
                fromColumn: to,
                fromCard: board.columns[to].cards.length,
                toColumn: from,
                toIndex: card,
              );
              expect(back, text, reason: 'column $from card $card to $to');
            }
          }
        }
      }
    });

    test('out of range indexes throw', () {
      void move(int fc, int fk, int tc, int ti) => moveCard(
        issueBoard,
        fromColumn: fc,
        fromCard: fk,
        toColumn: tc,
        toIndex: ti,
      );
      expect(() => move(3, 0, 0, 0), throwsRangeError);
      expect(() => move(-1, 0, 0, 0), throwsRangeError);
      expect(() => move(0, 2, 0, 0), throwsRangeError);
      expect(() => move(0, 0, 3, 0), throwsRangeError);
      expect(() => move(0, 0, 1, 2), throwsRangeError);
      expect(() => move(0, 0, 1, -1), throwsRangeError);
      expect(() => move(0, 0, 0, 2), throwsRangeError);
    });
  });

  group('addCard', () {
    test('goes at the end of the column, before its blank line', () {
      final out = addCard(issueBoard, 0, 'Call the caterer');
      expect(
        out,
        '---\n'
        'type: kanban\n'
        '---\n'
        '## To do\n'
        '- [ ] Write the brief #work\n'
        '- [ ] Book the venue due:2026-11-10\n'
        '- [ ] Call the caterer\n'
        '\n'
        '## Doing\n'
        '- [ ] Draft the slides\n'
        '  Outline first, then visuals.\n'
        '\n'
        '## Done\n'
        '- [x] Pick the date\n',
      );
    });

    test('goes after the body of the last card', () {
      final out = addCard(issueBoard, 1, 'Next');
      expect(
        out,
        contains(
          '- [ ] Draft the slides\n  Outline first, then visuals.\n'
          '- [ ] Next\n\n## Done',
        ),
      );
    });

    test('goes right under the heading of an empty column', () {
      expect(addCard('## A\n\n## B\n', 0, 'x'), '## A\n- [ ] x\n\n## B\n');
      expect(addCard('## A\n\n## B\n', 1, 'x'), '## A\n\n## B\n- [ ] x\n');
      expect(addCard('## A\n## B\n', 0, 'x'), '## A\n- [ ] x\n## B\n');
    });

    test('goes at a given index', () {
      const text = '## A\n- a\nprose\n- b\n';
      expect(
        addCard(text, 0, 'n', index: 0),
        '## A\n- [ ] n\n- a\nprose\n- b\n',
      );
      expect(
        addCard(text, 0, 'n', index: 1),
        '## A\n- a\nprose\n- [ ] n\n- b\n',
      );
      expect(
        addCard(text, 0, 'n', index: 2),
        '## A\n- a\nprose\n- b\n- [ ] n\n',
      );
    });

    test('is indented like the first card of the column', () {
      expect(addCard('## A\n  - a\n', 0, 'x'), '## A\n  - a\n  - [ ] x\n');
    });

    test('a title is one trimmed line', () {
      expect(addCard('## A\n', 0, '  one\r\n two \n'), '## A\n- [ ] one two\n');
    });

    test('a blank title adds nothing', () {
      expect(addCard(issueBoard, 0, '  \n '), same(issueBoard));
      expect(addCard(issueBoard, 0, ''), same(issueBoard));
    });

    test('in a CRLF note the new line has the note ending', () {
      expect(addCard('## A\r\n- a\r\n', 0, 'x'), '## A\r\n- a\r\n- [ ] x\r\n');
    });

    test('in a note without a final newline', () {
      expect(addCard('## A\n- a', 0, 'x'), '## A\n- a\n- [ ] x');
      expect(addCard('## A\r\n- a', 0, 'x'), '## A\r\n- a\r\n- [ ] x');
      expect(addCard('## A', 0, 'x'), '## A\n- [ ] x');
    });

    test('in the last column of an Obsidian board: footer untouched', () {
      final out = addCard(obsidianBoard, 2, 'New');
      expect(footerOf(out), footerOf(obsidianBoard));
      expect(
        out,
        obsidianBoard.replaceFirst(
          '- [x] Pick the date\n',
          '- [x] Pick the date\n- [ ] New\n',
        ),
      );
    });

    test('rewrites no line but the new one', () {
      final out = addCard(issueBoard, 1, 'x');
      expect(changedWidth(issueBoard, out), 1);
      expect(out.split('\n').length, issueBoard.split('\n').length + 1);
    });

    test('out of range throws', () {
      expect(() => addCard(issueBoard, 3, 'x'), throwsRangeError);
      expect(() => addCard(issueBoard, 0, 'x', index: 3), throwsRangeError);
      expect(() => addCard(issueBoard, 0, 'x', index: -1), throwsRangeError);
    });
  });

  group('editCardTitle', () {
    test('keeps the marker, the box and the indent', () {
      expect(
        editCardTitle('## A\n - [x] old\n', 0, 0, 'new'),
        '## A\n - [x] new\n',
      );
      expect(editCardTitle('## A\n* old\n', 0, 0, 'new'), '## A\n* new\n');
      expect(
        editCardTitle('## A\n+ [ ] old\n', 0, 0, 'new'),
        '## A\n+ [ ] new\n',
      );
    });

    test('keeps the spaces after the marker', () {
      expect(editCardTitle('## A\n-   old\n', 0, 0, 'new'), '## A\n-   new\n');
    });

    test('leaves the body and every other line alone', () {
      final out = editCardTitle(issueBoard, 1, 0, 'Redo the slides');
      expect(
        out,
        issueBoard.replaceFirst('Draft the slides', 'Redo the slides'),
      );
      expect(changedWidth(issueBoard, out), 1);
    });

    test('writes the title of a card whose line ends at the box', () {
      expect(editCardTitle('## A\n- [ ]\n', 0, 0, 'x'), '## A\n- [ ] x\n');
      expect(editCardTitle('## A\n-\n', 0, 0, 'x'), '## A\n- x\n');
    });

    test('a blank title clears it', () {
      expect(editCardTitle('## A\n- [ ] old\n', 0, 0, '  '), '## A\n- [ ]\n');
      expect(editCardTitle('## A\n- old\n', 0, 0, ''), '## A\n-\n');
    });

    test('the same title is no edit, whitespace and all', () {
      const text = '## A\n- [ ]   old  \n';
      expect(editCardTitle(text, 0, 0, 'old'), same(text));
      expect(editCardTitle(text, 0, 0, ' old\n'), same(text));
    });

    test('a title is one line', () {
      expect(editCardTitle('## A\n- old\n', 0, 0, 'a\nb'), '## A\n- a b\n');
    });

    test(r'keeps the \r of a CRLF line', () {
      expect(
        editCardTitle('## A\r\n- [ ] old\r\n- b\r\n', 0, 0, 'new'),
        '## A\r\n- [ ] new\r\n- b\r\n',
      );
    });

    test('the last line of a note without a final newline', () {
      expect(editCardTitle('## A\n- old', 0, 0, 'new'), '## A\n- new');
      expect(editCardTitle('## A\r\n- old', 0, 0, 'new'), '## A\r\n- new');
    });

    test('keeps the settings footer', () {
      final out = editCardTitle(obsidianBoard, 2, 0, 'Picked');
      expect(footerOf(out), footerOf(obsidianBoard));
      expect(out, obsidianBoard.replaceFirst('Pick the date', 'Picked'));
    });

    test('out of range throws', () {
      expect(() => editCardTitle(issueBoard, 0, 2, 'x'), throwsRangeError);
      expect(() => editCardTitle(issueBoard, 5, 0, 'x'), throwsRangeError);
    });
  });

  group('toggleCard', () {
    test('ticks and unticks a box, changing that one character', () {
      final ticked = toggleCard(issueBoard, 0, 0);
      expect(
        ticked,
        issueBoard.replaceFirst(
          '- [ ] Write the brief',
          '- [x] Write the brief',
        ),
      );
      expect(toggleCard(ticked, 0, 0), issueBoard);
      expect(
        toggleCard(issueBoard, 2, 0),
        issueBoard.replaceFirst('- [x] Pick', '- [ ] Pick'),
      );
    });

    test('an uppercase X unticks', () {
      expect(toggleCard('## A\n- [X] a\n', 0, 0), '## A\n- [ ] a\n');
    });

    test('a card without a box is left alone', () {
      const text = '## A\n- plain\n';
      expect(toggleCard(text, 0, 0), same(text));
    });

    test('keeps a CRLF line and an indent', () {
      expect(toggleCard('## A\r\n - [ ] a\r\n', 0, 0), '## A\r\n - [x] a\r\n');
    });

    test('a note without a final newline', () {
      expect(toggleCard('## A\n- [ ] a', 0, 0), '## A\n- [x] a');
    });

    test('keeps the settings footer', () {
      final out = toggleCard(obsidianBoard, 0, 1);
      expect(footerOf(out), footerOf(obsidianBoard));
      expect(changedWidth(obsidianBoard, out), 1);
    });

    test('out of range throws', () {
      expect(() => toggleCard(issueBoard, 0, 9), throwsRangeError);
    });
  });

  group('deleteCard', () {
    test('removes the card and its body, nothing else', () {
      final out = deleteCard(issueBoard, 1, 0);
      expect(
        out,
        '---\n'
        'type: kanban\n'
        '---\n'
        '## To do\n'
        '- [ ] Write the brief #work\n'
        '- [ ] Book the venue due:2026-11-10\n'
        '\n'
        '## Doing\n'
        '\n'
        '## Done\n'
        '- [x] Pick the date\n',
      );
    });

    test('removes one card of several', () {
      expect(
        deleteCard('## A\n- a\n- b\n  body\n- c\n', 0, 1),
        '## A\n- a\n- c\n',
      );
    });

    test('keeps the prose and blank lines around it', () {
      expect(
        deleteCard('## A\n- a\n\nprose\n\n- b\n', 0, 0),
        '## A\n\nprose\n\n- b\n',
      );
    });

    test('the last line of a note without a final newline', () {
      expect(deleteCard('## A\n- a\n- b', 0, 1), '## A\n- a');
      expect(deleteCard('## A\r\n- a\r\n- b', 0, 1), '## A\r\n- a');
    });

    test('a CRLF board', () {
      expect(
        deleteCard(crlf(issueBoard), 0, 0),
        crlf(deleteCard(issueBoard, 0, 0)),
      );
    });

    test('keeps the settings footer', () {
      final out = deleteCard(obsidianBoard, 2, 0);
      expect(footerOf(out), footerOf(obsidianBoard));
      expect(out, obsidianBoard.replaceFirst('- [x] Pick the date\n', ''));
    });

    test('out of range throws', () {
      expect(() => deleteCard(issueBoard, 0, 2), throwsRangeError);
      expect(() => deleteCard(issueBoard, -1, 0), throwsRangeError);
    });
  });

  group('every edit keeps the untouched lines byte for byte', () {
    test('a ticked, retitled, moved and deleted Obsidian board', () {
      var text = obsidianBoard;
      text = toggleCard(text, 0, 0);
      text = editCardTitle(text, 0, 1, 'Book the hall due:2026-11-11');
      text = moveCard(
        text,
        fromColumn: 1,
        fromCard: 0,
        toColumn: 2,
        toIndex: 0,
      );
      text = addCard(text, 1, 'Fresh');
      text = deleteCard(text, 0, 0);
      expect(footerOf(text), footerOf(obsidianBoard));
      expect(
        text.substring(0, text.indexOf('## To do')),
        obsidianBoard.substring(0, obsidianBoard.indexOf('## To do')),
        reason: 'the frontmatter is not touched',
      );
      final board = parseKanban(text);
      expect(board.columns.map((c) => c.cards.length).toList(), [1, 1, 2]);
      expect(board.columns[2].cards[0].title, 'Draft the slides');
      expect(board.columns[2].cards[0].body, ['Outline first, then visuals.']);
    });

    test('an edit of a board with prose and odd lines keeps them', () {
      const text =
          'Intro\n\n- loose\n\n## A\n- a\n> quote\n1. numbered\n### sub\n- b\n'
          '\n```\n## no\n```\n\n## B\n\n- [ ] c\n';
      final out = toggleCard(text, 1, 0);
      expect(out, text.replaceFirst('- [ ] c', '- [x] c'));
      final moved = moveCard(
        text,
        fromColumn: 0,
        fromCard: 1,
        toColumn: 1,
        toIndex: 0,
      );
      expect(moved.split('\n')..sort(), text.split('\n')..sort());
      expect(parseKanban(moved).columns[1].cards.first.title, 'b');
    });
  });
}
