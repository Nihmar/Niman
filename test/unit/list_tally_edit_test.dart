// #136: finding the list to count and placing the block it writes.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/editor/list_tally_edit.dart';

/// Counts [text] from [line] the way the source editor would, and
/// returns the new text.
String _run(String text, int line, {TallyCut cut = TallyCut.dash}) {
  final target = tallyTargetAt(text, line);
  expect(target, isNotNull, reason: 'no list at line $line');
  final rows = tallyList(
    rows: target!.rows,
    cut: cut,
    checked: tallyChecksAt(text, target),
  );
  return applyTally(text: text, target: target, rows: rows).text;
}

void main() {
  group('tallyTargetAt', () {
    test('finds the whole list the caret sits in', () {
      const text = '# T\n\n1. a - x\n2. b - y\n3. c - x\n\nprose\n';
      final target = tallyTargetAt(text, 3);
      expect(target, isNotNull);
      expect(target!.sourceStart, 2);
      expect(target.sourceEnd, 5);
      expect(target.rows, <String>['a - x', 'b - y', 'c - x']);
      expect(target.replaces, isFalse);
    });

    test('strips the marker and the task box from each row', () {
      const text = '- [ ] a - x\n- [x] b - y\n';
      expect(tallyTargetAt(text, 0)!.rows, <String>['a - x', 'b - y']);
    });

    test('the blank line under a list still means that list', () {
      const text = '1. a - x\n\nprose\n';
      expect(tallyTargetAt(text, 1)?.sourceStart, 0);
    });

    test('run from inside its own block, it still means the list above', () {
      const text = '1. a - x\n\n- [ ] x: 1\n';
      final target = tallyTargetAt(text, 2);
      expect(target!.sourceStart, 0);
      expect(target.sourceEnd, 1);
      expect(target.rows, <String>['a - x']);
      expect(target.replaces, isTrue);
      expect(target.blockStart, 2);
      expect(target.blockEnd, 3);
    });

    test('a generated row is not a source row, blank line or not', () {
      const text = '1. a - x\n- [ ] x: 1\n';
      final target = tallyTargetAt(text, 0);
      expect(target!.rows, <String>['a - x']);
      expect(target.replaces, isTrue);
    });

    test('a block further down the note belongs to somebody else', () {
      const text = '1. a - x\n\n\n- [ ] x: 1\n';
      expect(tallyTargetAt(text, 0)!.replaces, isFalse);
    });

    test('prose is not a list', () {
      expect(tallyTargetAt('just prose\n', 0), isNull);
    });

    test('a list inside a code fence is not a list', () {
      const text = '```\n- a - x\n```\n';
      expect(tallyTargetAt(text, 1), isNull);
    });

    test('an empty note has nothing to count', () {
      expect(tallyTargetAt('', 0), isNull);
    });

    test('a line past the end belongs to no list, and does not throw', () {
      expect(tallyTargetAt('1. a - x\n', 99), isNull);
    });

    test('the list indent is the block indent', () {
      const text = '  - a - x\n  - b - y\n';
      expect(tallyTargetAt(text, 0)!.indent, 2);
    });
  });

  group('tallyTargetsIn', () {
    test('finds every list in the note, in order', () {
      const text =
          '# Colazioni\n\n- a - x\n- b - y\n\n'
          '## Pranzo\n\n1. c - z\n2. d - z\n\nprose\n';
      final targets = tallyTargetsIn(text);
      expect(targets, hasLength(2));
      expect(targets[0].rows, <String>['a - x', 'b - y']);
      expect(targets[1].rows, <String>['c - z', 'd - z']);
    });

    test('a block already written does not become a list of its own', () {
      const text = '- a - x\n\n- [ ] x: 1\n\n- b - y\n';
      final targets = tallyTargetsIn(text);
      expect(targets, hasLength(2));
      expect(targets[0].rows, <String>['a - x']);
      expect(targets[0].replaces, isTrue);
      expect(targets[1].rows, <String>['b - y']);
      expect(targets[1].replaces, isFalse);
    });

    test('the caret picks the list it is in, out of several', () {
      const text = '- a - x\n\n- b - y\n\n- c - z\n';
      expect(tallyTargetAt(text, 0)!.rows, <String>['a - x']);
      expect(tallyTargetAt(text, 2)!.rows, <String>['b - y']);
      expect(tallyTargetAt(text, 4)!.rows, <String>['c - z']);
    });

    test('a note with no list has nothing to offer', () {
      expect(tallyTargetsIn('just prose\n'), isEmpty);
    });
  });

  group('applyTally', () {
    test('writes the block under the list, with a blank line between', () {
      expect(
        _run('1. a - brioche\n2. b - brioche, orzo\n', 0),
        '1. a - brioche\n2. b - brioche, orzo\n\n'
        '- [ ] brioche: 2\n- [ ] orzo: 1\n',
      );
    });

    test('the text after the list keeps its own blank line', () {
      expect(_run('- a - x\n\nprose\n', 0), '- a - x\n\n- [ ] x: 1\n\nprose\n');
    });

    test('text glued under the list does not become part of the block', () {
      expect(_run('- a - x\nprose\n', 0), '- a - x\n\n- [ ] x: 1\n\nprose\n');
    });

    test('a re-run replaces the block instead of writing a second', () {
      const text = '- a - x\n- b - y\n\n- [ ] x: 1\n- [ ] y: 1\n';
      expect(_run(text, 0), text);
    });

    test('a re-run after an edit keeps the ticks of what survives', () {
      const text =
          '- a - x\n- b - x\n- c - z\n\n'
          '- [x] x: 1\n- [x] y: 3\n- [ ] z: 1\n';
      expect(
        _run(text, 0),
        '- a - x\n- b - x\n- c - z\n\n- [x] x: 2\n- [ ] z: 1\n',
      );
    });

    test('the indent of the list is the indent of the block', () {
      expect(_run('  - a - x\n', 0), '  - a - x\n\n  - [ ] x: 1\n');
    });

    test('the caret lands on the first generated row', () {
      const text = '- a - x\n';
      final target = tallyTargetAt(text, 0)!;
      final edit = applyTally(
        text: text,
        target: target,
        rows: tallyList(rows: target.rows, cut: TallyCut.dash),
      );
      expect(
        edit.text.substring(edit.selection.baseOffset),
        startsWith('- [ ] x: 1'),
      );
    });

    test('the note that asked for this counts and recounts', () {
      const order =
          '1. Alessandro -  acqua naturale, brioche\n'
          '2. Alex - coca cola, tramezzino olive\n'
          '3. Dara - orzo\n';
      final once = _run(order, 0);
      // Every value appears once, so the count order falls back on the
      // alphabet.
      expect(
        once,
        '$order\n'
        '- [ ] acqua naturale: 1\n'
        '- [ ] brioche: 1\n'
        '- [ ] coca cola: 1\n'
        '- [ ] orzo: 1\n'
        '- [ ] tramezzino olive: 1\n',
      );
      // Counting it again changes nothing: the block is found, not
      // counted, and rewritten as it was.
      expect(_run(once, 0), once);
    });
  });
}
