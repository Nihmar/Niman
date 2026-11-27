import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/external_sorter.dart';
import '../../../tool/dictionary_pack/star_dict_order.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  late Directory work;

  setUp(() {
    work = Directory.systemTemp.createTempSync('niman_sorter_test');
  });

  tearDown(() {
    work.deleteSync(recursive: true);
  });

  group('StarDict order', () {
    int cmp(String a, String b) => compareStarDictKeys(_b(a), _b(b));

    test('folds ASCII case first, then breaks the tie with strcmp', () {
      // g_ascii_strcasecmp calls them equal; strcmp puts 'P' before 'p'.
      expect(cmp('Polish', 'polish'), lessThan(0));
      expect(cmp('polish', 'Polish'), greaterThan(0));
      expect(cmp('polish', 'Polisher'), lessThan(0));
      expect(cmp('apple', 'Banana'), lessThan(0));
      expect(cmp('Zebra', 'apple'), greaterThan(0));
    });

    test('compares the UTF-8 bytes, so an accent sorts after z', () {
      expect(cmp('zebra', 'àncora'), lessThan(0));
      expect(cmp('ancora', 'àncora'), lessThan(0));
    });

    test('puts a prefix before its extensions', () {
      expect(cmp('a', 'ab'), lessThan(0));
      expect(cmp('', 'a'), lessThan(0));
    });
  });

  group('ExternalSorter', () {
    List<String> drained(ExternalSorter sorter) => [
      for (final r in sorter.drain())
        '${utf8.decode(r.key)}|${utf8.decode(r.value)}',
    ];

    test('sorts in memory when nothing spilled', () {
      final sorter = ExternalSorter(work, 's', SpillBudget(1 << 30))
        ..add(_b('b'), _b('1'))
        ..add(_b('A'), _b('2'))
        ..add(_b('a'), _b('3'))
        ..add(_b('b'), _b('0'));
      expect(drained(sorter), ['A|2', 'a|3', 'b|0', 'b|1']);
      expect(work.listSync(), isEmpty);
    });

    test('spills runs and merges them back in the same order', () {
      final random = Random(7);
      final words = [
        for (var i = 0; i < 3000; i++)
          String.fromCharCodes([
            for (var j = 0; j < 1 + random.nextInt(6); j++)
              (random.nextBool() ? 65 : 97) + random.nextInt(26),
          ]),
      ];
      // A tiny budget forces many runs.
      final sorter = ExternalSorter(work, 's', SpillBudget(20000));
      for (var i = 0; i < words.length; i++) {
        sorter.add(_b(words[i]), _b('$i'));
      }
      expect(
        work.listSync().whereType<File>().length,
        greaterThan(3),
        reason: 'the budget must have forced runs onto disk',
      );
      final expected =
          [for (var i = 0; i < words.length; i++) (_b(words[i]), _b('$i'))]
            ..sort((a, b) {
              final byKey = compareStarDictKeys(a.$1, b.$1);
              return byKey != 0 ? byKey : compareBytes(a.$2, b.$2);
            });
      expect(drained(sorter), [
        for (final (k, v) in expected) '${utf8.decode(k)}|${utf8.decode(v)}',
      ]);
      expect(work.listSync(), isEmpty, reason: 'runs are deleted once read');
    });

    test('the budget is shared: the fullest sorter is the one that spills', () {
      final budget = SpillBudget(5000);
      final small = ExternalSorter(work, 'small', budget)
        ..add(_b('x'), _b('y'));
      final big = ExternalSorter(work, 'big', budget);
      for (var i = 0; i < 200; i++) {
        big.add(_b('k$i'), _b('v' * 40));
      }
      final names = work.listSync().map((e) => p.basename(e.path)).toList();
      expect(names, everyElement(startsWith('big.')));
      expect(drained(small), ['x|y']);
      expect(drained(big), hasLength(200));
    });
  });
}
