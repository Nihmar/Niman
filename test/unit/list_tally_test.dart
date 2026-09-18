// #136: counting the values of a list into a checklist.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_tally.dart';

/// The note that asked for the feature, rows only, verbatim — odd
/// spacing, mixed case and the dash glued to `succo` all as written.
const List<String> _order = <String>[
  'Alessandro -  acqua naturale, brioche',
  'Alex - coca cola, tramezzino olive',
  'Dara - orzo',
  'Chiara V -  succo pesca, tramezzino',
  'Elena - succo pesca, tramezzino',
  'Ilaria -  espresso',
  'Jacopo - succo pesca, tramezzino cip',
  'Tommaso -succo pesca, brioche',
  'Alessia - spremuta, brioche',
  'Chantal - cappuccino, brioche',
  'Gerard - macchiato, brioche',
  'Pamela - succo pesca, tramezzino cip',
  'Alberto - macchiato, brioche',
  'Fabio - macchiato, brioche',
];

void main() {
  group('tallyValues', () {
    test('cuts the name off and splits the rest on commas', () {
      expect(tallyValues('Alex - coca cola, tramezzino olive', TallyCut.dash), [
        'coca cola',
        'tramezzino olive',
      ]);
    });

    test('the dash does not need a space after it', () {
      expect(tallyValues('Tommaso -succo pesca, brioche', TallyCut.dash), [
        'succo pesca',
        'brioche',
      ]);
    });

    test('an en dash and an em dash cut too', () {
      expect(tallyValues('Elena – orzo', TallyCut.dash), ['orzo']);
      expect(tallyValues('Elena — orzo', TallyCut.dash), ['orzo']);
    });

    test('a hyphenated value is not cut in half', () {
      expect(tallyValues('anti-pasto', TallyCut.dash), ['anti-pasto']);
    });

    test('inner whitespace runs collapse and the value is trimmed', () {
      expect(tallyValues('Alessandro -  acqua   naturale ', TallyCut.dash), [
        'acqua naturale',
      ]);
    });

    test('a row the cut does not match keeps all of itself', () {
      expect(tallyValues('brioche', TallyCut.dash), ['brioche']);
    });

    test('empty values are dropped', () {
      expect(tallyValues('Elena - orzo, , brioche,', TallyCut.dash), [
        'orzo',
        'brioche',
      ]);
    });

    test('the colon cut takes the first colon only', () {
      expect(tallyValues('Elena: orzo: doppio', TallyCut.colon), [
        'orzo: doppio',
      ]);
    });

    test('commas splits without cutting a name off', () {
      expect(tallyValues('pane, latte', TallyCut.commas), ['pane', 'latte']);
    });

    test('whole keeps the row entire, commas and all', () {
      expect(tallyValues('pane, latte', TallyCut.whole), ['pane, latte']);
    });

    test('a blank row has no values', () {
      expect(tallyValues('   ', TallyCut.dash), isEmpty);
    });
  });

  group('detectTallyCut', () {
    test('picks the dash on the note that asked for this', () {
      expect(detectTallyCut(_order), TallyCut.dash);
    });

    test('picks the colon when that is what the rows use', () {
      expect(
        detectTallyCut(<String>['Elena: orzo', 'Dara: caffe', 'Ilaria: te']),
        TallyCut.colon,
      );
    });

    test('one stray dash does not decide how a shopping list is read', () {
      expect(
        detectTallyCut(<String>['pane, latte', 'uova', 'olio - extra']),
        TallyCut.commas,
      );
    });

    test('a list with no separator and no comma is counted whole', () {
      expect(
        detectTallyCut(<String>['brioche', 'brioche', 'orzo']),
        TallyCut.whole,
      );
    });

    test('an empty list falls back to whole rather than throwing', () {
      expect(detectTallyCut(const <String>[]), TallyCut.whole);
      expect(detectTallyCut(<String>['', '  ']), TallyCut.whole);
    });
  });

  group('tallyList', () {
    test('counts the order the way its author counted it by hand', () {
      final rows = tallyList(rows: _order, cut: TallyCut.dash);
      final counts = <String, int>{
        for (final row in rows) foldTallyLabel(row.label): row.count,
      };
      // The hand-made tally in the note: brioche 7, succo pesca 5,
      // tramezzino 5 across its three spellings, macchiato 3, and one
      // each of the rest.
      expect(counts['brioche'], 7);
      expect(counts['succo pesca'], 5);
      expect(counts['macchiato'], 3);
      expect(counts['tramezzino'], 2);
      expect(counts['tramezzino cip'], 2);
      expect(counts['tramezzino olive'], 1);
      expect(counts['acqua naturale'], 1);
      expect(counts['coca cola'], 1);
      expect(counts['orzo'], 1);
      expect(counts['espresso'], 1);
      expect(counts['spremuta'], 1);
      expect(counts['cappuccino'], 1);
      expect(counts.length, 12);
    });

    test('two spellings count as one, under the first one seen', () {
      final rows = tallyList(
        rows: <String>['a - Acqua naturale', 'b - acqua naturale'],
        cut: TallyCut.dash,
      );
      expect(rows, hasLength(1));
      expect(rows.single.label, 'Acqua naturale');
      expect(rows.single.count, 2);
    });

    test('count order is most first, ties alphabetical', () {
      final rows = tallyList(
        rows: <String>['x - b, c, a', 'y - a', 'z - a, c'],
        cut: TallyCut.dash,
      );
      expect(rows.map((r) => '${r.label}:${r.count}').toList(), [
        'a:3',
        'c:2',
        'b:1',
      ]);
    });

    test('alphabetical order ignores case', () {
      final rows = tallyList(
        rows: <String>['x - b, A, c'],
        cut: TallyCut.dash,
        sort: TallySort.alphabetical,
      );
      expect(rows.map((r) => r.label).toList(), ['A', 'b', 'c']);
    });

    test('first-seen order is the order of the source list', () {
      final rows = tallyList(
        rows: <String>['x - b, c', 'y - a, a, a'],
        cut: TallyCut.dash,
        sort: TallySort.firstSeen,
      );
      expect(rows.map((r) => r.label).toList(), ['b', 'c', 'a']);
    });

    test('a surviving label keeps the tick it had', () {
      final rows = tallyList(
        rows: <String>['x - brioche, orzo'],
        cut: TallyCut.dash,
        checked: <String, bool>{'brioche': true},
      );
      final brioche = rows.firstWhere((r) => r.label == 'brioche');
      final orzo = rows.firstWhere((r) => r.label == 'orzo');
      expect(brioche.checked, isTrue);
      expect(orzo.checked, isFalse);
    });

    test('a tick for a label that is gone does not come back', () {
      final rows = tallyList(
        rows: <String>['x - orzo'],
        cut: TallyCut.dash,
        checked: <String, bool>{'brioche': true},
      );
      expect(rows.map((r) => r.label).toList(), ['orzo']);
    });

    test('an empty list counts to nothing', () {
      expect(tallyList(rows: const <String>[], cut: TallyCut.dash), isEmpty);
    });
  });

  group('tallyLine', () {
    test('writes the checklist row', () {
      expect(
        tallyLine(const TallyRow(label: 'brioche', count: 7)),
        '- [ ] brioche: 7',
      );
    });

    test('a ticked row keeps its x', () {
      expect(
        tallyLine(const TallyRow(label: 'orzo', count: 1, checked: true)),
        '- [x] orzo: 1',
      );
    });

    test('an indent is kept', () {
      expect(
        tallyLine(const TallyRow(label: 'orzo', count: 1), indent: 2),
        '  - [ ] orzo: 1',
      );
    });
  });

  group('parseTallyLine', () {
    test('reads back what tallyLine writes', () {
      const row = TallyRow(label: 'succo pesca', count: 5, checked: true);
      expect(parseTallyLine(tallyLine(row)), row);
    });

    test('reads the hand-made rows in the note that asked for this', () {
      expect(
        parseTallyLine('- [ ] cappuccino: 1'),
        const TallyRow(label: 'cappuccino', count: 1),
      );
      expect(
        parseTallyLine('- [ ]  orzo: 1'),
        const TallyRow(label: 'orzo', count: 1),
      );
      expect(
        parseTallyLine('- [x] Macchiato: 3'),
        const TallyRow(label: 'Macchiato', count: 3, checked: true),
      );
    });

    test('an indented row is still a row', () {
      expect(parseTallyLine('   - [ ] orzo: 2')?.count, 2);
    });

    test('a label that ends in a number keeps it', () {
      expect(parseTallyLine('- [ ] caffe: 2: 3')?.label, 'caffe: 2');
      expect(parseTallyLine('- [ ] caffe: 2: 3')?.count, 3);
    });

    test('anything else is not one of ours', () {
      for (final line in <String>[
        '- [ ] brioche',
        '- brioche: 7',
        'brioche: 7',
        '- [ ] : 7',
        '- [ ] brioche: sette',
        '',
      ]) {
        expect(parseTallyLine(line), isNull, reason: line);
      }
    });
  });

  group('tallyChecks', () {
    test('keys the ticks by folded label', () {
      final checks = tallyChecks(<String>[
        '- [x] Brioche: 7',
        '- [ ] orzo: 1',
        'not a row',
      ]);
      expect(checks, <String, bool>{'brioche': true, 'orzo': false});
    });

    test('a half-rewritten block still gives up the ticks it carries', () {
      final checks = tallyChecks(<String>[
        '- [x] brioche: 7',
        '- [ ] Bibite: 2',
        '  - coca cola',
      ]);
      expect(checks.keys, containsAll(<String>['brioche', 'bibite']));
    });
  });
}
