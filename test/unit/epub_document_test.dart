// An EPUB, read into one Markdown text: its chapters in spine order, its
// table of contents and its own links as lines of that text, its pictures
// extracted to the cache.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

void main() {
  late Directory dir;
  late String pictures;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_epub_');
    pictures = p.join(dir.path, 'pictures');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  String book(String name) => p.join(dir.path, name);

  group('an EPUB 3, its contents in the nav', () {
    late EpubDocument document;
    const png = [0x89, 0x50, 0x4E, 0x47, 1, 2, 3];
    setUp(() {
      final file = writeTestEpub(
        book('three.epub'),
        title: 'Three',
        chapters: [
          (
            path: 'text/ch1.xhtml',
            body:
                '<h1 id="c1">One</h1>'
                '<p>Go to <a href="ch2.xhtml#deep">two</a>.</p>'
                '<p><img src="../images/pic.png" alt="P"/></p>',
          ),
          (
            path: 'text/ch2.xhtml',
            body:
                '<h1>Two</h1><p>a</p><p id="deep">deep</p>'
                '<p><a href="ch1.xhtml">back</a> '
                '<a href="https://example.com">out</a> '
                '<a href="#deep">here</a></p>',
          ),
        ],
        nav:
            '<ol><li><a href="text/ch1.xhtml">One</a>'
            '<ol><li><a href="text/ch2.xhtml#deep">Deep</a></li></ol></li>'
            '<li><a href="text/ch2.xhtml">Two</a></li></ol>',
        files: {'OEBPS/images/pic.png': png},
      );
      document = readEpub(file.path, pictures);
    });

    test('its chapters are one text, a rule between them', () {
      expect(document.title, 'Three');
      expect(
        document.markdown,
        '# One\n\nGo to [two](<epub-link:0>).\n\n![P](epub-picture:0)'
        '\n\n---\n\n'
        '# Two\n\na\n\ndeep\n\n'
        '[back](<epub-link:1>) [out](<https://example.com>) '
        '[here](<epub-link:2>)\n',
      );
    });

    test('its contents are lines of the text, nested', () {
      expect(document.contents, [
        (title: 'One', line: 0, depth: 0),
        (title: 'Deep', line: 12, depth: 1),
        (title: 'Two', line: 8, depth: 0),
      ]);
      final lines = document.markdown.split('\n');
      expect(lines[8], '# Two');
      expect(lines[12], 'deep');
    });

    test('a line is a place in its chapter, and back (#281)', () {
      expect(document.chapters, [
        (file: 'OEBPS/text/ch1.xhtml', line: 0),
        (file: 'OEBPS/text/ch2.xhtml', line: 8),
      ]);
      const deep = EpubLocation(
        chapter: 'OEBPS/text/ch2.xhtml',
        line: 4,
        fraction: 0.5,
      );
      expect(document.locationAt(12, 0.5), deep);
      expect(document.lineOfLocation(deep), 12);
    });

    test('a place past its chapter stays in it; a lost chapter is none', () {
      const past = EpubLocation(chapter: 'OEBPS/text/ch1.xhtml', line: 50);
      expect(document.lineOfLocation(past), 7);
      const last = EpubLocation(chapter: 'OEBPS/text/ch2.xhtml', line: 50);
      expect(document.lineOfLocation(last), 14);
      const gone = EpubLocation(chapter: 'OEBPS/text/ch9.xhtml', line: 1);
      expect(document.lineOfLocation(gone), isNull);
    });

    test('a chapter is found whatever its case, or by its name (#282)', () {
      for (final chapter in [
        'oebps/TEXT/ch2.xhtml',
        'ch2.xhtml',
        'CH2.XHTML',
      ]) {
        expect(
          document.lineOfLocation(EpubLocation(chapter: chapter, line: 4)),
          12,
          reason: chapter,
        );
      }
      // A name is a whole file name, not the end of one.
      expect(
        document.lineOfLocation(
          const EpubLocation(chapter: 'h2.xhtml', line: 0),
        ),
        isNull,
      );
    });

    test('its links go to lines; the ones leaving it do not', () {
      expect(document.lineOfLink('epub-link:0'), 12);
      expect(document.lineOfLink('epub-link:1'), 0);
      expect(document.lineOfLink('epub-link:2'), 12);
      expect(document.lineOfLink('https://example.com'), isNull);
      expect(document.lineOfLink('epub-link:9'), isNull);
    });

    test('its pictures are on disk, once', () {
      final path = document.pictures['epub-picture:0'];
      expect(path, p.join(pictures, '0.png'));
      expect(File(path!).readAsBytesSync(), png);
      final modified = File(path).lastModifiedSync();
      final again = readEpub(book('three.epub'), pictures);
      expect(again.pictures, document.pictures);
      expect(File(path).lastModifiedSync(), modified);
    });
  });

  test('an EPUB 2: its NCX, a prefixed OPF, a chapter missing', () {
    final file = writeTestEpub(
      book('two.epub'),
      title: 'Two',
      prefix: true,
      chapters: [
        (path: 'a.xhtml', body: '<h2>A</h2>'),
        (path: 'missing.xhtml', body: '<p>gone</p>'),
        (path: 'b.xhtml', body: '<p>B</p>'),
      ],
      omit: {'missing.xhtml'},
      ncx:
          ncxPoint('A', 'a.xhtml', ncxPoint('B', 'b.xhtml')) +
          ncxPoint('Missing', 'missing.xhtml'),
    );
    final document = readEpub(file.path, pictures);
    expect(document.title, 'Two');
    expect(document.markdown, '## A\n\n---\n\nB\n');
    expect(document.contents, [
      (title: 'A', line: 0, depth: 0),
      (title: 'B', line: 4, depth: 1),
    ]);
    expect(document.pictures, isEmpty);
    expect(Directory(pictures).existsSync(), isFalse);
  });

  test('a book with no title is named by its file', () {
    final file = writeTestEpub(
      book('Nameless.epub'),
      title: ' ',
      chapters: [(path: 'a.xhtml', body: '<p>a</p>')],
    );
    expect(readEpub(file.path, pictures).title, 'Nameless');
  });

  test('a file that is not an EPUB it can read is a FormatException', () {
    final text = File(book('text.epub'))..writeAsStringSync('not a zip');
    expect(() => readEpub(text.path, pictures), throwsFormatException);
    final empty = writeTestEpub(book('empty.epub'), chapters: []);
    expect(() => readEpub(empty.path, pictures), throwsFormatException);
  });

  test("a book's pictures have a folder of their own, per version", () {
    final file = writeTestEpub(
      book('v.epub'),
      chapters: [(path: 'a.xhtml', body: '<p>a</p>')],
    );
    final first = pictureDirOf(file.path, dir.path);
    expect(p.dirname(first), dir.path);
    expect(pictureDirOf(file.path, dir.path), first);
    file.writeAsStringSync('changed');
    expect(pictureDirOf(file.path, dir.path), isNot(first));
  });
}
