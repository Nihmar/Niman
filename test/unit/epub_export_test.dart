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
    // No `cover:` frontmatter, no cover page.
    expect(files.keys, isNot(contains('OEBPS/cover.xhtml')));
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

  test("a cover named in the frontmatter is the book's first page", () async {
    await File(p.join(root.path, 'photo.png')).writeAsBytes(<int>[1, 2, 3]);
    final payload = await exportNoteEpub(
      text: '---\ntitle: With cover\ncover: photo.png\n---\n# T\n',
      title: 'With cover',
      path: 'With cover.md',
      root: root.path,
      language: 'en',
    );
    final file = p.join(root.path, 'cover.epub');
    await File(file).writeAsBytes(payload.bytes);
    final files = textEntries(file);
    expect(files.keys, contains('OEBPS/cover.xhtml'));
    expect(files.keys, contains('OEBPS/images/cover.png'));
    expectParses(files);

    final opf = files['OEBPS/content.opf']!;
    expect(opf, contains('properties="cover-image"'));
    expect(opf, contains('<meta name="cover" content="cover-image" />'));
    // The cover page opens the book, before any chapter.
    final coverAt = opf.indexOf('<itemref idref="cover-page" />');
    final chapterAt = opf.indexOf('<itemref idref="ch1" />');
    expect(coverAt, greaterThanOrEqualTo(0));
    expect(coverAt, lessThan(chapterAt));
    // The cover page sits at the package's root, so its picture is one
    // directory down, not up.
    expect(files['OEBPS/cover.xhtml'], contains('src="images/cover.png"'));
  });

  test('the frontmatter metadatas the package', () async {
    final payload = await exportNoteEpub(
      text:
          '---\n'
          'title: The Book\n'
          'author: [Ada Lovelace, Alan Turing]\n'
          'language: it\n'
          'description: What it is.\n'
          'publisher: Niman Press\n'
          'published: 2026-09-25\n'
          'tags: [geometry, notes]\n'
          'series: Notes\n'
          'series_index: 2\n'
          'rights: Public domain\n'
          'isbn: 978-3-16-148410-0\n'
          '---\n# Chapter\n',
      title: 'ignored',
      path: 'Book.md',
      root: root.path,
      language: 'en',
    );
    final file = p.join(root.path, 'meta.epub');
    await File(file).writeAsBytes(payload.bytes);
    final files = textEntries(file);
    expectParses(files);
    final opf = files['OEBPS/content.opf']!;
    // The frontmatter's own title and language win over the export's.
    expect(opf, contains('<dc:title>The Book</dc:title>'));
    expect(opf, contains('<dc:language>it</dc:language>'));
    expect(opf, contains('<dc:creator>Ada Lovelace</dc:creator>'));
    expect(opf, contains('<dc:creator>Alan Turing</dc:creator>'));
    expect(opf, contains('<dc:description>What it is.</dc:description>'));
    expect(opf, contains('<dc:publisher>Niman Press</dc:publisher>'));
    expect(opf, contains('<dc:date>2026-09-25</dc:date>'));
    expect(opf, contains('<dc:subject>geometry</dc:subject>'));
    expect(opf, contains('<dc:subject>notes</dc:subject>'));
    expect(opf, contains('<dc:rights>Public domain</dc:rights>'));
    expect(opf, contains('<dc:identifier>978-3-16-148410-0</dc:identifier>'));
    expect(opf, contains('id="series">Notes</meta>'));
    expect(opf, contains('property="group-position">2</meta>'));
    expect(files['OEBPS/text/note.xhtml'], contains('xml:lang="it"'));
  });

  test("a folder book takes its index.md's cover and metadata", () async {
    final notes = p.join(root.path, 'Notes');
    await Directory(notes).create(recursive: true);
    await File(p.join(notes, 'photo.png')).writeAsBytes(<int>[1, 2, 3]);
    await File(p.join(notes, 'index.md')).writeAsString(
      '---\ncover: photo.png\nauthor: Ada Lovelace\n---\n# Index\n',
    );
    await File(p.join(notes, 'a.md')).writeAsString('# A\n');
    await File(p.join(notes, 'b.md')).writeAsString('# B\n');
    final out = p.join(root.path, 'book.epub');
    await TreeExport.run(
      dir: notes,
      zipPath: out,
      format: ExportTreeFormat.epub,
      language: 'en',
    );
    final files = textEntries(out);
    expect(files.keys, contains('OEBPS/cover.xhtml'));
    final opf = files['OEBPS/content.opf']!;
    expect(opf, contains('properties="cover-image"'));
    expect(opf, contains('<dc:creator>Ada Lovelace</dc:creator>'));
    // `index.md` is a chapter like any other.
    expect(files.keys, contains('OEBPS/text/index.xhtml'));
  });

  test("a cover in a chapter is not the book's", () async {
    final notes = p.join(root.path, 'Notes');
    await Directory(notes).create(recursive: true);
    await File(p.join(notes, 'photo.png')).writeAsBytes(<int>[1, 2, 3]);
    await File(p.join(notes, 'a.md'))
        .writeAsString('---\ncover: photo.png\n---\n# A\n');
    final out = p.join(root.path, 'book.epub');
    await TreeExport.run(
      dir: notes,
      zipPath: out,
      format: ExportTreeFormat.epub,
      language: 'en',
    );
    final files = textEntries(out);
    expect(files.keys, isNot(contains('OEBPS/cover.xhtml')));
  });

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
