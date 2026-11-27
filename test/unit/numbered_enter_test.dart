// Enter in the middle of a numbered list renumbers the items after the new
// one that were counted on from it, in the same edit (#1343).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_row.dart';
import 'package:niman/src/editor/list_tree.dart';
import 'package:niman/src/markdown/edit/enter_edit.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Presses Enter at [caret] of [text] and returns the note after it with the
/// caret marked, and how many edits the buffer took for it; null when Enter is
/// the platform's.
({String text, int edits})? _press(String text, int caret) {
  final buffer = SourceBuffer.fromText(text);
  final edit = enterEdit(buffer, caret, indentWidth: 2);
  if (edit == null) return null;
  final before = buffer.length;
  buffer.replaceRange(edit.start, edit.end, edit.text, verbatim: edit.verbatim);
  final stored = buffer.length - before + (edit.end - edit.start);
  final at = edit.caret?.extent ?? edit.start + stored;
  final result = buffer.text;
  return (text: '${result.substring(0, at)}|${result.substring(at)}', edits: 1);
}

/// [marked] (a note with `|` for the caret) after Enter.
String? _enter(String marked) {
  final caret = marked.indexOf('|');
  return _press(marked.replaceFirst('|', ''), caret)?.text;
}

/// What Enter makes of the numbered item on [line] of [lines], by the rule
/// read over the whole note: the item's own line break and marker, then each
/// following sibling that counts on from it one number up. The slow answer the
/// bounded read is held to.
String _wholeNote(List<String> lines, int line, int column, String eol) {
  final rows = [for (final text in lines) ListRow(text)];
  final head = rows[line].head!;
  final counting = ListTree(rows).countingAfter(line);
  final out = <String>[...lines];
  var expected = head.number!;
  for (final at in counting.run) {
    expected += 1;
    final row = rows[at];
    final marker = row.head!.markerFor(expected + 1);
    out[at] =
        '${row.marks}${row.body.substring(0, row.lead)}$marker'
        '${row.body.substring(row.lead + row.head!.marker.length)}';
  }
  final own = lines[line];
  final newItem = '${rows[line].marks}${head.continuation}';
  out[line] = '${own.substring(0, column)}$eol$newItem${own.substring(column)}';
  return out.join(eol);
}

