// The expected HTML is written as adjacent strings, one element a line:
// the missing space between them is the point.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/pack_build.dart';
import '../../../tool/dictionary_pack/pack_languages.dart';
import '../../../tool/dictionary_pack/pack_report.dart';
import 'pack_reader.dart';

final String _fixtures = p.join(
  'test',
  'fixtures',
  'dictionary',
  'wiktextract',
);

void main() {
  late Directory dir;
  late PackReport report;
  late PackReport alone;

  Future<List<PackReport>> build(
    String name, {
    required bool withEnglish,
    bool dictzip = true,
    bool keepFolders = true,
  }) => buildPacks(
    BuildOptions(
      outDir: Directory(p.join(dir.path, name)),
      workDir: Directory(p.join(dir.path, '$name-work')),
      languages: [packLanguageFor('it')!],
      date: '2026-11-27',
      englishEdition: withEnglish
          ? File(p.join(_fixtures, 'en-sample.jsonl'))
          : null,
      ownEditions: {'it': File(p.join(_fixtures, 'it-sample.jsonl'))},
      dictzip: dictzip,
      keepFolders: keepFolders,
      memoryBytes: 1 << 10,
    ),
    (_) {},
  );

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('niman_pack_own');
    report = (await build('with-english', withEnglish: true)).single;
    alone = (await build('alone', withEnglish: false, dictzip: false)).single;
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  TestPack readPack(String name) =>
      TestPack.read(Directory(p.join(dir.path, name, 'niman-it')), 'niman-it');

  group('built from its own edition, completed from the English one', () {
    test('the .ifo says the glosses are Italian, from two editions', () {
      final it = readPack('with-english');
      expect(it.ifo['definitions'], 'it');
      expect(it.ifo['source'], 'it.wiktionary+en.wiktionary');
      expect(it.ifo['languages'], 'it');
      expect(it.ifo['website'], 'https://it.wiktionary.org');
      expect(it.ifo['bookname'], 'Wiktionary Italian');
    });

    test('its own entries are kept, in its own words', () {
      final it = readPack('with-english');
      expect(it.idx.map((e) => e.word), [
        'a priori',
        'amare',
        'amo',
        'ancora',
        'caminetto',
        'ghiaccio',
        'ghiaccioli',
        'ghiacciolo',
      ]);
      // The qualifier is what Italian Wiktionary printed, not the English
      // tag the extractor normalized it to.
      expect(
        it.html('caminetto'),
        '<div class="entry"><h1>caminetto</h1>'
        '<section data-pos="noun" data-tags="masculine"><ol>'
        '<li>Piccolo camino di una stanza.<ul class="ex">'
        '<li>accendere il caminetto</li></ul></li>'
        '<li><span class="q">figurato</span> Luogo di ritrovo.</li></ol>'
        '</section>'
        // Borrowed from the English edition.
        '<div class="forms"><span data-tags="plural">caminetti</span></div>'
        '</div>',
      );
      expect(
        it.html('ghiaccioli'),
        '<div class="entry"><h1>ghiaccioli</h1>'
        '<section data-pos="noun" data-tags=""><ol>'
        '<li>Plurale di ghiacciolo.</li></ol>'
        '<p class="form-of" data-tags="plural">ghiacciolo</p></section></div>',
      );
      expect(it.html('amare'), contains('<span class="q">sentimenti</span>'));
    });

    test('the English edition completes the forms of the lemmas it has', () {
      final it = readPack('with-english');
      // caminetto's own entry lists no form; the English one lists caminetti
      // twice (in the lemma and as the entry of the form). caminetti is no
      // headword of the own edition, so it is a record.
      expect(it.lemmasOf('caminetti'), ['caminetto']);
      expect(it.lemmasOf('ancore'), ['ancora']);
      // The form shared by two lemmas reaches both.
      expect(it.lemmasOf('ami'), ['amare', 'amo']);
      // The pack's own forms stay, and a form equal to the headword is none.
      expect(it.lemmasOf('ghiacci'), ['ghiaccio']);
      expect(it.lemmasOf('ghiaccio'), isEmpty);
      // ancorare is not in the own edition: its forms have no lemma to point
      // at, so neither ancoro nor ancora reaches it.
      expect(it.lemmasOf('ancoro'), isEmpty);
      expect(it.lemmasOf('ancora'), isEmpty);
      // amo is a headword here and a form of amare: its entry does not name
      // amare, so it keeps the record.
      expect(it.lemmasOf('amo'), ['amare']);
      // ghiaccioli is a headword and a form of ghiacciolo, and its entry
      // names ghiacciolo in a form-of paragraph: no record.
      expect(it.lemmasOf('ghiaccioli'), isEmpty);
      expect(it.html('ghiaccioli'), contains('class="form-of"'));
      expect(it.syn, hasLength(6));
    });

    test('every key is found, in either file', () {
      final it = readPack('with-english');
      for (final entry in it.idx) {
        expect(it.find(entry.word)?.offset, entry.offset);
      }
      for (final record in it.syn) {
        expect(it.idx[record.index].word, isNotEmpty);
      }
    });

    test('the report sets the own edition against the English one', () {
      final c = report.comparison!;
      // English Italian: caminetto, caminetti, ancora, ancorare, amare, amo,
      // a priori. Own: those but caminetti and ancorare, and ghiaccio and
      // ghiaccioli.
      expect(c.englishHeadwords, 7);
      expect(c.englishSenses, 11);
      expect(c.sharedHeadwords, 5);
      expect(c.coverage, closeTo(5 / 7, 1e-9));
      expect(c.sharedOwnSenses, 7);
      expect(c.sharedEnglishSenses, 9);
      expect(c.senseRatio, closeTo(7 / 9, 1e-9));
      expect(c.formsFromEnglish, 5);
      expect(report.headwords, 8);
      expect(report.inflectionHeadwords, 1);
      expect(report.sourceEntries, 9);
      expect(report.senses, 10);
      expect(report.skipped, isEmpty);
      expect(report.summary(), contains('coverage 71.4%'));
    });
  });

  group('without the English edition', () {
    test("forms are the own edition's alone, and it says so", () {
      final it = readPack('alone');
      expect(it.ifo['source'], 'it.wiktionary');
      expect(it.lemmasOf('caminetti'), isEmpty);
      expect(it.lemmasOf('ghiacci'), ['ghiaccio']);
      expect(alone.comparison, isNull);
    });

    test('--no-dictzip leaves a plain .dict, which is the same text', () {
      final it = readPack('alone');
      expect(it.file('dict.dz').existsSync(), isFalse);
      expect(it.file('dict').existsSync(), isTrue);
      expect(it.html('amo'), contains('Gancio da pesca.'));
      expect(alone.fileSizes.containsKey('dict.dz'), isFalse);
    });
  });

  test('archives only: the pack folder goes once it is archived', () async {
    await build('archived', withEnglish: false, keepFolders: false);
    expect(
      Directory(p.join(dir.path, 'archived', 'niman-it')).existsSync(),
      isFalse,
    );
    expect(
      File(p.join(dir.path, 'archived', 'niman-it.tar')).existsSync(),
      isTrue,
    );
    expect(
      File(p.join(dir.path, 'archived', 'niman-it.report.json')).existsSync(),
      isTrue,
    );
  });
}
