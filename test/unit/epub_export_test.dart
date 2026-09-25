// A note and a folder as EPUB (#303): the container's shape, XHTML that
// parses, the pictures inside it, and links between chapters.
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_epub_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Map<String, String> textEntries(String path) {
    final archive = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
    return <String, String>{
      for (final file in archive.files)
        if (file.isFile) file.name: utf8.decode(file.content as List<int>),
    };
  }

  /// Every XML-flavoured entry parses: the format's own floor.
  void expectParses(Map<String, String> files) {
    for (final entry in files.entries) {
      final name = entry.key;
      if (name.endsWith('.xhtml') || name.endsWith('.opf')) {
        XmlDocument.parse(entry.value);
      }
    }
  }

  test('a note is a one-chapter book, its picture inside', () async {
    await File(p.join(root.path, 'photo.png')).writeAsBytes(<int>[1, 2, 3]);
    final payload = await exportNoteEpub(
      text:
          '# Title\n\nA formula, \$x^2\$, and a picture:\n\n![p](photo.png)\n',
      title: 'Title',
      path: 'Title.md',
      root: root.path,
      language: 'en',
    );
    expect(payload.name, 'Title.epub');
    expect(payload.mimeType, 'application/epub+zip');

    final file = p.join(root.path, 'out.epub');
    await File(file).writeAsBytes(payload.bytes);
    final files = textEntries(file);
    expect(files.keys, contains('META-INF/container.xml'));
    expect(files.keys, contains('OEBPS/content.opf'));
    expect(files.keys, contains('OEBPS/nav.xhtml'));
    expect(files.keys, contains('OEBPS/text/note.xhtml'));
    expect(files.keys, contains('OEBPS/style.css'));
    expect(files.keys.any((name) => name.startsWith('OEBPS/images/')), isTrue);
    expectParses(files);

    final chapter = files['OEBPS/text/note.xhtml']!;
    expect(chapter, contains('<svg'));
    expect(chapter, contains('src="../images/'));
    final opf = files['OEBPS/content.opf']!;
    expect(opf, contains('properties="nav"'));
    expect(opf, contains('media-type="image/png"'));
    expect(opf, contains('media-type="application/xhtml+xml"'));
    final nav = files['OEBPS/nav.xhtml']!;
    expect(nav, contains('href="text/note.xhtml"'));
  });

  test('the mimetype entry is first and stored', () async {
    final payload = await exportNoteEpub(
      text: '# T\n',
      title: 'T',
      path: 'T.md',
      root: root.path,
      language: 'en',
    );
    final archive = ZipDecoder().decodeBytes(payload.bytes);
    expect(archive.files.first.name, 'mimetype');
    expect(archive.files.first.compression, CompressionType.none);
    expect(
      utf8.decode(archive.files.first.content as List<int>),
      'application/epub+zip',
    );
  });

  test(
    'a folder is one book, its notes chapters that link to each other',
    () async {
      final notes = p.join(root.path, 'Notes');
      await Directory(p.join(notes, 'sub')).create(recursive: true);
      await File(p.join(notes, 'a.md'))
          .writeAsString('# A\n\nSee [[b]] and [[sub/c#Part|cee]].\n');
      await File(p.join(notes, 'b.md')).writeAsString('# B\n');
      await File(p.join(notes, 'sub', 'c.md'))
          .writeAsString('# C\n\n## Part\n');

      final out = p.join(root.path, 'book.epub');
      await TreeExport.run(
        dir: notes,
        zipPath: out,
        format: ExportTreeFormat.epub,
        language: 'en',
      );

      final files = textEntries(out);
      expect(
        files.keys,
        containsAll(<String>[
          'OEBPS/text/a.xhtml',
          'OEBPS/text/b.xhtml',
          'OEBPS/text/sub/c.xhtml',
        ]),
      );
      expectParses(files);

      // A chapter's neighbour is where the same relative name says it is, and
      // the heading anchor survives.
      final a = files['OEBPS/text/a.xhtml']!;
      expect(a, contains('href="b.xhtml"'));
      expect(a, contains('href="sub/c.xhtml#part"'));

      // One nav entry per chapter, in spine order.
      final nav = files['OEBPS/nav.xhtml']!;
      expect(nav, contains('href="text/a.xhtml"'));
      expect(nav, contains('href="text/b.xhtml"'));
      expect(nav, contains('href="text/sub/c.xhtml"'));
      final opf = files['OEBPS/content.opf']!;
      expect(
        RegExp(r'<itemref idref="ch\d+" />').allMatches(opf),
        hasLength(3),
      );
    },
  );

  test("the app's own reader opens the book it wrote", () async {
    final notes = p.join(root.path, 'Notes');
    await Directory(notes).create(recursive: true);
    await File(p.join(notes, 'photo.png')).writeAsBytes(<int>[1, 2, 3]);
    await File(p.join(notes, 'a.md'))
        .writeAsString('# Alpha\n\n![[photo.png]]\n\nSee [[b]].\n');
    await File(p.join(notes, 'b.md')).writeAsString('# Beta\n');
    final out = p.join(root.path, 'book.epub');
    await TreeExport.run(
      dir: notes,
      zipPath: out,
      format: ExportTreeFormat.epub,
      language: 'en',
    );

    final document = readEpub(out, p.join(root.path, 'pictures'));
    expect(document.title, 'Notes');
    expect(document.markdown, contains('Alpha'));
    expect(document.markdown, contains('Beta'));
    expect(
      document.contents.map((entry) => entry.title),
      containsAll(<String>['a', 'b']),
    );
    expect(document.pictures, hasLength(1));
  });

  test('a picture shared by two notes goes in once', () async {
    final notes = p.join(root.path, 'Notes');
    await Directory(notes).create(recursive: true);
    await File(p.join(notes, 'photo.png')).writeAsBytes(<int>[1, 2, 3]);
    await File(p.join(notes, 'a.md')).writeAsString('![[photo.png]]\n');
    await File(p.join(notes, 'b.md')).writeAsString('![[photo.png]]\n');

    final out = p.join(root.path, 'book.epub');
    await TreeExport.run(
      dir: notes,
      zipPath: out,
      format: ExportTreeFormat.epub,
      language: 'en',
    );
    final files = textEntries(out);
    expect(
      files.keys.where((name) => name.startsWith('OEBPS/images/')),
      hasLength(1),
    );
  });
}
