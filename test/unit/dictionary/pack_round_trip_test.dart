// The two halves of the pack format meet here (docs/records/dictionary.md,
// "The pack format, version 1"): packs the pipeline builds from a
// wiktextract sample are looked up by the engine the app ships. Each side
// is tested against the contract on its own; this is what catches the two
// reading it differently.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/pack_build.dart';
import '../../../tool/dictionary_pack/pack_languages.dart';

final String _samples = p.join('test', 'fixtures', 'dictionary', 'wiktextract');

File _gzipped(Directory dir, String name) =>
    File(p.join(dir.path, '$name.jsonl.gz'))..writeAsBytesSync(
      gzip.encode(
        File(p.join(_samples, '$name-sample.jsonl')).readAsBytesSync(),
      ),
    );

void main() {
  late Directory dir;
  late DictionaryService service;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('niman_pack_round_trip');
    await buildPacks(
      BuildOptions(
        outDir: Directory(p.join(dir.path, 'packs')),
        workDir: Directory(p.join(dir.path, 'work')),
        languages: [
          for (final code in ['it', 'en', 'hr']) packLanguageFor(code)!,
        ],
        date: '2026-11-27',
        englishEdition: _gzipped(dir, 'en'),
        ownEditions: {'it': _gzipped(dir, 'it')},
        memoryBytes: 1 << 10,
      ),
      (_) {},
    );
    service = DictionaryService(directory: p.join(dir.path, 'packs'));
  });

  tearDownAll(() async {
    await service.dispose();
    dir.deleteSync(recursive: true);
  });

  test('the built packs are installed, each for its languages', () async {
    final packs = await service.installedPacks();
    expect(
      {for (final pack in packs) pack.id: pack.isAvailable},
      {'niman-it': true, 'niman-en': true, 'niman-sh': true},
    );
    expect((await service.packFor('sr'))?.id, 'niman-sh');
    expect((await service.packFor('bs'))?.id, 'niman-sh');
  });

  test(
    'an inflected form reaches its lemma, and says which form it was',
    () async {
      final result = await service.lookUp('caminetti', 'it');
      expect(result.outcome, DictionaryOutcome.found);
      final entry = result.entries.first;
      expect(entry.headword, 'caminetto');
      expect(entry.foundForm?.text, 'caminetti');
      expect(entry.foundForm?.tags, contains('plural'));
      expect(entry.credit.license, contains('CC BY-SA 4.0'));
    },
  );

  test('a form that is also a headword finds both, headword first', () async {
    // *Amo* is a noun (a fish-hook) and the first person of *amare*.
    final result = await service.lookUp('amo', 'it');
    expect(result.entries.map((e) => e.headword).toList(), ['amo', 'amare']);
  });

  test('a multi-word headword is found whole, from a selection', () async {
    final result = await service.lookUp('«a priori»', 'it');
    expect(result.entries.first.headword, 'a priori');
  });

  test('case keeps Polish and polish apart', () async {
    expect(
      (await service.lookUp('Polish', 'en')).entries.first.headword,
      'Polish',
    );
    expect(
      (await service.lookUp('polish', 'en')).entries.first.headword,
      'polish',
    );
  });

  test('a Cyrillic headword is reached from its Latin spelling', () async {
    final result = await service.lookUp('ljubav', 'hr');
    expect(result.entries.first.headword, 'љубав');
  });

  test('a word no pack has is not found, with no error', () async {
    final result = await service.lookUp('sbrindellato', 'it');
    expect(result.outcome, DictionaryOutcome.notFound);
  });
}
