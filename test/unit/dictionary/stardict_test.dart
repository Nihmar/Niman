// A pack's `.ifo`, `.idx` and `.syn` (docs/records/dictionary.md, "The pack
// format"): read by hand, 32- and 64-bit offsets, and a header the engine
// cannot serve reported rather than thrown.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/stardict_idx.dart';
import 'package:niman/src/dictionary/stardict_ifo.dart';
import 'package:niman/src/dictionary/stardict_syn.dart';
import 'package:path/path.dart' as p;

import 'pack_writer.dart';

const List<PackEntry> _entries = [
  (headword: 'polish', html: '<p>verb</p>'),
  (headword: 'Polish', html: '<p>adjective</p>'),
  (headword: 'caminetto', html: '<p>fireplace</p>'),
  (headword: 'Zebra', html: '<p>z</p>'),
  (headword: 'apple', html: '<p>a</p>'),
  (headword: 'città', html: '<p>city</p>'),
];

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('niman_dict'));
  tearDown(() => root.deleteSync(recursive: true));

  group('.ifo', () {
    test('the StarDict keys and the Niman keys are read', () async {
      final dir = await writePack(
        root.path,
        code: 'sh',
        entries: _entries,
        languages: ['hr', 'sr', 'bs'],
        definitions: 'en',
        source: 'en.wiktionary',
      );
      final ifo = StardictIfo.parse(
        File(p.join(dir, 'niman-sh.ifo')).readAsStringSync(),
      )!;
      expect(ifo.version, '3.0.0');
      expect(ifo.bookName, 'Niman sh');
      expect(ifo.wordCount, 6);
      expect(ifo.idxOffsetBits, 32);
      expect(ifo.sameTypeSequence, 'h');
      expect(ifo.nimanPack, 1);
      expect(ifo.languages, ['hr', 'sr', 'bs']);
      expect(ifo.definitions, 'en');
      expect(ifo.source, 'en.wiktionary');
      expect(ifo.license, 'CC BY-SA 4.0; GFDL');
      expect(ifo.unsupportedReason, isNull);
    });

    test('a value keeps its own equals signs and CRLF lines read', () {
      final ifo = StardictIfo.parse(
        "StarDict's dict ifo file\r\nbookname=a=b\r\nniman-pack=1\r\n",
      )!;
      expect(ifo.bookName, 'a=b');
      expect(ifo.unsupportedReason, isNull);
    });

    test('a file without the magic line is not an .ifo', () {
      expect(StardictIfo.parse('bookname=x\nniman-pack=1\n'), isNull);
      expect(StardictIfo.parse(''), isNull);
    });

    test('a pack that is not format 1 is unsupported, never thrown', () {
      for (final pack in ['2', '0', 'x', null]) {
        final ifo = StardictIfo.parse(
          "StarDict's dict ifo file\nversion=3.0.0\n"
          '${pack == null ? '' : 'niman-pack=$pack'}\n',
        )!;
        expect(ifo.unsupportedReason, contains('niman-pack'));
      }
    });

    test('an offset width other than 32 and 64 is unsupported', () {
      final ifo = StardictIfo.parse(
        "StarDict's dict ifo file\nniman-pack=1\nidxoffsetbits=16\n",
      )!;
      expect(ifo.unsupportedReason, contains('idxoffsetbits'));
    });

    test('languages are lowercased and an absent key is empty', () {
      expect(
        StardictIfo.parse("StarDict's dict ifo file\nlanguages=HR, sr ,\n")!
            .languages,
        ['hr', 'sr'],
      );
      expect(
        StardictIfo.parse("StarDict's dict ifo file\n")!.languages,
        isEmpty,
      );
    });
  });

  for (final bits in [32, 64]) {
    group('.idx and .syn at $bits bits', () {
      test('entries come back in StarDict order with their place', () async {
        final dir = await writePack(
          root.path,
          code: 'it',
          entries: _entries,
          offsetBits: bits,
          compress: false,
        );
        final idx = await StardictIdx.readAll(
          p.join(dir, 'niman-it.idx'),
          offsetBits: bits,
        );
        // strcasecmp first, then strcmp: "Polish" before "polish", and
        // "Zebra" after "città".
        expect(
          [for (final e in idx) e.headword],
          ['apple', 'caminetto', 'città', 'Polish', 'polish', 'Zebra'],
        );
        // The offsets are the entries' places in the .dict, one after the
        // other.
        var offset = 0;
        for (final entry in idx) {
          expect(entry.offset, offset);
          offset += entry.size;
        }
        expect(File(p.join(dir, 'niman-it.dict')).lengthSync(), offset);
      });

      test('.syn records point at the idx entry numbers', () async {
        final dir = await writePack(
          root.path,
          code: 'it',
          entries: _entries,
          forms: {
            'caminetti': ['caminetto'],
            'ami': ['apple', 'Zebra'],
          },
          offsetBits: bits,
        );
        final syn = await StardictSyn.readAll(p.join(dir, 'niman-it.syn'));
        expect(
          [for (final s in syn) (s.word, s.entryIndex)],
          [('ami', 0), ('ami', 5), ('caminetti', 1)],
        );
      });
    });
  }

  test('a file cut in the middle of a record is reported', () async {
    final dir = await writePack(
      root.path,
      code: 'it',
      entries: _entries,
      compress: false,
    );
    final path = p.join(dir, 'niman-it.idx');
    final bytes = File(path).readAsBytesSync();
    File(path).writeAsBytesSync(bytes.sublist(0, bytes.length - 3));
    expect(StardictIdx.readAll(path), throwsA(isA<Exception>()));
  });

  test('records that straddle the read blocks are not lost', () async {
    // 120,000 entries of ~12 bytes cross the 1 MiB block several times.
    final big = [
      for (var i = 0; i < 120000; i++)
        (headword: 'w${i.toString().padLeft(6, '0')}', html: 'x'),
    ];
    final dir = await writePack(
      root.path,
      code: 'it',
      entries: big,
      compress: false,
    );
    final idx = await StardictIdx.readAll(p.join(dir, 'niman-it.idx'));
    expect(idx.length, big.length);
    expect(idx.last.headword, 'w119999');
    expect(idx.last.offset, 119999);
  });
}
