// The sidecar index (docs/records/dictionary.md, "The engine"): built from
// the pack's files alone, searched by binary search over the first keys of
// its blocks and one block read, stale when the pack changes, rebuilt when
// deleted.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/dictionary_exception.dart';
import 'package:niman/src/dictionary/dictionary_index.dart';
import 'package:niman/src/dictionary/dictionary_index_builder.dart';
import 'package:niman/src/dictionary/dictionary_index_job.dart';
import 'package:niman/src/dictionary/stardict_idx.dart';
import 'package:path/path.dart' as p;

import 'fixture_packs.dart';
import 'pack_writer.dart';

void main() {
  late Directory root;
  final opened = <DictionaryIndex>[];
  setUp(() => root = Directory.systemTemp.createTempSync('niman_index'));
  tearDown(() async {
    for (final index in opened) {
      await index.close();
    }
    opened.clear();
    root.deleteSync(recursive: true);
  });

  Future<DictionaryIndex> built(String directory, String id) async {
    await DictionaryIndexBuilder.build(directory: directory, id: id);
    final index = (await DictionaryIndex.open(directory, id))!;
    opened.add(index);
    return index;
  }

  test('a headword, a form and a shared form are found with their entry '
      'numbers', () async {
    final [it, _] = await writeFixturePacks(root.path);
    final index = await built(it, 'niman-it');
    final idx = await StardictIdx.readAll(p.join(it, 'niman-it.idx'));
    int number(String headword) =>
        idx.indexWhere((e) => e.headword == headword);

    expect(index.entryCount, idx.length);
    expect(await index.find('caminetto'), [
      (entry: number('caminetto'), isSyn: false),
    ]);
    expect(await index.find('caminetti'), [
      (entry: number('caminetto'), isSyn: true),
    ]);
    // One record per lemma, in the order of their entries.
    expect(await index.find('ami'), [
      (entry: number('amare'), isSyn: true),
      (entry: number('amo'), isSyn: true),
    ]);
    expect(await index.find('a priori'), isNotEmpty);
    expect(await index.find('caminett'), isEmpty);
    expect(await index.find('zzz'), isEmpty);
    expect(await index.find(''), isEmpty);
  });

  test('the case of a headword is kept: Polish and polish are two', () async {
    final [_, en] = await writeFixturePacks(root.path);
    final index = await built(en, 'niman-en');
    final idx = await StardictIdx.readAll(p.join(en, 'niman-en.idx'));
    final upper = await index.find('Polish');
    final lower = await index.find('polish');
    expect(upper, hasLength(1));
    expect(lower, hasLength(1));
    expect(idx[upper.single.entry].headword, 'Polish');
    expect(idx[lower.single.entry].headword, 'polish');
    expect(await index.find('POLISH'), isEmpty);
  });

  test('an entry number gives the place of its bytes in the .dict', () async {
    final [it, _] = await writeFixturePacks(root.path);
    final index = await built(it, 'niman-it');
    final idx = await StardictIdx.readAll(p.join(it, 'niman-it.idx'));
    final source = (await DictSource.open(it, 'niman-it'))!;
    addTearDown(source.close);
    for (final (number, entry) in idx.indexed) {
      final place = await index.entry(number);
      expect((place.offset, place.size), (entry.offset, entry.size));
    }
    final hit = (await index.find('caminetti')).single;
    final place = await index.entry(hit.entry);
    final html = utf8.decode(await source.read(place.offset, place.size));
    expect(html, contains('<h1>caminetto</h1>'));
  });

  test('every key of a pack of many blocks is found, a key shared by more '
      'than a block of lemmas gives them all', () async {
    final entries = [
      for (var i = 0; i < 400; i++)
        (headword: 'e${i.toString().padLeft(4, '0')}', html: 'entry $i'),
    ];
    final lemmas = [for (final e in entries.take(150)) e.headword];
    final dir = await writePack(
      root.path,
      code: 'xx',
      entries: entries,
      forms: {
        'shared': lemmas,
        for (var i = 0; i < 400; i += 3)
          'f${i.toString().padLeft(4, '0')}': [entries[i].headword],
      },
      compress: false,
    );
    final index = await built(dir, 'niman-xx');
    expect(index.keyCount, 400 + 150 + 134);
    for (var i = 0; i < 400; i++) {
      expect(await index.find(entries[i].headword), [
        (entry: i, isSyn: false),
      ], reason: entries[i].headword);
    }
    for (var i = 0; i < 400; i += 3) {
      expect(await index.find('f${i.toString().padLeft(4, '0')}'), [
        (entry: i, isSyn: true),
      ]);
    }
    final shared = await index.find('shared');
    expect(
      [for (final h in shared) h.entry],
      [for (var i = 0; i < 150; i++) i],
    );
    expect(shared.every((h) => h.isSyn), isTrue);
  });

  test('the nearest keys by prefix are distinct and in byte order, up to a '
      'limit', () async {
    final [it, _] = await writeFixturePacks(root.path);
    final index = await built(it, 'niman-it');
    expect(await index.keysWithPrefix('camin', 10), [
      'caminetti',
      'caminetto',
      'camini',
      'camino',
    ]);
    expect(await index.keysWithPrefix('camin', 2), ['caminetti', 'caminetto']);
    expect(await index.keysWithPrefix('ami', 10), ['ami']);
    expect(await index.keysWithPrefix('xyz', 10), isEmpty);
    // A key that is shared by several lemmas is one suggestion.
    expect(await index.keysWithPrefix('am', 10), ['amare', 'ami', 'amo']);
  });

  test('keys are held in NFC: a decomposed headword is found by the '
      'composed spelling and the other way round', () async {
    final dir = await writePack(
      root.path,
      code: 'xx',
      entries: [
        (headword: 'citta\u{0300}', html: 'city'),
        (headword: 'caf\u{00E9}', html: 'coffee'),
      ],
      compress: false,
    );
    final index = await built(dir, 'niman-xx');
    expect(await index.find('citt\u{00E0}'), hasLength(1));
    expect(await index.find('citta\u{0300}'), hasLength(1));
    expect(await index.find('cafe\u{0301}'), hasLength(1));
    expect(await index.find('caf\u{00E9}'), hasLength(1));
  });

  test('a pack without a .syn is indexed by its headwords', () async {
    final dir = await writePack(
      root.path,
      code: 'xx',
      entries: itEntries,
      compress: false,
    );
    expect(File(p.join(dir, 'niman-xx.syn')).existsSync(), isFalse);
    final index = await built(dir, 'niman-xx');
    expect(index.keyCount, itEntries.length);
    expect(await index.find('camino'), hasLength(1));
  });

  group('the sidecar is rebuildable', () {
    test('absent means open says so, and it is built on an isolate with '
        'progress', () async {
      final [it, _] = await writeFixturePacks(root.path);
      expect(await DictionaryIndex.open(it, 'niman-it'), isNull);
      final progress = <double>[];
      await buildDictionaryIndexOnIsolate(
        directory: it,
        id: 'niman-it',
        onProgress: progress.add,
      );
      expect(File(DictionaryIndex.pathOf(it, 'niman-it')).existsSync(), isTrue);
      expect(progress, isNotEmpty);
      expect(progress.last, 1);
      expect(progress, orderedEquals([...progress]..sort()));
      final index = (await DictionaryIndex.open(it, 'niman-it'))!;
      opened.add(index);
      expect(await index.find('caminetti'), hasLength(1));
    });

    test('deleted, it is built again, byte for byte', () async {
      final [it, _] = await writeFixturePacks(root.path);
      await (await built(it, 'niman-it')).close();
      opened.clear();
      final path = DictionaryIndex.pathOf(it, 'niman-it');
      final first = File(path).readAsBytesSync();
      File(path).deleteSync();
      expect(await DictionaryIndex.open(it, 'niman-it'), isNull);
      await built(it, 'niman-it');
      expect(File(path).readAsBytesSync(), first);
    });

    test('a pack that changed makes the sidecar stale', () async {
      final [it, _] = await writeFixturePacks(root.path);
      await DictionaryIndexBuilder.build(directory: it, id: 'niman-it');
      final open = await DictionaryIndex.open(it, 'niman-it');
      expect(open, isNotNull);
      await open!.close();
      // Same size, later time: a pack downloaded again.
      File(p.join(it, 'niman-it.dict.dz'))
          .setLastModifiedSync(DateTime.now().add(const Duration(minutes: 5)));
      expect(await DictionaryIndex.open(it, 'niman-it'), isNull);
      await DictionaryIndexBuilder.build(directory: it, id: 'niman-it');
      final again = await DictionaryIndex.open(it, 'niman-it');
      expect(again, isNotNull);
      await again!.close();
      // A different size, the .syn this time.
      File(p.join(it, 'niman-it.syn')).writeAsBytesSync([0x61, 0, 0, 0, 0, 0]);
      expect(await DictionaryIndex.open(it, 'niman-it'), isNull);
    });

    test('a damaged sidecar is a missing one', () async {
      final [it, _] = await writeFixturePacks(root.path);
      await DictionaryIndexBuilder.build(directory: it, id: 'niman-it');
      final path = DictionaryIndex.pathOf(it, 'niman-it');
      final bytes = File(path).readAsBytesSync();
      File(path).writeAsBytesSync(bytes.sublist(0, bytes.length - 10));
      expect(await DictionaryIndex.open(it, 'niman-it'), isNull);
      File(path).writeAsBytesSync(utf8.encode('not an index at all'));
      expect(await DictionaryIndex.open(it, 'niman-it'), isNull);
    });
  });

  test('a pack that is not format 1 is not indexed', () async {
    final dir = await writePack(
      root.path,
      code: 'xx',
      entries: itEntries,
      nimanPack: 2,
      compress: false,
    );
    await expectLater(
      DictionaryIndexBuilder.build(directory: dir, id: 'niman-xx'),
      throwsA(isA<DictionaryException>()),
    );
    await expectLater(
      buildDictionaryIndexOnIsolate(directory: dir, id: 'niman-xx'),
      throwsA(isA<DictionaryException>()),
    );
    expect(File(DictionaryIndex.pathOf(dir, 'niman-xx')).existsSync(), isFalse);
  });
}
