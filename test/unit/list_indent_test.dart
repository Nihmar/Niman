// Tab on a list item nests it under the item above, the way CommonMark reads
// it: an item is inside another only when it is indented to that item's
// content column, which a fixed number of spaces does not reach for `6. `.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_indent.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Runs the indent over [marked], where `|` is the caret (two of them, a
/// selection), and gives the note back with the caret marks where they land.
String _run(String marked, {bool outdent = false, int width = 2}) {
  final text = marked.replaceAll('|', '');
  final marks = <int>[];
  var removed = 0;
  for (var at = 0; at < marked.length; at++) {
    if (marked[at] == '|') {
      marks.add(at - removed);
      removed++;
    }
  }
  final edit = indentLines(
    text: text,
    selection: TextSelection(baseOffset: marks.first, extentOffset: marks.last),
    width: width,
    outdent: outdent,
  );
  final base = edit.selection.baseOffset;
  final extent = edit.selection.extentOffset;
  final at = <int>{base, extent}.toList()..sort();
  var result = edit.text;
  for (var n = at.length - 1; n >= 0; n--) {
    result = result.replaceRange(at[n], at[n], '|');
  }
  return result;
}

/// Where the scanner the read and live views draw from puts each item of
/// [document]: how deep, and which one of its list it is.
List<(int, int)> _places(String document) {
  final buffer = SourceBuffer.fromText(document);
  return [
    for (final block in BlockScanner(buffer).index.blocks)
      (block.listDepth, block.listOrdinal),
  ];
}

