// #52 AC: a per-library counter hands out 1 then 2, survives a
// restart, and counts each name separately.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/counters.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('niman_counters_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  group('CounterStore', () {
    test('starts at 1 and counts up per name', () async {
      final store = await CounterStore.load(root.path);
      expect(await store.use('quest'), 1);
      expect(await store.use('quest'), 2);
      expect(await store.use('other'), 1);
      expect(store.current('quest'), 2);
      expect(store.current('never'), 0);
    });

    test('survives a restart through .niman/counters.json', () async {
      final store = await CounterStore.load(root.path);
      expect(await store.use('quest'), 1);
      expect(await store.use('quest'), 2);
      await store.save();
      expect(
        File(p.join(root.path, '.niman', 'counters.json')).existsSync(),
        isTrue,
      );
      final reloaded = await CounterStore.load(root.path);
      expect(reloaded.current('quest'), 2);
      expect(await reloaded.use('quest'), 3);
    });

    // #359: two creations starting together are two stores over one root.
    // The value has to be on disk before it is handed back, or both read 0
    // and both get 1.
    test('two stores over one root hand out 1 then 2', () async {
      final first = await CounterStore.load(root.path);
      final second = await CounterStore.load(root.path);
      final handedOut = [await first.use('quest'), await second.use('quest')];
      expect(handedOut, [1, 2]);
    });

    test('a creation reserves one number per name, once', () async {
      expect(await CounterStore.reserve(root.path, const []), isNull);
      expect(await CounterStore.reserve(null, const ['quest']), isNull);
      final first = (await CounterStore.reserve(root.path, ['quest', 'bug']))!;
      expect(first.counter('quest'), 1);
      expect(first.counter('quest'), 1, reason: 'read twice, handed out once');
      expect(first.counter('bug'), 1);
      final second = (await CounterStore.reserve(root.path, ['quest']))!;
      expect(second.counter('quest'), 2);
    });

    test('a missing or corrupt file starts empty', () async {
      final fresh = await CounterStore.load(root.path);
      expect(await fresh.use('quest'), 1);
      final dir = Directory(p.join(root.path, '.niman'))..createSync();
      File(p.join(dir.path, 'counters.json')).writeAsStringSync('nope{');
      final corrupt = await CounterStore.load(root.path);
      expect(await corrupt.use('quest'), 1);
    });
  });
}
