// Tab and Shift+Tab over a buffer (`listIndentEdit`): the edit the source
// editor makes, held to the answer of `indentLines` over the whole note
// (#1345, #1355).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_indent.dart';
import 'package:niman/src/markdown/edit/list_indent_edit.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where the `|` marks of [marked] are, and the note without them: one mark
/// is a caret, two a selection from the first to the second.
({String text, SelectionModel selection}) _read(String marked) {
  final marks = <int>[];
  var removed = 0;
  for (var at = 0; at < marked.length; at++) {
    if (marked[at] == '|') marks.add(at - removed++);
  }
  return (
    text: marked.replaceAll('|', ''),
    selection: SelectionModel(anchor: marks.first, extent: marks.last),
  );
}

/// [text] with `|` where [selection] has its ends.
String _mark(String text, SelectionModel selection) {
  final at = <int>{selection.anchor, selection.extent}.toList()..sort();
  var marked = text;
  for (var n = at.length - 1; n >= 0; n--) {
    marked = marked.replaceRange(at[n], at[n], '|');
  }
  return marked;
}

/// What Tab (or Shift+Tab, [outdent]) makes of [marked]: the note and the
/// selection after it, marked again; the note as it was when there is no edit.
String _press(String marked, {bool outdent = false, int width = 2}) {
  final read = _read(marked);
  final buffer = SourceBuffer.fromText(read.text);
  final edit = listIndentEdit(
    buffer,
    read.selection,
    width: width,
    outdent: outdent,
  );
  if (edit == null) return marked;
  buffer.replaceRange(edit.start, edit.end, edit.text, verbatim: true);
  return _mark(buffer.text, edit.caret);
}

/// The same press over the whole note by `indentLines`.
String _whole(String marked, {bool outdent = false, int width = 2}) {
  final read = _read(marked);
  final edit = indentLines(
    text: read.text,
    selection: TextSelection(
      baseOffset: read.selection.anchor,
      extentOffset: read.selection.extent,
    ),
    width: width,
    outdent: outdent,
  );
  return _mark(
    edit.text,
    SelectionModel(
      anchor: edit.selection.baseOffset,
      extent: edit.selection.extentOffset,
    ),
  );
}

void main() {
  group('a selection that ends at the start of a line stops before it', () {
    test('the line below is not indented', () {
      expect(_press('|a\nb\n|c'), '  |a\n  b\n|c');
      expect(_whole('|a\nb\n|c'), '  |a\n  b\n|c');
    });

    test('and is not outdented', () {
      expect(_press('|  a\n  b\n|  c', outdent: true), '|a\nb\n|  c');
      expect(_whole('|  a\n  b\n|  c', outdent: true), '|a\nb\n|  c');
    });

    test('a list item below keeps its place', () {
      expect(_press('- a\n|- b\n|- c'), '- a\n  |- b\n|- c');
    });

    test('a selection ending at column 0 of a line outside what changes', () {
      expect(_press('|a\n|\n\nb'), '  |a\n|\n\nb');
    });

    test('a collapsed caret at the start of a line touches that line', () {
      expect(_press('a\n|b'), 'a\n  |b');
    });

    test('a range that starts at a line end and stops at the next start', () {
      expect(_press('a|\n|b'), '  a|\n|b');
    });
  });

  group('blank lines are not padded (#1345)', () {
    test('a plain blank line among the lines stays empty', () {
      expect(_press('|a\n\nb|'), '  |a\n\n  b|');
      expect(_whole('|a\n\nb|'), '  |a\n\n  b|');
    });

    test('a line of spaces only is not given more', () {
      expect(_press('|a\n  \nb|'), '  |a\n  \n  b|');
    });

    test('and outdent takes the spaces off it', () {
      expect(_press('|  a\n  \n  b|', outdent: true), '|a\n\nb|');
    });

    test('a blank line among items and their text', () {
      expect(_press('|- a\n\n  more\n- b|'), '  |- a\n\n    more\n  - b|');
    });
  });
}
