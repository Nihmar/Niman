// The facade the rest of the app calls (docs/records/dictionary.md, "The
// engine"): a selection and a language in, a result out, through the pack
// folder, the sidecar index and the worker isolate, over the small fixture
// packs.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:path/path.dart' as p;

import 'fixture_packs.dart';
import 'pack_writer.dart';

void main() {
  late Directory root;
  late DictionaryService service;
  setUp(() async {
    root = Directory.systemTemp.createTempSync('niman_service');
    await writeFixturePacks(root.path);
    service = DictionaryService(directory: root.path);
  });
  tearDown(() async {
    await service.dispose();
    root.deleteSync(recursive: true);
  });

  List<String> headwords(DictionaryResult result) => [
    for (final entry in result.entries) entry.headword,
  ];

  group('candidates, in order', () {
    test('a headword is found and read', () async {
      final result = await service.lookUp('caminetto', 'it');
      expect(result.outcome, DictionaryOutcome.found);
      expect(result.isFound, isTrue);
      expect(result.packId, 'niman-it');
      expect(result.matched, 'caminetto');
      expect(headwords(result), ['caminetto']);
      final entry = result.entries.single;
      expect(entry.language, 'it');
      expect(entry.foundForm, isNull);
      expect(entry.sections.single.pos, 'noun');
      expect(entry.sections.single.tags, ['masculine']);
      expect(entry.sections.single.senses, hasLength(2));
      expect(entry.sections.single.senses[1].qualifier, 'familiar');
      expect(entry.sections.single.senses[0].examples, hasLength(1));
      expect(entry.forms.single.text, 'caminetti');
      expect(entry.credit.license, 'CC BY-SA 4.0; GFDL');
      expect(entry.credit.source, 'it.wiktionary');
    });

    test('a .syn form leads to its lemma, and says the form read', () async {
      final result = await service.lookUp('caminetti', 'it');
      expect(result.matched, 'caminetti');
      expect(headwords(result), ['caminetto']);
      expect(result.entries.single.foundForm?.text, 'caminetti');
      expect(result.entries.single.foundForm?.tags, ['plural']);
    });

    test('capitals and punctuation around a form are cleaned and '
        'lowercased', () async {
      final result = await service.lookUp('\u{201C}Caminetti,\u{201D}', 'it');
      expect(result.matched, 'caminetti');
      expect(headwords(result), ['caminetto']);
    });

    test('an elision is undone: dell\u{2019}acqua is acqua', () async {
      for (final selection in ["dell'acqua", 'dell\u{2019}acqua']) {
        final result = await service.lookUp(selection, 'it');
        expect(result.matched, 'acqua', reason: selection);
        expect(headwords(result), ['acqua']);
      }
    });

    test('a word hyphenated across a line is joined', () async {
      final result = await service.lookUp('cam-\nmino', 'it');
      expect(result.matched, 'cammino');
      expect(headwords(result), ['cammino']);
    });

    test('a soft hyphen is removed and a decomposed letter composed', () async {
      expect(headwords(await service.lookUp('cam\u{00AD}mino', 'it')), [
        'cammino',
      ]);
      expect(headwords(await service.lookUp('citta\u{0300}', 'it')), [
        'citt\u{00E0}',
      ]);
    });

    test('the whole selection is tried before its first word', () async {
      final whole = await service.lookUp('a priori', 'it');
      expect(whole.matched, 'a priori');
      expect(headwords(whole), ['a priori']);
      final cream = await service.lookUp('ice cream', 'en');
      expect(headwords(cream), ['ice cream']);
      final first = await service.lookUp('ice creams', 'en');
      expect(first.matched, 'ice');
      expect(headwords(first), ['ice']);
    });

    test('the case of a headword counts: Polish and polish are two', () async {
      expect(headwords(await service.lookUp('Polish', 'en')), ['Polish']);
      expect(headwords(await service.lookUp('polish', 'en')), ['polish']);
      // Neither exactly: the lowercase one is tried first.
      expect(headwords(await service.lookUp('POLISH', 'en')), ['polish']);
      final polish = (await service.lookUp('polish', 'en')).entries.single;
      expect(polish.sections.map((s) => s.pos), ['verb', 'noun']);
    });

    test('a form of an English lemma, from the sentence start', () async {
      final result = await service.lookUp('Polished', 'en');
      expect(result.matched, 'polished');
      expect(headwords(result), ['polish']);
      expect(result.entries.single.foundForm?.tags, ['past']);
    });

    test('a form shared by two lemmas gives both entries', () async {
      final result = await service.lookUp('ami', 'it');
      expect(headwords(result), ['amare', 'amo']);
      expect(result.entries[0].foundForm?.text, 'ami');
      // Only the second lists it among its forms, with its tag.
      expect(result.entries[1].foundForm?.tags, ['plural']);
      expect(result.entries[0].foundForm?.tags, isEmpty);
    });

    test('an entry that is itself an inflected form names its lemma', () async {
      final result = await service.lookUp('camini', 'it');
      expect(headwords(result), ['camini']);
      final lemma = result.entries.single.lemmas.single;
      expect(lemma.text, 'camino');
      expect(lemma.tags, ['plural']);
      // The lemma is a look-up of its own.
      expect(headwords(await service.lookUp(lemma.text, 'it')), ['camino']);
    });

    test('a language with a region reads as the language', () async {
      expect(headwords(await service.lookUp('caminetto', 'it-IT')), [
        'caminetto',
      ]);
      expect((await service.lookUp('caminetto', 'it_IT')).isFound, isTrue);
    });
  });

  group('nothing found', () {
    test('the nearest keys by prefix are offered', () async {
      final result = await service.lookUp('caminett', 'it');
      expect(result.outcome, DictionaryOutcome.notFound);
      expect(result.entries, isEmpty);
      expect(result.matched, isNull);
      expect(result.suggestions, ['caminetti', 'caminetto']);
    });

    test('a longer typo falls back to a shorter prefix', () async {
      final result = await service.lookUp('camminetto', 'it');
      expect(result.outcome, DictionaryOutcome.notFound);
      expect(result.suggestions, containsAll(['cammino']));
    });

    test('a word with nothing near it has no suggestion', () async {
      final result = await service.lookUp('zzzz', 'it');
      expect(result.outcome, DictionaryOutcome.notFound);
      expect(result.suggestions, isEmpty);
    });

    test('an empty selection finds nothing, and asks nothing', () async {
      final result = await service.lookUp('  \u{201C}\u{201D} ', 'it');
      expect(result.outcome, DictionaryOutcome.notFound);
      expect(result.suggestions, isEmpty);
    });

    test('suggestions are a handful at most', () async {
      final result = await service.lookUp('ca', 'it');
      expect(result.suggestions.length, lessThanOrEqualTo(6));
    });
  });

  group('packs', () {
    test('no pack for the language says so', () async {
      final result = await service.lookUp('Haus', 'de');
      expect(result.outcome, DictionaryOutcome.noPack);
      expect(result.packId, isNull);
      expect(result.entries, isEmpty);
    });

    test('a pack added later is found by the next look-up', () async {
      expect(
        (await service.lookUp('Haus', 'de')).outcome,
        DictionaryOutcome.noPack,
      );
      await writePack(
        root.path,
        code: 'de',
        entries: [(headword: 'Haus', html: '<p>house</p>')],
      );
      final result = await service.lookUp('Haus', 'de');
      expect(result.outcome, DictionaryOutcome.found);
      expect(result.packId, 'niman-de');
    });

    test(
      'a pack that is not format 1 is unavailable, with its reason',
      () async {
        await writePack(
          root.path,
          code: 'xx',
          entries: [(headword: 'a', html: 'b')],
          nimanPack: 2,
        );
        final result = await service.lookUp('a', 'xx');
        expect(result.outcome, DictionaryOutcome.unavailable);
        expect(result.reason, contains('niman-pack'));
        expect(result.packId, 'niman-xx');
        // The other packs go on working.
        expect((await service.lookUp('caminetto', 'it')).isFound, isTrue);
      },
    );

    test(
      'niman-sh serves hr, sr and bs, each result in its own language',
      () async {
        await writePack(
          root.path,
          code: 'sh',
          entries: [
            (headword: 'ku\u{0107}a', html: '<p>house</p>'),
            (
              headword: '\u{043A}\u{0443}\u{045B}\u{0430}',
              html: '<p>house</p>',
            ),
          ],
          forms: {
            'ku\u{0107}e': ['ku\u{0107}a'],
          },
          languages: ['hr', 'sr', 'bs'],
        );
        for (final language in ['hr', 'sr', 'bs']) {
          final result = await service.lookUp('ku\u{0107}a', language);
          expect(result.packId, 'niman-sh', reason: language);
          expect(headwords(result), ['ku\u{0107}a']);
          expect(result.entries.single.language, language);
        }
        // The other script of the entry is a headword of its own.
        expect(
          (await service.lookUp(
            '\u{043A}\u{0443}\u{045B}\u{0430}',
            'sr',
          )).isFound,
          isTrue,
        );
        expect((await service.lookUp('ku\u{0107}e', 'hr-HR')).isFound, isTrue);
      },
    );

    test('a pack replaced on disk is read again after forget', () async {
      expect(headwords(await service.lookUp('cat', 'en')), ['cat']);
      await writePack(
        root.path,
        code: 'en',
        entries: [
          (headword: 'cat', html: '<p>a different cat</p>'),
          (headword: 'dog', html: '<p>a dog</p>'),
        ],
      );
      await service.forget('niman-en');
      final dog = await service.lookUp('dog', 'en');
      expect(headwords(dog), ['dog']);
      final cat = await service.lookUp('cat', 'en');
      expect(
        cat.entries.single.sections.single.senses.single.text,
        'a different cat',
      );
    });

    test('the Turkish dotted and dotless i are looked up', () async {
      await writePack(
        root.path,
        code: 'tr',
        entries: [
          (headword: '\u{0131}s\u{0131}', html: '<p>heat</p>'),
          (headword: 'i\u{015F}', html: '<p>work</p>'),
          (headword: '\u{0130}stanbul', html: '<p>a city</p>'),
        ],
      );
      expect(headwords(await service.lookUp('ISI', 'tr')), [
        '\u{0131}s\u{0131}',
      ]);
      expect(headwords(await service.lookUp('\u{0130}\u{015E}', 'tr')), [
        'i\u{015F}',
      ]);
      expect(headwords(await service.lookUp('istanbul', 'tr')), [
        '\u{0130}stanbul',
      ]);
    });
  });

  group('the worker and what it keeps', () {
    test('the first look-up builds the index, with progress', () async {
      final progress = <IndexProgress>[];
      final subscription = service.indexProgress.listen(progress.add);
      addTearDown(subscription.cancel);
      expect(
        File(p.join(root.path, 'niman-it', 'niman-it.niman-index'))
            .existsSync(),
        isFalse,
      );
      await service.lookUp('caminetto', 'it');
      await Future<void>.delayed(Duration.zero);
      expect(
        File(p.join(root.path, 'niman-it', 'niman-it.niman-index'))
            .existsSync(),
        isTrue,
      );
      expect(progress, isNotEmpty);
      expect({for (final event in progress) event.packId}, {'niman-it'});
      expect(progress.last.fraction, 1);
    });

    test('look-ups at the same time share one build', () async {
      final results = await Future.wait([
        for (var i = 0; i < 6; i++) service.lookUp('caminetto', 'it'),
      ]);
      expect(results.every((r) => r.isFound), isTrue);
    });

    test('a recent look-up is kept: the same result comes back', () async {
      final first = await service.lookUp('caminetto', 'it');
      final second = await service.lookUp('caminetto', 'it');
      expect(identical(first, second), isTrue);
      // The cache is bounded: older ones go.
      final small = DictionaryService(directory: root.path, cacheSize: 2);
      addTearDown(small.dispose);
      final a = await small.lookUp('caminetto', 'it');
      await small.lookUp('camino', 'it');
      await small.lookUp('cammino', 'it');
      expect(identical(await small.lookUp('caminetto', 'it'), a), isFalse);
    });

    test('prepare builds and opens the pack of a language', () async {
      await service.prepare('it');
      expect(
        File(p.join(root.path, 'niman-it', 'niman-it.niman-index'))
            .existsSync(),
        isTrue,
      );
      await service.prepare('de');
    });

    test('installedPacks lists the folder and refreshes on request', () async {
      expect((await service.installedPacks()).length, 2);
      await writePack(
        root.path,
        code: 'de',
        entries: [(headword: 'Haus', html: 'h')],
      );
      expect((await service.installedPacks()).length, 2);
      expect((await service.installedPacks(refresh: true)).length, 3);
      expect((await service.packFor('de'))?.id, 'niman-de');
      expect(await service.packFor('fr'), isNull);
    });

    test('after dispose a look-up is refused', () async {
      await service.dispose();
      expect(service.lookUp('caminetto', 'it'), throwsStateError);
    });
  });
}
