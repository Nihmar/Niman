// The dictionaries folder's file work (#1382): a pack appears whole or not at
// all, and goes the same way.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_disk.dart';
import 'package:path/path.dart' as p;

import 'pack_tar.dart';

void main() {
  late Directory dir;
  late Directory root;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_disk');
    root = Directory(p.join(dir.path, 'dictionary'))..createSync();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// The fixture archive, where a download leaves it.
  Future<File> archive([String id = 'niman-it']) async {
    final built = await fixtureTar(dir, id);
    return built.renameSync(p.join(root.path, '$id.tar'));
  }

  List<String> names(Directory folder) =>
      [for (final entity in folder.listSync()) p.basename(entity.path)]..sort();

  group('install', () {
    test('unpacks into the pack folder and deletes the archive', () async {
      final tar = await archive();
      expect(await DictionaryDisk.install(root.path, 'niman-it'), isNull);
      expect(tar.existsSync(), isFalse);
      expect(names(Directory(p.join(root.path, 'niman-it'))), [
        'niman-it.dict.dz',
        'niman-it.idx',
        'niman-it.ifo',
        'niman-it.syn',
      ]);
      // The hidden folder it was unpacked in is gone.
      expect(names(root), ['niman-it']);
    });

    test('a truncated archive installs nothing and is kept', () async {
      final tar = await archive();
      final bytes = tar.readAsBytesSync();
      tar.writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
      final error = await DictionaryDisk.install(root.path, 'niman-it');
      expect(error, isNotNull);
      expect(names(root), ['niman-it.tar']);
      expect(await DictionaryDisk.scan(root.path), isEmpty);
    });

    test('a corrupt archive installs nothing', () async {
      File(p.join(root.path, 'niman-it.tar')).writeAsBytesSync(
        tarBytes([
          (name: 'niman-it.ifo', data: [1]),
        ], corruptChecksum: true),
      );
      expect(await DictionaryDisk.install(root.path, 'niman-it'), isNotNull);
      expect(names(root), ['niman-it.tar']);
    });

    test('an archive without a pack file installs nothing', () async {
      File(p.join(root.path, 'niman-it.tar')).writeAsBytesSync(
        tarBytes([
          (name: 'niman-it.ifo', data: [1]),
          (name: 'niman-it.idx', data: [1]),
        ]),
      );
      final error = await DictionaryDisk.install(root.path, 'niman-it');
      expect(error, contains('niman-it.dict.dz'));
      expect(names(root), ['niman-it.tar']);
    });

    test('a file of another pack, or of no pack, is refused', () async {
      File(p.join(root.path, 'niman-it.tar')).writeAsBytesSync(
        tarBytes([
          (name: 'niman-en.ifo', data: [1]),
        ]),
      );
      expect(await DictionaryDisk.install(root.path, 'niman-it'), isNotNull);
      expect(names(root), ['niman-it.tar']);
    });

    test('an older copy of the pack is replaced', () async {
      await archive();
      Directory(p.join(root.path, 'niman-it')).createSync();
      File(p.join(root.path, 'niman-it', 'stale.txt')).writeAsStringSync('x');
      expect(await DictionaryDisk.install(root.path, 'niman-it'), isNull);
      expect(
        File(p.join(root.path, 'niman-it', 'stale.txt')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(root.path, 'niman-it', 'niman-it.ifo')).existsSync(),
        isTrue,
      );
    });
  });

  group('scan', () {
    test('lists the installed packs with what they take on disk', () async {
      await archive();
      await DictionaryDisk.install(root.path, 'niman-it');
      final packs = await DictionaryDisk.scan(root.path);
      expect(packs.single.pack.id, 'niman-it');
      expect(packs.single.pack.isAvailable, isTrue);
      final expected =
          Directory(p.join('test', 'fixtures', 'dictionary', 'niman-it'))
              .listSync()
              .whereType<File>()
              .fold<int>(0, (sum, file) => sum + file.lengthSync());
      expect(packs.single.bytes, expected);
    });

    test('a folder that is not there holds nothing', () async {
      expect(await DictionaryDisk.scan(p.join(dir.path, 'absent')), isEmpty);
    });

    test('sweeping deletes what an interrupted install or removal left, '
        'and nothing else', () async {
      for (final name in [
        '.niman-it.unpacking',
        '.niman-en.removing',
        '.niman-fr.other',
        'plain',
      ]) {
        Directory(p.join(root.path, name)).createSync();
        File(p.join(root.path, name, 'f')).writeAsStringSync('x');
      }
      File(p.join(root.path, 'niman-it.tar.part')).writeAsStringSync('x');
      await DictionaryDisk.scan(root.path);
      expect(names(root), contains('.niman-it.unpacking'));
      await DictionaryDisk.scan(root.path, sweep: true);
      expect(names(root), ['.niman-fr.other', 'niman-it.tar.part', 'plain']);
    });
  });

  group('remove', () {
    test('deletes the folder and any archive left, and is done', () async {
      await archive();
      await DictionaryDisk.install(root.path, 'niman-it');
      File(p.join(root.path, 'niman-it.tar')).writeAsStringSync('x');
      expect(await DictionaryDisk.remove(root.path, 'niman-it'), isNull);
      expect(names(root), isEmpty);
    });

    test('a pack that is not there is already removed', () async {
      expect(await DictionaryDisk.remove(root.path, 'niman-it'), isNull);
    });

    test(
      'a hidden folder left by an earlier removal does not block it',
      () async {
        await archive();
        await DictionaryDisk.install(root.path, 'niman-it');
        final stale = Directory(p.join(root.path, '.niman-it.removing'))
          ..createSync();
        File(p.join(stale.path, 'f')).writeAsStringSync('x');
        expect(await DictionaryDisk.remove(root.path, 'niman-it'), isNull);
        expect(names(root), isEmpty);
      },
    );
  });
}
