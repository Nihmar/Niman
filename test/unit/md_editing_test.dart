// T-UI-08 AC: wrap-selection, empty-selection (markers at the caret), and
// list/quote prefixing per line.
import 'package:copist/src/editor/md_editing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
