// #25: a Notion "Markdown & CSV" export becomes a browsable, linked
// folder — page ids stripped from the names, links rewritten to follow,
// assets kept, the export's own files dropped.
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/notion.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late Directory library;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman-notion-');
    library = Directory(p.join(tmp.path, 'library'))..createSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// A 32-hex page id, as Notion appends it.
  String id(int n) => n.toString().padLeft(32, '0');

  /// Writes a zip named like a Notion export holding [entries]
  /// (path → text) and answers its path.
  String zip(Map<String, String> entries, {String name = 'Export'}) {
    final archive = Archive();
    entries.forEach((path, text) {
      archive.add(ArchiveFile.string(path, text));
    });
    final file = File(p.join(tmp.path, '$name ${id(99)}.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));
    return file.path;
  }

  String content(String rel) =>
      File(p.joinAll([library.path, ...rel.split('/')])).readAsStringSync();

  bool exists(String rel) =>
      File(p.joinAll([library.path, ...rel.split('/')])).existsSync();

  final workspace = 'My Workspace ${id(0)}';

  test('ids go, links follow, assets stay, csv and hidden drop', () async {
    final source = zip({
      '$workspace/Roadmap ${id(1)}.md':
          '# Roadmap\n\n'
          'See [Ideas](Ideas%20${id(2)}.md), '
          '[the plan](Sub/Plan%20${id(3)}.md#Steps) '
          'and [archived](/Old/Notes%20${id(4)}.md).\n\n'
          '![pic](Assets/pic%20${id(5)}.png)\n\n'
          'External [site](https://example.com/x.md) stays.\n',
      '$workspace/Ideas ${id(2)}.md': '# Ideas\n',
      '$workspace/Sub/Plan ${id(3)}.md': '# Plan\n',
      '$workspace/Old/Notes ${id(4)}.md': '# Old\n',
      '$workspace/Assets/pic ${id(5)}.png': 'png',
      '$workspace/Tasks ${id(6)}.csv': 'a,b\n',
      '$workspace/.obsidian/app.json': '{}',
      '$workspace/.hidden.md': 'hidden',
      '__MACOSX/._x': 'x',
    });

    final imported = await importNotionZip(
      source: source,
      libraryRoot: library.path,
    );

    expect(imported?.folder, 'My Workspace');
    expect(imported?.notes, 4);
    expect(imported?.assets, 1);
    final roadmap = content('My Workspace/Roadmap.md');
    expect(roadmap, contains('[Ideas](Ideas.md)'));
    expect(roadmap, contains('[the plan](Sub/Plan.md#Steps)'));
    expect(roadmap, contains('[archived](Old/Notes.md)'));
    expect(roadmap, contains('![pic](Assets/pic.png)'));
    expect(
      roadmap,
      contains('[site](https://example.com/x.md)'),
      reason: 'a link out of the export is left alone',
    );
    expect(exists('My Workspace/Sub/Plan.md'), isTrue);
    expect(exists('My Workspace/Old/Notes.md'), isTrue);
    expect(exists('My Workspace/Assets/pic.png'), isTrue);
    expect(exists('My Workspace/Tasks ${id(6)}.csv'), isFalse);
    expect(exists('My Workspace/.hidden.md'), isFalse);
    expect(exists('My Workspace/.obsidian'), isFalse);
    expect(exists('__MACOSX'), isFalse);
  });

  test(
    'two pages that clean to one name are kept apart, links and all',
    () async {
      final root = 'Workspace ${id(7)}';
      final source = zip({
        '$root/Notes ${id(8)}.md': 'first\n',
        '$root/Notes ${id(9)}.md': 'second\n\n[first](Notes%20${id(8)}.md)\n',
      });

      await importNotionZip(source: source, libraryRoot: library.path);

      expect(exists('Workspace/Notes.md'), isTrue);
      expect(exists('Workspace/Notes_2.md'), isTrue);
      expect(content('Workspace/Notes_2.md'), contains('[first](Notes.md)'));
    },
  );

  test('a zip with no notes imports nothing, and creates nothing', () async {
    final source = zip({'readme.txt': 'nothing to browse', 'pic.png': 'png'});

    final imported = await importNotionZip(
      source: source,
      libraryRoot: library.path,
    );

    expect(imported, isNull);
    expect(library.listSync(), isEmpty);
  });

  test('a page id with dashes is stripped too', () async {
    const root = 'Vault 4a1b2c3d-4e5f-6071-8293-a4b5c6d7e8f9';
    final source = zip({
      '$root/Roadmap 5b2c3d4e-5f60-7182-93a4-b5c6d7e8f901.md': '# Roadmap\n',
    });

    final imported = await importNotionZip(
      source: source,
      libraryRoot: library.path,
    );

    expect(imported?.folder, 'Vault');
    expect(exists('Vault/Roadmap.md'), isTrue);
  });

  test(
    'an entry past the byte budget is refused, and nothing is written',
    () async {
      // The guard reads the expansion the entries declare, not the archive's
      // size: this one declares 2 GiB while the zip holds a handful of bytes,
      // the shape a zip bomb has. The old import inflated it whole (#382).
      final archive = Archive()
        ..add(
          ArchiveFile.string('$workspace/Big ${id(1)}.md', 'x')..size = 2 << 30,
        );
      final source = File(p.join(tmp.path, 'Export ${id(99)}.zip'))
        ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

      await expectLater(
        importNotionZip(source: source.path, libraryRoot: library.path),
        throwsA(isA<ArchiveException>()),
      );

      expect(library.listSync(), isEmpty, reason: 'nothing was written');
    },
  );
}
