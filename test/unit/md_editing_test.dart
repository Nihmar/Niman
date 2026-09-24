// T-UI-08 AC: wrap-selection, empty-selection (markers at the caret), and
// list/quote prefixing per line.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/md_editing.dart';

TextSelection _sel(int start, [int? end]) => end == null
    ? TextSelection.collapsed(offset: start)
    : TextSelection(baseOffset: start, extentOffset: end);

void main() {
  group('wrapSelection', () {
    test('wraps a non-empty selection, keeping the inner text selected', () {
      final edit = wrapSelection(
        text: 'hello world',
        selection: _sel(0, 5),
        left: '**',
        right: '**',
      );
      expect(edit.text, '**hello** world');
      expect(edit.selection.start, 2);
      expect(edit.selection.end, 7);
      expect(edit.selection, _sel(2, 7));
    });

    test('collapsed caret: markers inserted, caret between them', () {
      final edit = wrapSelection(
        text: 'ab',
        selection: _sel(1),
        left: '[[',
        right: ']]',
      );
      expect(edit.text, 'a[[]]b');
      expect(edit.selection, _sel(3));
    });

    test('superscript and underline wrap their markers', () {
      final sup = wrapSelection(
        text: 'x2',
        selection: _sel(1),
        left: '<sup>',
        right: '</sup>',
      );
      expect(sup.text, 'x<sup></sup>2');
      expect(sup.selection, _sel(6));
      final under = wrapSelection(
        text: 'ab',
        selection: _sel(0, 2),
        left: '<u>',
        right: '</u>',
      );
      expect(under.text, '<u>ab</u>');
      expect(under.selection, _sel(3, 5));
    });
  });

  group('codeBlock', () {
    test('collapsed caret: fences with the caret on the first line', () {
      final edit = codeBlock(text: 'ab', selection: _sel(1));
      expect(edit.text, 'a```\n\n```b');
      // 1 + length of the opening fence and its newline.
      expect(edit.selection, _sel(5));
    });

    test('a selection is fenced and stays selected', () {
      final edit = codeBlock(text: 'ab\ncd', selection: _sel(0, 5));
      expect(edit.text, '```\nab\ncd\n```');
      expect(edit.selection.start, 4);
      expect(edit.selection.end, 9);
    });
  });

  group('prefixLines', () {
    test('prefixed caret line: the caret follows the prefix', () {
      final edit = prefixLines(text: 'item', selection: _sel(0), prefix: '- ');
      expect(edit.text, '- item');
      expect(edit.selection, _sel(2));
    });

    test('each line of a multi-line selection is prefixed', () {
      final edit = prefixLines(
        text: 'alpha\nbeta\ngamma',
        selection: _sel(0, 10), // 'alpha\nbeta' (the newline included).
        prefix: '> ',
      );
      expect(edit.text, '> alpha\n> beta\ngamma');
      expect(edit.selection.start, 4);
      expect(edit.selection.end, 14);
    });

    test('collapsed caret on an empty line keeps the caret on it', () {
      final edit = prefixLines(
        text: 'a\n\nb',
        selection: _sel(2),
        prefix: '- ',
      );
      expect(edit.text, 'a\n- \nb');
      expect(edit.selection, _sel(4));
    });

    test('quote prefixes a selection that ends mid-line', () {
      final edit = prefixLines(
        text: 'a\nb\nc',
        selection: _sel(0, 3), // 'a\nb' minus the newline.
        prefix: '> ',
      );
      expect(edit.text, '> a\n> b\nc');
      // Two lines prefixed: the selection shifts by 2 x 2.
      expect(edit.selection, _sel(4, 7));
    });
  });

  group('toggleTaskList (#263)', () {
    MarkdownEdit toggle(String text, TextSelection selection) =>
        toggleTaskList(text: text, selection: selection);

    test('a plain line becomes a task, the caret kept on its text', () {
      final edit = toggle('buy milk', _sel(3));
      expect(edit.text, '- [ ] buy milk');
      expect(edit.selection, _sel(9));
    });

    test('a bulleted item gains the box and keeps its marker', () {
      expect(toggle('* one', _sel(0)).text, '* [ ] one');
      expect(toggle('  - nested', _sel(4)).text, '  - [ ] nested');
    });

    test('a numbered item keeps its number', () {
      expect(toggle('3. third', _sel(0)).text, '3. [ ] third');
    });

    test('a task goes back to plain text, ticked or not', () {
      expect(toggle('- [ ] todo', _sel(8)).text, 'todo');
      expect(toggle('  - [x] done', _sel(0)).text, '  done');
    });

    test('several lines: tasks all, blank lines left alone', () {
      final edit = toggle('a\n\n- b\n- [x] c', _sel(0, 13));
      expect(edit.text, '- [ ] a\n\n- [ ] b\n- [x] c');
    });

    test('several lines, all tasks: all back to text', () {
      final edit = toggle('- [ ] a\n- [x] b', _sel(0, 15));
      expect(edit.text, 'a\nb');
    });

    test('an empty line alone becomes an empty task', () {
      expect(toggle('a\n\nb', _sel(2)).text, 'a\n- [ ] \nb');
    });

    test('Enter on a task carries an unticked box on', () {
      expect(listItemHead('- [x] done')!.continuation, '- [ ] ');
      expect(listItemHead('  - [ ] todo')!.continuation, '  - [ ] ');
    });
  });

  group('insertTable (#262)', () {
    const table = '|    |    |\n| --- | --- |\n|    |    |';

    MarkdownEdit insert(String text, int caret) =>
        insertTable(text: text, selection: _sel(caret));

    test('an empty note becomes the table, the caret in its first cell', () {
      final edit = insert('', 0);
      expect(edit.text, table);
      expect(edit.selection, _sel(2));
    });

    test('a blank line is replaced, and kept from its neighbours', () {
      final edit = insert('prima\n\ndopo', 6);
      expect(edit.text, 'prima\n\n$table\n\ndopo');
      expect(edit.selection, _sel('prima\n\n'.length + 2));
    });

    test('a caret in a line puts it below, a blank line between', () {
      final edit = insert('una riga\ndopo', 3);
      expect(edit.text, 'una riga\n\n$table\n\ndopo');
    });

    test('a caret at the start of a line puts it above', () {
      final edit = insert('una riga', 0);
      expect(edit.text, '$table\n\nuna riga');
      expect(edit.selection, _sel(2));
    });

    test('more columns and rows when asked', () {
      final edit = insertTable(
        text: '',
        selection: _sel(0),
        columns: 3,
        rows: 2,
      );
      expect(edit.text.split('\n'), [
        '|    |    |    |',
        '| --- | --- | --- |',
        '|    |    |    |',
        '|    |    |    |',
      ]);
    });
  });

  group('insertSnippet (#265)', () {
    test('one line goes at the caret, over the selection', () {
      final edit = insertSnippet(
        text: 'ab cd',
        selection: _sel(3, 5),
        snippet: '**x**',
      );
      expect(edit.text, 'ab **x**');
      expect(edit.selection, _sel(8));
    });

    test('several go on lines of their own, the caret after them', () {
      final edit = insertSnippet(
        text: 'prima riga',
        selection: _sel(5),
        snippet: '- [ ] a\n- [ ] b',
      );
      expect(edit.text, 'prima riga\n\n- [ ] a\n- [ ] b');
      expect(edit.selection, _sel(edit.text.length));
    });
  });
}
