// #1154: the kanban column edits — add, rename, delete — are byte-stable and
// never reach the Obsidian settings footer.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/card_edits.dart';
import 'package:niman/src/kanban/column_edits.dart';

import '../fakes/kanban_samples.dart';

/// The settings footer of [text], from its marker to the end.
String footerOf(String text) => text.substring(text.indexOf('%% kanban'));

void main() {
  group('addColumn', () {
    test('goes at the end of the board, set off by a blank line', () {
      expect(addColumn(issueBoard, 'Review'), '$issueBoard\n## Review\n');
    });

    test('goes before the settings footer, which stays last', () {
      final out = addColumn(obsidianBoard, 'Review');
      expect(
        out,
        obsidianBoard.replaceFirst(
          '- [x] Pick the date\n',
          '- [x] Pick the date\n\n## Review\n',
        ),
      );
      expect(footerOf(out), footerOf(obsidianBoard));
      final board = parseKanban(out);
      expect(board.columns.map((c) => c.name).toList(), [
        'To do',
        'Doing',
        'Done',
        'Review',
      ]);
      expect(board.columns.last.cards, isEmpty);
    });

    test('a column added after a column added, keeps the order', () {
      var text = addColumn(issueBoard, 'One');
      text = addColumn(text, 'Two');
      expect(parseKanban(text).columns.map((c) => c.name).toList(), [
        'To do',
        'Doing',
        'Done',
        'One',
        'Two',
      ]);
    });

    test('follows the frontmatter directly when the board is empty', () {
      expect(
        addColumn('---\ntype: kanban\n---\n', 'To do'),
        '---\ntype: kanban\n---\n## To do\n',
      );
      expect(
        addColumn('---\ntype: kanban\n---', 'To do'),
        '---\ntype: kanban\n---\n## To do',
      );
    });

    test('in an empty note', () {
      expect(addColumn('', 'To do'), '## To do\n');
    });

    test('after prose and a loose list', () {
      expect(addColumn('intro\n', 'A'), 'intro\n\n## A\n');
      expect(addColumn('- loose\n', 'A'), '- loose\n\n## A\n');
    });

    test('keeps the blank lines that closed the board', () {
      expect(addColumn('## A\n- a\n\n\n', 'B'), '## A\n- a\n\n## B\n\n\n');
    });

    test('in a note without a final newline', () {
      expect(addColumn('## A\n- a', 'B'), '## A\n- a\n\n## B');
      expect(addColumn('## A\r\n- a', 'B'), '## A\r\n- a\r\n\r\n## B');
    });

    test('in a CRLF board the new lines end CRLF', () {
      expect(
        addColumn(crlf(issueBoard), 'Review'),
        crlf(addColumn(issueBoard, 'Review')),
      );
    });

    test('a name is one trimmed line', () {
      expect(addColumn('## A\n', ' B\n C '), '## A\n\n## B C\n');
    });

    test('a blank name adds nothing', () {
      expect(addColumn(issueBoard, ' \n'), same(issueBoard));
    });

    test('rewrites no existing line', () {
      final out = addColumn(issueBoard, 'Review');
      final before = issueBoard.split('\n');
      final after = out.split('\n');
      expect(
        after.sublist(0, before.length - 1),
        before.sublist(0, before.length - 1),
      );
    });
  });

  group('renameColumn', () {
    test('rewrites the heading line only', () {
      expect(
        renameColumn(issueBoard, 1, 'In progress'),
        issueBoard.replaceFirst('## Doing', '## In progress'),
      );
    });

    test('keeps the indent and drops a closing run of #', () {
      expect(renameColumn('  ## Old ##\n- a\n', 0, 'New'), '  ## New\n- a\n');
    });

    test('rewrites the spaces after the ## to one', () {
      expect(renameColumn('##   Old\n', 0, 'New'), '## New\n');
    });

    test('the same name is no edit', () {
      expect(renameColumn(issueBoard, 0, 'To do'), same(issueBoard));
      expect(renameColumn(issueBoard, 0, ' To do '), same(issueBoard));
    });

    test('a blank name is no edit', () {
      expect(renameColumn(issueBoard, 0, '  '), same(issueBoard));
    });

    test('a name is one line', () {
      expect(renameColumn('## A\n', 0, 'B\nC'), '## B C\n');
    });

    test(r'keeps the \r of a CRLF heading', () {
      expect(
        renameColumn(crlf(issueBoard), 0, 'Backlog'),
        crlf(issueBoard).replaceFirst('## To do', '## Backlog'),
      );
    });

    test('a heading on the last line of a note', () {
      expect(renameColumn('## A\n- a\n## B', 1, 'C'), '## A\n- a\n## C');
    });

    test('keeps the settings footer and every card', () {
      final out = renameColumn(obsidianBoard, 2, 'Finished');
      expect(out, obsidianBoard.replaceFirst('## Done', '## Finished'));
      expect(parseKanban(out).columns[2].cards, hasLength(1));
    });

    test('out of range throws', () {
      expect(() => renameColumn(issueBoard, 3, 'x'), throwsRangeError);
      expect(() => renameColumn(issueBoard, -1, 'x'), throwsRangeError);
    });
  });

  group('deleteColumn', () {
    test('removes the heading, the cards and the blank line after them', () {
      expect(
        deleteColumn(issueBoard, 1),
        issueBoard.replaceFirst(
          '## Doing\n- [ ] Draft the slides\n'
              '  Outline first, then visuals.\n\n',
          '',
        ),
      );
    });

    test('the first column', () {
      expect(
        deleteColumn(issueBoard, 0),
        '---\n'
        'type: kanban\n'
        '---\n'
        '## Doing\n'
        '- [ ] Draft the slides\n'
        '  Outline first, then visuals.\n'
        '\n'
        '## Done\n'
        '- [x] Pick the date\n',
      );
    });

    test('the last column', () {
      expect(
        deleteColumn(issueBoard, 2),
        issueBoard.replaceFirst('## Done\n- [x] Pick the date\n', ''),
      );
    });

    test('an empty column', () {
      expect(
        deleteColumn('## A\n- a\n\n## B\n\n## C\n- c\n', 1),
        '## A\n- a\n\n## C\n- c\n',
      );
    });

    test('the only column', () {
      expect(deleteColumn('## A\n- a\n', 0), '');
      expect(
        deleteColumn('---\nt: k\n---\n## A\n- a\n', 0),
        '---\nt: k\n---\n',
      );
    });

    test('the last column of an Obsidian board, lane mark and all', () {
      final out = deleteColumn(obsidianBoard, 2);
      expect(footerOf(out), footerOf(obsidianBoard));
      expect(out, isNot(contains('Complete')));
      expect(out, isNot(contains('Pick the date')));
      final board = parseKanban(out);
      expect(board.columns.map((c) => c.name).toList(), ['To do', 'Doing']);
      expect(board.hasSettings, isTrue);
      expect(
        out,
        obsidianBoard.substring(0, obsidianBoard.indexOf('## Done')) +
            footerOf(obsidianBoard),
      );
    });

    test('a middle column of an Obsidian board', () {
      final out = deleteColumn(obsidianBoard, 1);
      expect(footerOf(out), footerOf(obsidianBoard));
      expect(
        out,
        obsidianBoard.replaceFirst(
          '## Doing\n\n- [ ] Draft the slides\n'
              '\tOutline first, then visuals.\n\n\n',
          '',
        ),
      );
    });

    test('prose between the cards of the column stays', () {
      expect(
        deleteColumn('## A\n- a\nprose\n- b\n\n## B\n- c\n', 0),
        'prose\n\n## B\n- c\n',
      );
    });

    test('headings of other levels and what is fenced inside stay prose', () {
      expect(
        deleteColumn('## A\n- a\n### sub\n```\n## x\n```\n## B\n', 0),
        '### sub\n```\n## x\n```\n## B\n',
      );
    });

    test('a CRLF board', () {
      expect(
        deleteColumn(crlf(issueBoard), 1),
        crlf(deleteColumn(issueBoard, 1)),
      );
    });

    test('a note without a final newline', () {
      expect(deleteColumn('## A\n- a\n## B\n- b', 1), '## A\n- a');
      expect(deleteColumn('## A\r\n- a\r\n## B\r\n- b', 1), '## A\r\n- a');
    });

    test('out of range throws', () {
      expect(() => deleteColumn(issueBoard, 3), throwsRangeError);
    });
  });

  group('columns and cards together', () {
    test('a board built from nothing reads back', () {
      var text = '---\ntype: kanban\n---\n';
      text = addColumn(text, 'To do');
      text = addColumn(text, 'Doing');
      text = addColumn(text, 'Done');
      text = addCard(text, 0, 'First');
      text = addCard(text, 0, 'Second');
      text = moveCard(
        text,
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 0,
      );
      text = toggleCard(text, 1, 0);
      expect(
        text,
        '---\n'
        'type: kanban\n'
        '---\n'
        '## To do\n'
        '- [ ] Second\n'
        '\n'
        '## Doing\n'
        '- [x] First\n'
        '\n'
        '## Done\n',
      );
    });

    test('deleting a column and adding it back leaves the others alone', () {
      final without = deleteColumn(obsidianBoard, 1);
      final back = addColumn(without, 'Doing');
      expect(footerOf(back), footerOf(obsidianBoard));
      expect(parseKanban(back).columns.map((c) => c.name).toList(), [
        'To do',
        'Done',
        'Doing',
      ]);
    });
  });
}
