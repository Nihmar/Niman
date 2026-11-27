// The expected HTML is written as adjacent strings, one element a line:
// the missing space between them is the point.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/dictionary_pack/pack_archive.dart';
import '../../../tool/dictionary_pack/pack_build.dart';
import '../../../tool/dictionary_pack/pack_languages.dart';
import '../../../tool/dictionary_pack/pack_report.dart';
import '../../../tool/dictionary_pack/star_dict_order.dart';
import 'pack_reader.dart';

final String _fixtures = p.join(
  'test',
  'fixtures',
  'dictionary',
  'wiktextract',
);

PackLanguage _language(String code) => packLanguageFor(code)!;

void main() {
  late Directory dir;
  late Map<String, PackReport> reports;

  group('built from the English edition', () {
    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('niman_pack_en');
      // The dump comes gzipped, as kaikki.org serves it.
      final gz = File(p.join(dir.path, 'en.jsonl.gz'))
        ..writeAsBytesSync(
          gzip.encode(
            File(p.join(_fixtures, 'en-sample.jsonl')).readAsBytesSync(),
          ),
        );
      reports = {
        for (final r in await buildPacks(
          BuildOptions(
            outDir: Directory(p.join(dir.path, 'out')),
            workDir: Directory(p.join(dir.path, 'work')),
            languages: [_language('it'), _language('en'), _language('hr')],
            date: '2026-11-27',
            englishEdition: gz,
            // Small enough that the sorts spill, so the merge is exercised.
            memoryBytes: 1 << 10,
          ),
          (_) {},
        ))
          r.id: r,
      };
    });

    tearDownAll(() => dir.deleteSync(recursive: true));

    TestPack readPack(String id) =>
        TestPack.read(Directory(p.join(dir.path, 'out', id)), id);

    test('builds a pack for each language, hr being the sh pack', () {
      expect(
        reports.keys,
        unorderedEquals(['niman-it', 'niman-en', 'niman-sh']),
      );
    });

    test("the .ifo has the StarDict keys and Niman's", () {
      final it = readPack('niman-it');
      expect(it.ifo.keys, [
        'version',
        'bookname',
        'wordcount',
        'synwordcount',
        'idxfilesize',
        'idxoffsetbits',
        'sametypesequence',
        'author',
        'website',
        'description',
        'date',
        'niman-pack',
        'languages',
        'definitions',
        'source',
        'license',
      ]);
      expect(it.ifo['version'], '3.0.0');
      expect(it.ifo['wordcount'], '${it.idx.length}');
      expect(it.ifo['synwordcount'], '${it.syn.length}');
      expect(it.ifo['idxfilesize'], '${it.idxBytes.length}');
      expect(it.ifo['idxoffsetbits'], '32');
      expect(it.ifo['sametypesequence'], 'h');
      expect(it.ifo['niman-pack'], '1');
      expect(it.ifo['languages'], 'it');
      expect(it.ifo['definitions'], 'en');
      expect(it.ifo['source'], 'en.wiktionary');
      expect(it.ifo['license'], 'CC BY-SA 4.0; GFDL');
      expect(it.ifo['date'], '2026-11-27');
      final description = it.ifo['description']!;
      for (final part in [
        'Wiktionary contributors',
        'CC BY-SA 4.0',
        'GFDL',
        'wiktextract',
        'Tatu Ylonen',
        'Wiktextract: Wiktionary as Machine-Readable Structured Data',
        'LREC 2022',
      ]) {
        expect(description, contains(part));
      }
      expect(readPack('niman-sh').ifo['languages'], 'hr,sr,bs');
      expect(readPack('niman-en').ifo['bookname'], 'Wiktionary English');
    });

    test('the .idx is in StarDict order with contiguous offsets', () {
      final it = readPack('niman-it');
      expect(it.idx.map((e) => e.word), [
        'a priori',
        'amare',
        'amo',
        'ancora',
        'ancorare',
        'caminetti',
        'caminetto',
      ]);
      var offset = 0;
      for (final entry in it.idx) {
        expect(entry.offset, offset);
        offset += entry.size;
      }
      expect(offset, it.dict.length);
      for (var i = 1; i < it.idx.length; i++) {
        expect(
          compareStarDictKeys(it.idx[i - 1].key, it.idx[i].key),
          lessThan(0),
        );
      }
    });

    test('Polish and polish are two entries, the capital first', () {
      final en = readPack('niman-en');
      expect(en.idx.map((e) => e.word), ['Polish', 'polish', 'R&D']);
      // Each holds every part of speech of its headword.
      expect(RegExp('<section ').allMatches(en.html('Polish')).length, 2);
      expect(en.html('polish'), contains('data-pos="verb"'));
      expect(en.html('polish'), contains('data-pos="noun"'));
    });

    test('every key written is found by binary search', () {
      for (final id in reports.keys) {
        final pack = readPack(id);
        for (final entry in pack.idx) {
          expect(
            pack.find(entry.word)?.offset,
            entry.offset,
            reason: entry.word,
          );
        }
        for (final record in pack.syn) {
          expect(pack.idx[record.index], isNotNull);
        }
        for (var i = 1; i < pack.syn.length; i++) {
          final a = pack.syn[i - 1];
          final b = pack.syn[i];
          final order = compareStarDictKeys(a.key, b.key);
          expect(order <= 0, isTrue, reason: '.syn out of order at $i');
          if (order == 0) expect(a.index, lessThan(b.index));
        }
      }
    });

    test('an entry is the closed HTML grammar, exactly', () {
      final it = readPack('niman-it');
      expect(
        it.html('caminetto'),
        '<div class="entry"><h1>caminetto</h1>'
        '<section data-pos="noun" data-tags="masculine"><ol>'
        '<li>fireplace, hearth<ul class="ex"><li>accendere il caminetto</li>'
        '</ul></li>'
        '<li><span class="q">figuratively, architecture</span> '
        'a place to gather</li></ol></section>'
        '<div class="forms"><span data-tags="plural">caminetti</span></div>'
        '</div>',
      );
      expect(
        it.html('caminetti'),
        '<div class="entry"><h1>caminetti</h1>'
        '<section data-pos="noun" data-tags=""><ol>'
        '<li>plural of caminetto</li></ol>'
        '<p class="form-of" data-tags="plural">caminetto</p></section></div>',
      );
    });

    test('a multi-word headword is one entry with its parts of speech', () {
      expect(
        readPack('niman-it').html('a priori'),
        '<div class="entry"><h1>a priori</h1>'
        '<section data-pos="adv" data-tags=""><ol><li>a priori</li></ol>'
        '</section>'
        '<section data-pos="adj" data-tags="masculine feminine"><ol>'
        '<li><span class="q">invariable</span> '
        'a priori, not based on experience</li></ol></section></div>',
      );
    });

    test('text is HTML-escaped, and a long quotation is left out', () {
      final en = readPack('niman-en');
      expect(
        en.html('R&D'),
        '<div class="entry"><h1>R&amp;D</h1>'
        '<section data-pos="noun" data-tags=""><ol>'
        '<li><span class="q">abbreviation</span> '
        'Abbreviation of research &amp; development: '
        'the &quot;R&lt;&gt;D&quot; department.'
        '<ul class="ex"><li>&lt;b&gt;R&amp;D&lt;/b&gt; spending rose.</li></ul>'
        '</li></ol></section></div>',
      );
      expect(
        readPack('niman-it').html('caminetto'),
        isNot(contains('lungo passo')),
      );
    });

    test('a form shared by two lemmas has two records, a headword none', () {
      final it = readPack('niman-it');
      // ami: the plural of amo and a form of amare.
      expect(it.lemmasOf('ami'), ['amare', 'amo']);
      expect(it.lemmasOf('ancore'), ['ancora']);
      expect(it.lemmasOf('ancoro'), ['ancorare']);
      // ancora and amo are forms of ancorare and amare, and headwords.
      expect(it.lemmasOf('ancora'), isEmpty);
      expect(it.lemmasOf('amo'), isEmpty);
      // caminetti is a headword; its entry says it is a form of caminetto.
      expect(it.lemmasOf('caminetti'), isEmpty);
      // Placeholders of the extractor are not forms.
      expect(it.syn.map((r) => r.word), isNot(contains('-')));
      expect(it.syn.map((r) => r.word), isNot(contains('no-table-tags')));
      expect(it.syn, hasLength(4));
    });

    test('Serbo-Croatian is keyed in both scripts', () {
      final sh = readPack('niman-sh');
      expect(sh.idx.map((e) => e.word), containsAll(['kuća', 'кућа', 'вода']));
      // Each script of kuća is a headword: no record for either.
      expect(sh.lemmasOf('kuća'), isEmpty);
      expect(sh.lemmasOf('кућа'), isEmpty);
      // The Latin spelling a Cyrillic entry lists, and the one it does not
      // list, which is added.
      expect(sh.lemmasOf('voda'), ['вода']);
      expect(sh.lemmasOf('ljubav'), ['љубав']);
      // A Latin entry gains no Cyrillic key: that map is not exact.
      expect(sh.lemmasOf('лијеп'), isEmpty);
      expect(sh.lemmasOf('џеп'), isEmpty);
      expect(sh.lemmasOf('kuće'), ['kuća']);
    });

    test('.dict.dz is dictzip: each entry reads from its own chunks', () {
      for (final id in reports.keys) {
        final pack = readPack(id);
        expect(pack.file('dict').existsSync(), isFalse);
        for (final entry in pack.idx) {
          expect(pack.htmlByChunks(entry), pack.html(entry.word));
        }
      }
    });

    test('the archive holds the four files, flat', () {
      for (final id in reports.keys) {
        final tar = File(p.join(dir.path, 'out', '$id.tar'));
        final members = readTarMembers(tar);
        expect(members.map((m) => m.name), [
          '$id.ifo',
          '$id.idx',
          '$id.syn',
          '$id.dict.dz',
        ]);
        // An independent reader agrees.
        final archive = TarDecoder().decodeBytes(tar.readAsBytesSync());
        expect(archive.files.map((f) => f.name), members.map((m) => m.name));
        for (final file in archive.files) {
          final source = File(p.join(dir.path, 'out', id, file.name));
          expect(file.content, source.readAsBytesSync(), reason: file.name);
        }
      }
    });

    test('the report counts what was written', () {
      final it = reports['niman-it']!;
      expect(it.headwords, 7);
      expect(it.inflectionHeadwords, 1);
      expect(it.sourceEntries, 9);
      expect(it.senses, 11);
      expect(it.forms, 7);
      expect(it.synRecords, 4);
      expect(it.skipped, {'no sense with a gloss': 1, 'redirect': 1});
      expect(it.comparison, isNull);
      final pack = readPack('niman-it');
      expect(it.fileSizes['idx'], pack.idxBytes.length);
      expect(it.fileSizes['dict'], pack.dict.length);
      expect(it.fileSizes['dict.dz'], pack.file('dict.dz').lengthSync());
      expect(
        it.fileSizes['tar'],
        File(p.join(dir.path, 'out', 'niman-it.tar')).lengthSync(),
      );
      final json = jsonDecode(
        File(p.join(dir.path, 'out', 'niman-it.report.json'))
            .readAsStringSync(),
      ) as Map<String, Object?>;
      expect(json['headwords'], 7);
      expect(json['synRecords'], 4);
      expect(json['sensesPerHeadword'], closeTo(1.5714, 0.0001));
      expect(
        File(p.join(dir.path, 'out', 'report.txt')).readAsStringSync(),
        contains('niman-it'),
      );
    });

    test('the spill files are gone', () {
      expect(Directory(p.join(dir.path, 'work')).listSync(), isEmpty);
    });
  });
}
