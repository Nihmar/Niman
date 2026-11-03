// #1248: cells copied from a spreadsheet, or a CSV file's lines, read as
// a Markdown table — and everything that only looks like one left as text.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/table/clipboard_table.dart';

List<String>? _lines(String text) => tableFromClipboard(text)?.toLines();

void main() {
  test("Excel's copy: tabs, CRLF, a closing newline", () {
    expect(_lines('Name\tQty\r\nApples\t3\r\nPears\t12\r\n'), [
      '| Name | Qty |',
      '| --- | --- |',
      '| Apples | 3 |',
      '| Pears | 12 |',
    ]);
  });

  test('a quoted cell keeps its tab, its newline and its quotes', () {
    expect(_lines('A\tB\n"one\ttwo"\t"line 1\nline 2 ""q"""\n'), [
      '| A | B |',
      '| --- | --- |',
      '| one\ttwo | line 1<br>line 2 "q" |',
    ]);
  });

  test('a pipe in a cell is escaped; an empty cell stays a cell', () {
    expect(_lines('x\ty\na|b\t\n'), [
      '| x | y |',
      '| --- | --- |',
      r'| a\|b |  |',
    ]);
  });

  test('a short tab-separated row is filled', () {
    expect(_lines('a\tb\tc\n1\t2\n'), [
      '| a | b | c |',
      '| --- | --- | --- |',
      '| 1 | 2 |  |',
    ]);
  });

  test("a CSV file's lines, quotes and commas inside them", () {
    expect(_lines('city,"pop, 2020"\nRome,"2,8M"\n"He said ""hi""",1\n'), [
      '| city | pop, 2020 |',
      '| --- | --- |',
      '| Rome | 2,8M |',
      '| He said "hi" | 1 |',
    ]);
  });

  test('semicolons, where the comma is the decimal mark', () {
    expect(_lines('nome;prezzo\npane;1,20\n'), [
      '| nome | prezzo |',
      '| --- | --- |',
      '| pane | 1,20 |',
    ]);
  });

  group('left as text', () {
    for (final (what, text) in [
      ('one line of cells', 'a\tb\tc'),
      ('one column', 'a\nb\nc\n'),
      ('prose with commas', 'Hello, world.\nYes, again.\n'),
      ('an argument list', 'f(a, b)\ng(c, d)\n'),
      ('ragged CSV', 'a,b,c\n1,2\n'),
      ('a line without a tab after the cells', 'a\tb\n1\t2\nnotes\n'),
      ('tab-indented code', '\tif (x)\n\t\treturn;\n'),
      ('an unclosed quote', 'a,"b\nc,d\n'),
      ('plain text', 'just a sentence'),
      ('nothing', ''),
    ]) {
      test(what, () => expect(tableFromClipboard(text), isNull));
    }
  });
}
