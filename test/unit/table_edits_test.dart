// A table read from its lines and written back, and the edits its menu
// offers (#261): each one a table and the cell the caret goes to, the
// columns padded as the writer had them or not.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';
import 'package:niman/src/markdown/table/table_edits.dart';

MarkdownTable _table(String text) => MarkdownTable.parse(text.split('\n'))!;

String _lines(TableEdit? edit) => edit!.table.toLines().join('\n');

const String _plain = '| a | b |\n| --- | --- |\n| 1 | 2 |\n| 3 | 4 |';

const String _padded =
    '| name |   n |\n'
    '| ---- | --: |\n'
    '| pera |  10 |\n'
    '| mela |   2 |';

void main() {
  group('reading and writing', () {
    test('an unpadded table comes back as it was', () {
      expect(_table(_plain).toLines().join('\n'), _plain);
      expect(_table(_plain).padded, isFalse);
    });

    test('a padded table is seen as padded and comes back padded', () {
      final table = _table('| name | n  |\n| ---- | -- |\n| pera | 10 |');
      expect(table.padded, isTrue);
      expect(
        table.toLines().join('\n'),
        '| name | n   |\n| ---- | --- |\n| pera | 10  |',
        reason: 'a delimiter cell is three dashes at least',
      );
    });

    test('alignments are read from the delimiter row', () {
      final table = _table('| a | b | c | d |\n| --- | :-- | :-: | --: |');
      expect(table.aligns, [
        TableAlign.none,
        TableAlign.left,
        TableAlign.center,
        TableAlign.right,
      ]);
    });

    test('an escaped pipe is a cell’s text', () {
      final table = _table('| a \\| b | c |\n| --- | --- |');
      expect(table.header, [r'a \| b', 'c']);
    });

    test('rows short of cells are filled, long ones cut', () {
      final table = _table('| a | b |\n| --- | --- |\n| 1 |\n| 1 | 2 | 3 |');
      expect(table.rows, [
        ['1', ''],
        ['1', '2'],
      ]);
    });

    test('without outer pipes, and indented', () {
      final table = _table('  a | b\n  --- | ---\n  1 | 2');
      expect(table.outerPipes, isFalse);
      expect(table.toLines(), ['  a | b', '  --- | ---', '  1 | 2']);
    });

    test('a table tight against its pipes stays tight', () {
      const compact = '|a|b|\n|---|---|\n|1|2|';
      expect(_table(compact).toLines().join('\n'), compact);
      expect(
        _lines(TableEdits.addRowAtEnd(_table('| a | b |\n|---|---|'))),
        '| a | b |\n|---|---|\n|  |  |',
        reason: 'the rows spaced, the delimiter row tight, each as it was',
      );
    });

    test('not a table', () {
      expect(MarkdownTable.parse(['| a |', 'text']), isNull);
    });
  });

  group('rows', () {
    final table = _table(_plain);

    test('added above and below, the caret in the new row', () {
      final above = TableEdits.addRowAbove(table, (row: 2, column: 1));
      expect(
        _lines(above),
        '| a | b |\n| --- | --- |\n| 1 | 2 |\n|  |  |\n| 3 | 4 |',
      );
      expect(above!.caret, (row: 2, column: 1));
      expect(
        _lines(TableEdits.addRowBelow(table, (row: 0, column: 0))),
        '| a | b |\n| --- | --- |\n|  |  |\n| 1 | 2 |\n| 3 | 4 |',
        reason: 'below the header is the first body row',
      );
      expect(TableEdits.addRowAbove(table, (row: 0, column: 0)), isNull);
    });

    test('moved, duplicated, deleted', () {
      expect(
        _lines(TableEdits.moveRowUp(table, (row: 2, column: 0))),
        '| a | b |\n| --- | --- |\n| 3 | 4 |\n| 1 | 2 |',
      );
      expect(TableEdits.moveRowUp(table, (row: 1, column: 0)), isNull);
      expect(TableEdits.moveRowDown(table, (row: 2, column: 0)), isNull);
      expect(
        _lines(TableEdits.duplicateRow(table, (row: 1, column: 0))),
        '| a | b |\n| --- | --- |\n| 1 | 2 |\n| 1 | 2 |\n| 3 | 4 |',
      );
      final deleted = TableEdits.deleteRow(table, (row: 2, column: 1));
      expect(_lines(deleted), '| a | b |\n| --- | --- |\n| 1 | 2 |');
      expect(deleted!.caret, (row: 1, column: 1));
      expect(TableEdits.deleteRow(table, (row: 0, column: 0)), isNull);
    });

    test('one at the foot', () {
      expect(_lines(TableEdits.addRowAtEnd(table)), '$_plain\n|  |  |');
    });
  });

  group('columns', () {
    final table = _table(_plain);

    test('added left and right, and at the edge', () {
      expect(
        _lines(TableEdits.addColumnLeft(table, (row: 1, column: 0))),
        '|  | a | b |\n| --- | --- | --- |\n|  | 1 | 2 |\n|  | 3 | 4 |',
      );
      final right = TableEdits.addColumnRight(table, (row: 1, column: 0));
      expect(
        _lines(right),
        '| a |  | b |\n| --- | --- | --- |\n| 1 |  | 2 |\n| 3 |  | 4 |',
      );
      expect(right.caret, (row: 1, column: 1));
      expect(
        _lines(TableEdits.addColumnAtEnd(table)),
        '| a | b |  |\n| --- | --- | --- |\n| 1 | 2 |  |\n| 3 | 4 |  |',
      );
    });

    test('moved, duplicated, deleted', () {
      expect(
        _lines(TableEdits.moveColumnRight(table, (row: 0, column: 0))),
        '| b | a |\n| --- | --- |\n| 2 | 1 |\n| 4 | 3 |',
      );
      expect(TableEdits.moveColumnLeft(table, (row: 0, column: 0)), isNull);
      expect(
        _lines(TableEdits.duplicateColumn(table, (row: 0, column: 1))),
        '| a | b | b |\n| --- | --- | --- |\n| 1 | 2 | 2 |\n| 3 | 4 | 4 |',
      );
      final deleted = TableEdits.deleteColumn(table, (row: 1, column: 1));
      expect(_lines(deleted), '| a |\n| --- |\n| 1 |\n| 3 |');
      expect(deleted!.caret, (row: 1, column: 0));
      expect(
        TableEdits.deleteColumn(_table('| a |\n| --- |'), (row: 0, column: 0)),
        isNull,
        reason: 'the only column stays',
      );
    });

    test('aligned: its own dashes change, the others keep theirs', () {
      final table = _table('| a | b |\n| - | -- |');
      expect(
        _lines(
          TableEdits.alignColumn(table, (row: 0, column: 1), TableAlign.center),
        ),
        '| a | b |\n| - | :---: |',
      );
      expect(
        TableEdits.alignColumn(table, (row: 0, column: 0), TableAlign.none),
        isNull,
      );
    });

    test('a padded table stays padded', () {
      final table = _table(_padded);
      expect(table.toLines().join('\n'), _padded);
      expect(
        _lines(
          TableEdits.alignColumn(table, (row: 0, column: 0), TableAlign.right),
        ),
        '| name |   n |\n'
        '| ---: | --: |\n'
        '| pera |  10 |\n'
        '| mela |   2 |',
      );
    });
  });

  group('sort', () {
    test('numbers as numbers, text ignoring case, ties kept in order', () {
      final table = _table(_padded);
      expect(
        _lines(TableEdits.sortByColumn(table, (row: 1, column: 1))),
        '| name |   n |\n| ---- | --: |\n| mela |   2 |\n| pera |  10 |',
      );
      expect(
        _lines(
          TableEdits.sortByColumn(table, (row: 1, column: 0), descending: true),
        ),
        _padded,
      );
      final ties = _table(
        '| a | b |\n| --- | --- |\n| B | 1 |\n| a | 2 |\n| b | 3 |',
      );
      expect(
        _lines(TableEdits.sortByColumn(ties, (row: 1, column: 0))),
        '| a | b |\n| --- | --- |\n| a | 2 |\n| B | 1 |\n| b | 3 |',
      );
    });
  });
}
