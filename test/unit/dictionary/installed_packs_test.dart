// Which packs the dictionaries folder holds and which serves a language
// (docs/records/dictionary.md, decision 14): `niman-<code>` folders with a
// readable `.ifo`, `niman-sh` serving `hr`, `sr` and `bs`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/installed_packs.dart';
import 'package:path/path.dart' as p;

import 'fixture_packs.dart';
import 'pack_writer.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('niman_packs'));
  tearDown(() => root.deleteSync(recursive: true));

  test('a folder that is not there holds no packs', () async {
    expect(await InstalledPacks.list(p.join(root.path, 'absent')), isEmpty);
    expect(await InstalledPacks.list(root.path), isEmpty);
  });

  test('packs are listed by id, with the languages they serve', () async {
    await writeFixturePacks(root.path);
    await writePack(
      root.path,
      code: 'sh',
      entries: [(headword: 'ku\u{0107}a', html: 'house')],
      languages: ['hr', 'sr', 'bs'],
    );
    final packs = await InstalledPacks.list(root.path);
    expect(
      [for (final pack in packs) pack.id],
      ['niman-en', 'niman-it', 'niman-sh'],
    );
    expect(packs.every((pack) => pack.isAvailable), isTrue);
    expect(packs.first.directory, p.join(root.path, 'niman-en'));
    expect(packs.first.languages, ['en']);
    expect(packs.last.languages, ['hr', 'sr', 'bs']);
    expect(packs.first.credit.license, 'CC BY-SA 4.0; GFDL');
    expect(packs.first.credit.source, 'en.wiktionary');
  });

  test('niman-sh serves hr, sr and bs, and a region does not matter', () async {
    await writePack(
      root.path,
      code: 'sh',
      entries: [(headword: 'ku\u{0107}a', html: 'house')],
      languages: ['hr', 'sr', 'bs'],
    );
    await writeFixturePacks(root.path);
    final packs = await InstalledPacks.list(root.path);
    for (final language in ['hr', 'sr', 'bs', 'hr-HR', 'sr_Latn', 'BS']) {
      expect(
        InstalledPacks.forLanguage(packs, language)?.id,
        'niman-sh',
        reason: language,
      );
    }
    expect(InstalledPacks.forLanguage(packs, 'it')?.id, 'niman-it');
    expect(InstalledPacks.forLanguage(packs, 'pt-BR'), isNull);
    expect(InstalledPacks.forLanguage(packs, 'sh'), isNull);
    expect(InstalledPacks.forLanguage(packs, ''), isNull);
    expect(packs.last.serves('hr-HR'), isTrue);
    expect(packs.last.serves('it'), isFalse);
  });

  test('a pack without a languages key serves the code in its id', () async {
    await writePack(
      root.path,
      code: 'de',
      entries: [(headword: 'Haus', html: 'house')],
    );
    final ifo = File(p.join(root.path, 'niman-de', 'niman-de.ifo'));
    ifo.writeAsStringSync(
      ifo
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.startsWith('languages='))
          .join('\n'),
    );
    final packs = await InstalledPacks.list(root.path);
    expect(packs.single.languages, ['de']);
    expect(InstalledPacks.forLanguage(packs, 'de')?.id, 'niman-de');
  });

  test('a pack of another format is listed, unavailable, and never '
      'chosen', () async {
    await writePack(
      root.path,
      code: 'xx',
      entries: [(headword: 'a', html: 'b')],
      nimanPack: 2,
    );
    final packs = await InstalledPacks.list(root.path);
    expect(packs.single.isAvailable, isFalse);
    expect(packs.single.unavailableReason, contains('niman-pack'));
    expect(InstalledPacks.forLanguage(packs, 'xx'), isNull);
  });

  test('a pack with a file missing is unavailable, a folder without an '
      '.ifo or of another name is not a pack', () async {
    await writePack(
      root.path,
      code: 'aa',
      entries: [(headword: 'a', html: 'b')],
    );
    File(p.join(root.path, 'niman-aa', 'niman-aa.dict.dz')).deleteSync();
    await writePack(
      root.path,
      code: 'bb',
      entries: [(headword: 'a', html: 'b')],
    );
    File(p.join(root.path, 'niman-bb', 'niman-bb.idx')).deleteSync();
    await writePack(
      root.path,
      code: 'cc',
      entries: [(headword: 'a', html: 'b')],
    );
    File(p.join(root.path, 'niman-cc', 'niman-cc.ifo')).deleteSync();
    Directory(p.join(root.path, 'other')).createSync();
    Directory(p.join(root.path, 'niman-')).createSync();
    File(p.join(root.path, 'niman-it')).writeAsStringSync('a file');
    File(p.join(root.path, 'niman-dd.ifo')).writeAsStringSync('x');
    final packs = await InstalledPacks.list(root.path);
    expect([for (final pack in packs) pack.id], ['niman-aa', 'niman-bb']);
    expect(packs.first.unavailableReason, 'no .dict');
    expect(packs.last.unavailableReason, 'no .idx');
  });

  test('a file that is not an .ifo is not a pack', () async {
    Directory(p.join(root.path, 'niman-zz')).createSync();
    File(p.join(root.path, 'niman-zz', 'niman-zz.ifo'))
        .writeAsStringSync('not an ifo');
    expect(await InstalledPacks.list(root.path), isEmpty);
  });
}
