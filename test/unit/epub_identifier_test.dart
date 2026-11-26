// A book's identifier (#1307): the same note or folder exported twice is one
// book to a reader, so the package's `unique-identifier` is the frontmatter's
// own or a name-based UUID of the path, never a random one.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/epub_identifier.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_epub_id_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  /// The package of the book at [path].
  String opfOf(String path) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    return utf8.decode(
      archive.findFile('OEBPS/content.opf')!.content as List<int>,
    );
  }

  /// The identifiers [opf] names: every `dc:identifier`, and the one the
  /// package points at.
  ({List<String> all, String unique}) identifiersOf(String opf) {
    final all = [
      for (final m in RegExp(
        '<dc:identifier[^>]*>([^<]*)</dc:identifier>',
      ).allMatches(opf))
        m[1]!,
    ];
    final pub = RegExp('<dc:identifier id="pub-id">([^<]*)</dc:identifier>')
        .firstMatch(opf)![1]!;
    return (all: all, unique: pub);
  }

  Future<String> exportNote(String text, String path) async {
    final payload = await exportNoteEpub(
      text: text,
      title: 'T',
      path: path,
      root: root.path,
      language: 'en',
    );
    final file = p.join(root.path, 'out-${path.hashCode}.epub');
    await File(file).writeAsBytes(payload.bytes);
    return opfOf(file);
  }

  group('uuidV5', () {
    test('is the RFC 4122 name-based UUID', () {
      // The DNS namespace and "www.example.com": the reference vector.
      expect(
        uuidV5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'www.example.com'),
        '2ed6657d-e927-568b-95e1-2665a8aea6a2',
      );
    });
  });

  group('an ISBN', () {
    test('is urn:isbn: and its digits', () {
      expect(epubIsbnUrn('978-3-16-148410-0'), 'urn:isbn:9783161484100');
      expect(epubIsbnUrn('9780441013593'), 'urn:isbn:9780441013593');
      expect(epubIsbnUrn('urn:isbn:9780441013593'), 'urn:isbn:9780441013593');
      expect(epubIsbnUrn('0-306-40615-2'), 'urn:isbn:0306406152');
      expect(epubIsbnUrn('0-8044-2957-X'), 'urn:isbn:080442957X');
    });

    test('is not any number of the right length', () {
      expect(epubIsbnUrn('1234567890'), isNull);
      expect(epubIsbnUrn('9783161484101'), isNull);
      expect(epubIsbnUrn('urn:uuid:123'), isNull);
      expect(epubIsbnUrn('my-book'), isNull);
    });
  });

  test('two exports of one note carry one identifier', () async {
    final first = identifiersOf(await exportNote('# T\n', 'Notes/T.md'));
    final second = identifiersOf(
      await exportNote('# T\n\nMore.\n', 'Notes/T.md'),
    );
    expect(first.unique, startsWith('urn:uuid:'));
    expect(second.unique, first.unique);
    expect(first.all, [first.unique]);
  });

  test('two notes are two books', () async {
    final one = identifiersOf(await exportNote('# T\n', 'Notes/One.md'));
    final two = identifiersOf(await exportNote('# T\n', 'Notes/Two.md'));
    expect(one.unique, isNot(two.unique));
  });

  test('the identifier is named by the library path, not the host', () async {
    final opf = identifiersOf(await exportNote('# T\n', 'Notes/T.md'));
    expect(opf.unique, 'urn:uuid:${uuidV5(epubNamespace, 'Notes/T.md')}');
  });

  test('a note with isbn: is urn:isbn:, and only once', () async {
    final ids = identifiersOf(
      await exportNote(
        '---\nisbn: 978-3-16-148410-0\n---\n# T\n',
        'Notes/T.md',
      ),
    );
    expect(ids.unique, 'urn:isbn:9783161484100');
    expect(ids.all, ['urn:isbn:9783161484100']);
  });

  test('an identifier: that is not an ISBN is the book as written', () async {
    final ids = identifiersOf(
      await exportNote(
        '---\nidentifier: urn:uuid:11111111-2222-3333-4444-555555555555\n'
            '---\n# T\n',
        'Notes/T.md',
      ),
    );
    expect(ids.unique, 'urn:uuid:11111111-2222-3333-4444-555555555555');
    expect(ids.all, hasLength(1));
  });

  group('a folder', () {
    Future<String> exportFolder(String libraryPath, {String? index}) async {
      final dir = Directory(p.join(root.path, 'Book'));
      await dir.create(recursive: true);
      await File(p.join(dir.path, 'a.md')).writeAsString('# A\n');
      if (index != null) {
        await File(p.join(dir.path, 'index.md')).writeAsString(index);
      }
      final out = p.join(root.path, 'folder-${libraryPath.hashCode}.epub');
      await TreeExport.run(
        dir: dir.path,
        zipPath: out,
        format: ExportTreeFormat.epub,
        language: 'en',
        libraryPath: libraryPath,
      );
      final opf = opfOf(out);
      File(out).deleteSync();
      return opf;
    }

    test('is the same book on every export, another folder another', () async {
      final first = identifiersOf(await exportFolder('Shelf/Book'));
      final again = identifiersOf(await exportFolder('Shelf/Book'));
      final other = identifiersOf(await exportFolder('Shelf/Other'));
      expect(again.unique, first.unique);
      expect(other.unique, isNot(first.unique));
      expect(first.unique, 'urn:uuid:${uuidV5(epubNamespace, 'Shelf/Book')}');
    });

    test("takes index.md's isbn: for its identifier", () async {
      final ids = identifiersOf(
        await exportFolder(
          'Shelf/Book',
          index: '---\nisbn: 9780441013593\n---\n',
        ),
      );
      expect(ids.unique, 'urn:isbn:9780441013593');
      expect(ids.all, hasLength(1));
    });
  });
}
