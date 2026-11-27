// Tab and Shift+Tab over a buffer (`listIndentEdit`): the edit the source
// editor makes, held to the answer of `indentLines` over the whole note
// (#1345, #1355).
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_indent.dart';
import 'package:niman/src/editor/list_window.dart';
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

  group(
    "the edit is the whole note's answer, read from a part of it (#1355)",
    () {
      /// A list block of [count] lines: bullets and numbers, nested, some
      /// counted on one by one and some written as they came, with text and
      /// blank lines among them, now and then behind a quote's marks.
      ///
      /// With [calm] the list is mostly numbered, counted on one by one, and
      /// changes level seldom: long runs of siblings and long subtrees, which
      /// are what the edit has to read past its first few lines for.
      List<String> block(Random random, int count, {required bool calm}) {
        final counts = List<int>.filled(6, 0);
        final lines = <String>[];
        var depth = 0;
        final quote = !calm && random.nextInt(6) == 0 ? '> ' : '';
        for (var at = 0; at < count; at++) {
          final step = random.nextInt(calm ? 40 : 8);
          if (step == 0 && depth < 4) {
            depth++;
            counts[depth] = 0;
          } else if (step <= (calm ? 3 : 2) && depth > 0) {
            depth -= 1 + random.nextInt(depth);
          }
          final pad = ' ' * (3 * depth);
          switch (calm ? random.nextInt(24) + 4 : random.nextInt(12)) {
            case 0:
              lines.add('');
            case 1:
              lines.add('$quote$pad  words of an item');
            case 2 || 3 || 4:
              lines.add('$quote$pad- bullet $at');
            case 5:
              lines.add('$quote$pad- [ ] task $at');
            default:
              counts[depth] = !calm && random.nextInt(9) == 0
                  ? 1 + random.nextInt(12)
                  : counts[depth] + 1;
              final delimiter = !calm && random.nextInt(9) == 0 ? ')' : '.';
              lines.add('$quote$pad${counts[depth]}$delimiter item $at');
          }
        }
        return lines;
      }

      test('over a long list, a caret or a range, Tab and Shift+Tab', () {
        final random = Random(20261127);
        for (var round = 0; round < 500; round++) {
          final calm = round.isOdd;
          final lines = [
            ...block(random, 3, calm: calm),
            ...block(random, 40 + random.nextInt(160), calm: calm),
            'after the list',
          ];
          final eol = random.nextBool() ? '\n' : '\r\n';
          final note = lines.join(eol);
          final first = random.nextInt(lines.length - 1);
          final span = random.nextInt(3) == 0 ? random.nextInt(4) : 0;
          final last = min(lines.length - 2, first + span);
          final probe = SourceBuffer.fromText(note);
          final anchor = probe.offsetOfLine(first) + random.nextInt(3);
          final extent = probe.offsetOfLine(last) + random.nextInt(3);
          final marked = _mark(
            note,
            SelectionModel(
              anchor: min(anchor, probe.length),
              extent: min(extent, probe.length),
            ),
          );
          for (final outdent in <bool>[false, true]) {
            final width = random.nextBool() ? 2 : 4;
            expect(
              _press(marked, outdent: outdent, width: width),
              _whole(marked, outdent: outdent, width: width),
              reason:
                  'round $round, ${outdent ? 'outdent' : 'indent'} '
                  'at $first..$last of ${lines.length}',
            );
          }
        }
      });

      test('a numbered run that goes on past what is first read', () {
        // 100 items counted one by one: Tab on the 10th takes the 90 below it
        // along, which is more than the first read holds.
        final lines = [for (var n = 1; n <= 100; n++) '$n. item $n'];
        final note = lines.join('\n');
        final at = SourceBuffer.fromText(note).offsetOfLine(9);
        final marked = '${note.substring(0, at)}|${note.substring(at)}';
        expect(_press(marked), _whole(marked));
        expect(_press(marked).split('\n')[99], '99. item 100');
      });

      test('a subtree longer than the first read moves whole', () {
        final lines = [
          '- a',
          '- b',
          for (var n = 0; n < 100; n++) '  - child $n',
          '- c',
        ];
        final note = lines.join('\n');
        final at = SourceBuffer.fromText(note).offsetOfLine(1);
        final marked = '${note.substring(0, at)}|${note.substring(at)}';
        expect(_press(marked), _whole(marked));
        expect(_press(marked).split('\n')[101], '    - child 99');
      });

      test(
        'a flat list is read for a few lines around the item, not whole',
        () {
          final read = <int>{};
          final lines = [for (var n = 0; n < 5000; n++) '- item $n'];
          final window = listIndentWindowBelow(
            (at) {
              read.add(at);
              return lines[at];
            },
            lines.length,
            2500,
            2500,
            below: 32,
          );
          expect(window.complete, isFalse);
          expect(read.length, lessThan(40), reason: 'read $read');
        },
      );

      test('a sublist closed by the next item is not read past', () {
        // Items 1..5000, each followed by a two-item sublist: Tab on the
        // second of those closes up nothing below the sublist, so the first
        // read holds the answer.
        final lines = [
          for (var n = 1; n <= 5000; n++) ...[
            '$n. item',
            '   1. first',
            '   2. second',
          ],
        ];
        const at = 3 * 2500 + 2;
        final window = listIndentWindowBelow(
          (line) => lines[line],
          lines.length,
          at,
          at,
          below: 32,
        );
        final run = indentListLinesWithin(
          [for (var l = window.first; l <= window.last; l++) lines[l]],
          first: at - window.first,
          last: at - window.first,
          width: 2,
          outdent: false,
        );
        expect(window.complete, isFalse);
        expect(run.needsMore, isFalse);
        expect(window.last - window.first, lessThan(40));
      });

      test(
        'an item of a long bulleted list is indented without reading it',
        () {
          final lines = [for (var n = 0; n < 20000; n++) '- item $n'];
          final buffer = SourceBuffer.fromText(lines.join('\n'));
          final edit = listIndentEdit(
            buffer,
            SelectionModel.at(buffer.offsetOfLine(10000) + 3),
            width: 2,
            outdent: false,
          )!;
          expect(edit.text, '  - item 10000');
          expect(edit.start, buffer.offsetOfLine(10000));
          expect(edit.end, buffer.offsetOfLine(10000) + 12);
        },
      );
    },
  );
}
