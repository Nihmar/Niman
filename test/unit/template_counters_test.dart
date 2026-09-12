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
      expect(store.use('quest'), 1);
      expect(store.use('quest'), 2);
      expect(store.use('other'), 1);
      expect(store.current('quest'), 2);
      expect(store.current('never'), 0);
    });

    test('survives a restart through .niman/counters.json', () async {
      final store = await CounterStore.load(root.path);
      expect(store.use('quest'), 1);
      expect(store.use('quest'), 2);
      await store.save();
      expect(
        File(p.join(root.path, '.niman', 'counters.json')).existsSync(),
        isTrue,
      );
      final reloaded = await CounterStore.load(root.path);
      expect(reloaded.current('quest'), 2);
      expect(reloaded.use('quest'), 3);
    });

    test('a missing or corrupt file starts empty', () async {
      final fresh = await CounterStore.load(root.path);
      expect(fresh.use('quest'), 1);
      final dir = Directory(p.join(root.path, '.niman'))..createSync();
      File(p.join(dir.path, 'counters.json')).writeAsStringSync('nope{');
      final corrupt = await CounterStore.load(root.path);
      expect(corrupt.use('quest'), 1);
    });
  });
}