void main() {
  group('indent', () {
    test('the reported note: a nested ordered item starts at 1', () {
      expect(
        _run('6. se dati coerenti\n7. te|st\n8. vzsfv'),
        '6. se dati coerenti\n   1. te|st\n7. vzsfv',
      );
    });

    test('the item is under 6. in the block tree, and was not before', () {
      expect(_places('6. se dati\n  7. test\n8. vzsfv'), [
        (0, 6),
        (0, 7),
        (0, 8),
      ], reason: 'two spaces nest nothing under 6.');
      final note = _run('6. se dati\n7. te|st\n8. vzsfv').replaceAll('|', '');
      expect(_places(note), [(0, 6), (1, 1), (0, 7)], reason: note);
    });

    test('a two-digit parent takes four spaces', () {
      expect(_run('10. a\n11. b|'), '10. a\n    1. b|');
    });

    test('a bulleted parent takes two, and the bullet stays', () {
      expect(_run('- a\n- b|'), '- a\n  - b|');
      expect(_run('* a\n* b|'), '* a\n  * b|');
    });

    test('a task parent: the box is not part of the marker', () {
      expect(_run('- [ ] a\n- [ ] b|'), '- [ ] a\n  - [ ] b|');
    });

    test('an ordered item under a bullet starts a numbered sublist', () {
      expect(_run('- a\n5. b|'), '- a\n  1. b|');
    });

    test('a sublist already open is continued', () {
      expect(
        _run('1. a\n   1. x\n   2. y\n2. b|'),
        '1. a\n   1. x\n   2. y\n   3. b|',
      );
    });

    test('the delimiter of the sublist it joins is kept', () {
      expect(_run('1. a\n   1) x\n2. b|'), '1. a\n   1) x\n   2) b|');
    });

    test('the subtree and the lines under the item move with it', () {
      expect(
        _run('- a\n- b|\n  c\n  - d\n    - e\n- f'),
        '- a\n  - b|\n    c\n    - d\n      - e\n- f',
      );
    });

    test('an ordered item with children keeps them nested', () {
      expect(
        _run('1. a\n2. b|\n   - c\n3. d'),
        '1. a\n   1. b|\n      - c\n2. d',
      );
    });

    test('the siblings left behind close up, while counted in order', () {
      expect(_run('1. a\n2. b|\n3. c\n4. d'), '1. a\n   1. b|\n2. c\n3. d');
      expect(
        _run('1. a\n2. b|\n3. c\n7. d'),
        '1. a\n   1. b|\n2. c\n7. d',
        reason: 'a number written on purpose is left',
      );
      expect(
        _run('1. a\n5. b|\n6. c'),
        '1. a\n   1. b|\n6. c',
        reason: 'a list not counted in order is not touched',
      );
    });

    test('a selection of several items moves them together', () {
      expect(
        _run('1. a\n2. |b\n3. c|\n4. d'),
        '1. a\n   1. |b\n   2. c|\n2. d',
      );
      expect(_run('- a\n- |b\n- c|\n- d'), '- a\n  - |b\n  - c|\n- d');
    });

    test('a selection over an item and its child keeps their shape', () {
      expect(_run('- a\n- |b\n  - c|\n- d'), '- a\n  - |b\n    - c|\n- d');
    });

    test('the first item has nothing to nest under: it moves by the width', () {
      expect(_run('- a|\n- b'), '  - a|\n- b');
      expect(_run('1. a|', width: 4), '    1. a|');
    });

    test('a line that is not an item moves by the width, as ever', () {
      expect(_run('plain|'), '  plain|');
      expect(_run('plain|', width: 4), '    plain|');
      expect(_run('a\n|b\nc|'), 'a\n  |b\n  c|');
      expect(_run('    x|', outdent: true), '  x|');
      expect(_run(' x|', outdent: true), 'x|');
      expect(_run('x|', outdent: true), 'x|');
    });

    test('an item in a quote nests inside the quote', () {
      expect(_run('> - a\n> - b|'), '> - a\n>   - b|');
      expect(_run('> 1. a\n> 2. b|'), '> 1. a\n>    1. b|');
    });

    test('a quote does not nest under a list outside it', () {
      expect(_run('- a\n> - b|'), '- a\n>   - b|');
    });

    test('a CRLF note keeps its line ends', () {
      expect(_run('6. a\r\n7. b|\r\n8. c'), '6. a\r\n   1. b|\r\n7. c');
    });

    test('a paragraph above the list ends the walk up', () {
      expect(_run('text\n- a\n- b|'), 'text\n- a\n  - b|');
      expect(_run('- a\n\ntext\n- b|'), '- a\n\ntext\n  - b|');
    });

    test('a loose list is nested across its blank lines', () {
      expect(_run('- a\n\n- b|'), '- a\n\n  - b|');
    });
  });

  group('the caret', () {
    test('stays on the same text after the marker', () {
      expect(_run('1. a\n2. |b'), '1. a\n   1. |b');
      expect(_run('1. a\n2. b|'), '1. a\n   1. b|');
    });

    test('an empty item keeps the caret after its marker, ready to type', () {
      // Enter on `6. foo` makes `7. `; Tab there makes `1. ` under 6.
      expect(_run('6. foo\n7. |'), '6. foo\n   1. |');
      expect(_run('6. foo\n7.|'), '6. foo\n   1.|');
      expect(_run('- foo\n- |'), '- foo\n  - |');
      expect(_run('- foo\n- [ ] |'), '- foo\n  - [ ] |');
    });

    test('a caret inside the marker lands inside the new one', () {
      expect(_run('6. a\n7|. b'), '6. a\n   1|. b');
      expect(_run('6. a\n|7. b'), '6. a\n   |1. b');
    });

    test('every end of a selection moves with its own text', () {
      expect(
        _run('1. a\n2. |b\n3. c\n4. d|'),
        '1. a\n   1. |b\n   2. c\n   3. d|',
      );
    });
  });

  group('outdent', () {
    test('goes back to the parent, as the next of its list', () {
      expect(
        _run('6. a\n   1. te|st\n7. v', outdent: true),
        '6. a\n7. te|st\n8. v',
      );
    });

    test('is the inverse of indent', () {
      const note = '6. a\n7. te|st\n8. v';
      final nested = _run(note);
      expect(_run(nested, outdent: true), '6. a\n7. te|st\n8. v');
    });

    test('a bullet goes back to its parent bullet', () {
      expect(_run('- a\n  - b|', outdent: true), '- a\n- b|');
    });

    test('an ordered item in a bullet list keeps its number', () {
      expect(_run('- a\n  3. b|', outdent: true), '- a\n3. b|');
    });

    test('the subtree goes with it', () {
      expect(
        _run('- a\n  - b|\n    c\n    - d', outdent: true),
        '- a\n- b|\n  c\n  - d',
      );
    });

    test('several items go back together, numbered in turn', () {
      expect(
        _run('1. a\n   1. |b\n   2. c|\n2. d', outdent: true),
        '1. a\n2. |b\n3. c|\n4. d',
      );
    });

    test('an item with no parent loses up to the width of its indent', () {
      expect(_run('  7. t|', outdent: true), '7. t|');
      expect(_run('7. t|', outdent: true), '7. t|');
    });

    test('a mis-indented item (the old two spaces) is brought back', () {
      expect(_run('6. a\n  7. t|\n8. v', outdent: true), '6. a\n7. t|\n8. v');
    });
  });
}