void main() {
  group('the items after the new one count on from it', () {
    for (final (marked, expected) in <(String, String)>[
      ('1. a|\n2. b', '1. a\n2. |\n3. b'),
      ('1. a|\n2. b\n3. c\ntext', '1. a\n2. |\n3. b\n4. c\ntext'),
      ('1. a\n2. b|', '1. a\n2. b\n3. |'),
      ('1. a\n2. b|\n3. c', '1. a\n2. b\n3. |\n4. c'),
      ('1. ab|cd\n2. e', '1. ab\n2. |cd\n3. e'),
      ('5. a|\n6. b\n7. c', '5. a\n6. |\n7. b\n8. c'),
      ('1. a|\n2. b\n\n3. c', '1. a\n2. |\n3. b\n\n4. c'),
      ('1) a|\n2) b', '1) a\n2) |\n3) b'),
      ('01. a|\n02. b\n03. c', '01. a\n02. |\n03. b\n04. c'),
      ('09. a|\n10. b', '09. a\n10. |\n11. b'),
      ('1. [ ] a|\n2. [x] b', '1. [ ] a\n2. [ ] |\n3. [x] b'),
    ]) {
      test(
        marked.replaceAll('\n', r'\n'),
        () => expect(_enter(marked), expected),
      );
    }

    test('behind the quote marks, in the same quote', () {
      expect(_enter('> 1. a|\n> 2. b'), '> 1. a\n> 2. |\n> 3. b');
    });

    test('on a nested list, and not past it', () {
      expect(
        _enter('1. a\n   1. x|\n   2. y\n2. b'),
        '1. a\n   1. x\n   2. |\n   3. y\n2. b',
      );
    });

    test('over the children of an item, which the new item takes', () {
      expect(
        _enter('1. a|\n   - x\n2. b\n3. c'),
        '1. a\n2. |\n   - x\n3. b\n4. c',
      );
    });

    test('a run is as far as the counting goes', () {
      expect(_enter('1. a|\n2. b\n5. c\n6. d'), '1. a\n2. |\n3. b\n5. c\n6. d');
    });

    test('a list written 1. 1. 1. is left alone', () {
      expect(_enter('1. a|\n1. b\n1. c'), '1. a\n2. |\n1. b\n1. c');
    });

    test('a list of another delimiter is not counted', () {
      expect(_enter('1. a|\n2) b'), '1. a\n2. |\n2) b');
    });

    test('a list that ends at a paragraph stops there', () {
      expect(_enter('1. a|\n2. b\ntext\n3. c'), '1. a\n2. |\n3. b\ntext\n3. c');
    });

    test('a bulleted list has nothing to renumber', () {
      expect(_enter('- a|\n- b'), '- a\n- |\n- b');
    });
  });

  group('an empty nested item going back a level makes room as well', () {
    test('the siblings of its parent count on', () {
      expect(_enter('1. a\n2. b\n   1. |\n3. c'), '1. a\n2. b\n3. |\n4. c');
    });

    test('with the padding of the list kept', () {
      expect(
        _enter('01. a\n02. b\n    1. |\n03. c'),
        '01. a\n02. b\n03. |\n04. c',
      );
    });
  });

  test('it is one edit, with the line endings the note has', () {
    final pressed = _press('1. a\r\n2. b\r\n3. c', 4)!;
    expect(pressed.edits, 1);
    final buffer = SourceBuffer.fromText('1. a\r\n2. b\r\n3. c');
    final edit = enterEdit(buffer, 4, indentWidth: 2)!;
    buffer.replaceRange(
      edit.start,
      edit.end,
      edit.text,
      verbatim: edit.verbatim,
    );
    expect(buffer.text, '1. a\r\n2. \r\n3. b\r\n4. c');
    expect(edit.caret, const SelectionModel.at(9));
  });

  test('a tab-indented sibling keeps its tab', () {
    expect(_enter('\t1. a|\n\t2. b'), '\t1. a\n\t2. |\n\t3. b');
  });

  group('over a long list, the answer of the whole note', () {
    test('a run that goes on past what is first read', () {
      final lines = [for (var n = 1; n <= 100; n++) '$n. item $n'];
      final note = lines.join('\n');
      final caret = SourceBuffer.fromText(note).offsetOfLine(9) + 4;
      final marked = _press(note, caret)!.text.replaceAll('|', '');
      expect(marked.split('\n').length, 101);
      expect(marked.split('\n')[100], '101. item 100');
      expect(marked, _wholeNote(lines, 9, 4, '\n'));
    });

    test('random lists, carets and line endings', () {
      final random = Random(20261127);
      for (var round = 0; round < 400; round++) {
        final counts = List<int>.filled(5, 0);
        var depth = 0;
        final lines = <String>[];
        final calm = round.isOdd;
        final quote = round % 7 == 0 ? '> ' : '';
        final total = 20 + random.nextInt(140);
        for (var at = 0; at < total; at++) {
          final step = random.nextInt(calm ? 30 : 8);
          if (step == 0 && depth < 3) {
            depth++;
            counts[depth] = 0;
          } else if (step <= (calm ? 2 : 2) && depth > 0) {
            depth -= 1 + random.nextInt(depth);
          }
          final pad = ' ' * (3 * depth);
          switch (random.nextInt(calm ? 20 : 8)) {
            case 0:
              lines.add('');
            case 1:
              lines.add('$quote$pad  more words');
            case 2:
              lines.add('$quote$pad- bullet');
            default:
              counts[depth] = !calm && random.nextInt(7) == 0
                  ? 1 + random.nextInt(9)
                  : counts[depth] + 1;
              final delimiter = !calm && random.nextInt(8) == 0 ? ')' : '.';
              lines.add('$quote$pad${counts[depth]}$delimiter item $at');
          }
        }
        final eol = random.nextBool() ? '\n' : '\r\n';
        final note = lines.join(eol);
        final buffer = SourceBuffer.fromText(note);
        final numbered = [
          for (var at = 0; at < lines.length; at++)
            if (ListRow(lines[at]).head?.number != null) at,
        ];
        if (numbered.isEmpty) continue;
        final line = numbered[random.nextInt(numbered.length)];
        final row = ListRow(lines[line]);
        final column = min<int>(
          lines[line].length - row.head!.content.length + random.nextInt(2),
          lines[line].length,
        );
        final caret = buffer.offsetOfLine(line) + column;
        final pressed = _press(note, caret);
        expect(pressed, isNotNull, reason: 'round $round line $line');
        expect(
          pressed!.text.replaceAll('|', ''),
          _wholeNote(lines, line, column, eol),
          reason: 'round $round, line $line of ${lines.length}',
        );
      }
    });
  });
}
