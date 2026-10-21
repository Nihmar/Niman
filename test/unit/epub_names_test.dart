// How a book spells the names of its files and anchors (#1138): raw UTF-8
// (`cité.xhtml`, the way most books with accents or CJK names write them),
// percent-encoded (`cit%C3%A9.xhtml`), or with a `%` that opens no escape.
// All of them open in the reader's parse and convert to notes.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('niman_epub_names_'));

  tearDown(() => tmp.deleteSync(recursive: true));

  EpubBook parse(String path) {
    final input = InputFileStream(path);
    addTearDown(input.closeSync);
    return parseEpub(EpubArchive.open(input));
  }

  Future<String> convert(String source) async {
    final library = Directory(p.join(tmp.path, 'library'))..createSync();
    final converted = await convertEpub((
      source: source,
      libraryRoot: library.path,
      parent: '',
      staging: p.join(library.path, '.epub.niman-tmp-1'),
      oneNote: false,
      attachments: 'assets',
      words: _words,
    ));
    return p.join(library.path, converted.made);
  }

  // Two chapters named [first] and [second], the manifest, the contents and
  // a link between them writing those names as [spell] does.
  String book(
    String first,
    String second, {
    String Function(String name) spell = _same,
  }) => writeTestEpub(
    p.join(tmp.path, 'book.epub'),
    title: 'Names',
    chapters: [
      (
        path: first,
        body:
            '<h1>One</h1><p>See <a href="${spell(second)}#there">two</a>.</p>',
      ),
      (path: second, body: '<h1>Two</h1><h2 id="there">There</h2><p>Hi.</p>'),
    ],
    hrefs: {first: spell(first), second: spell(second)},
    nav:
        '<ol><li><a href="${spell(first)}">One</a></li>'
        '<li><a href="${spell(second)}">Two</a></li></ol>',
  ).path;

  for (final (label, first, second) in [
    ('accents', 'cité.xhtml', 'Capítulo dos.xhtml'),
    ('CJK', '日本語.xhtml', '第二章.xhtml'),
    ('Cyrillic', 'глава.xhtml', 'часть два.xhtml'),
  ]) {
    group('a book of $label names', () {
      for (final (how, spell) in [
        ('raw', _same),
        ('percent-encoded', _encoded),
      ]) {
        test('$how: the parse finds its chapters, contents and links', () {
          final parsed = parse(book(first, second, spell: spell));
          expect(parsed.chapters.map((c) => c.file), [
            'OEBPS/$first',
            'OEBPS/$second',
          ]);
          expect(parsed.contents.map((e) => e.file), [
            'OEBPS/$first',
            'OEBPS/$second',
          ]);
          expect(parsed.links.single.file, 'OEBPS/$second');
          expect(parsed.links.single.fragment, 'there');
        });

        test('$how: the conversion writes its notes', () async {
          final folder = await convert(book(first, second, spell: spell));
          expect(
            File(p.join(folder, '01 One.md')).readAsStringSync(),
            contains('[two](<02%20Two.md#There>)'),
          );
          expect(File(p.join(folder, '02 Two.md')).existsSync(), isTrue);
        });
      }
    });
  }

  test('a name with a stray % or a byte that is not UTF-8 is a name', () {
    // `100%.xhtml` opens no escape; `%FF` is not UTF-8. Neither ends the
    // parse: the first is found, the second names a file the book lacks.
    final parsed = parse(
      writeTestEpub(
        p.join(tmp.path, 'odd.epub'),
        chapters: [
          (path: '100%.xhtml', body: '<h1>Hundred</h1><p>Text.</p>'),
          (path: 'gone.xhtml', body: '<p>Never read.</p>'),
        ],
        omit: {'gone.xhtml'},
        hrefs: {'gone.xhtml': 'a%FFb.xhtml'},
        nav:
            '<ol><li><a href="100%.xhtml">Hundred</a></li>'
            '<li><a href="a%FFb.xhtml">Lost</a></li></ol>',
      ).path,
    );
    expect(parsed.chapters.map((c) => c.file), ['OEBPS/100%.xhtml']);
    expect(parsed.contents, hasLength(2));
  });
}

String _same(String name) => name;

String _encoded(String name) => Uri.encodeComponent(name);
