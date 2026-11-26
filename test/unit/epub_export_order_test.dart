// A folder as an EPUB, in reading order (#1308): the chapters in the tree's
// own order, `index.md` first, and a contents nested by folder — the way back
// from converting a book into notes.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/export/epub_nav.dart';
import 'package:niman/src/export/epub_package.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:niman/src/export/export_tree_book.dart';
import 'package:niman/src/export/export_tree_pages.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_epub_order_');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// Writes [files] (relative path to text) under a folder named [name].
  String folder(String name, List<String> files) {
    final dir = p.join(tmp.path, name);
    for (final file in files) {
      final target = File(p.joinAll([dir, ...file.split('/')]));
      target.parent.createSync(recursive: true);
      target.writeAsStringSync('# ${p.basenameWithoutExtension(file)}\n');
    }
    return dir;
  }

  /// Exports [dir] as a book and answers its entries as text.
  Future<Map<String, String>> exportBook(String dir) async {
    final out = p.join(tmp.path, '${p.basename(dir)}.epub');
    await TreeExport.run(
      dir: dir,
      zipPath: out,
      format: ExportTreeFormat.epub,
      language: 'en',
    );
    final archive = ZipDecoder().decodeBytes(File(out).readAsBytesSync());
    return {
      for (final file in archive.files)
        if (file.isFile) file.name: utf8.decode(file.content as List<int>),
    };
  }

  /// The hrefs of the spine, in order, as the package lists them.
  List<String> spineOf(String opf) {
    final document = XmlDocument.parse(opf);
    final hrefs = {
      for (final item in document.findAllElements('item'))
        item.getAttribute('id')!: Uri.decodeFull(item.getAttribute('href')!),
    };
    return [
      for (final ref in document.findAllElements('itemref'))
        hrefs[ref.getAttribute('idref')!]!,
    ];
  }

  group('the walk', () {
    test('lists folders first, then names as the tree sorts them', () {
      final dir = folder('tree', [
        'Chapter 10.md',
        'Chapter 2.md',
        'chapter 1.md',
        'Zed/inside.md',
        'Alpha/b.md',
        'Alpha/a.md',
        'Émile.md',
        'eve.md',
      ]);
      expect(
        [for (final entry in ExportTreePages.walk(dir).entries) entry.rel],
        [
          'Alpha',
          'Alpha/a.md',
          'Alpha/b.md',
          'Zed',
          'Zed/inside.md',
          'chapter 1.md',
          'Chapter 2.md',
          'Chapter 10.md',
          'Émile.md',
          'eve.md',
        ],
      );
    });

    test('a folder of numbered chapters is in reading order', () async {
      final dir = folder('numbered', [
        for (final n in [10, 9, 2, 1]) 'Chapter $n.md',
      ]);
      final files = await exportBook(dir);
      expect(spineOf(files['OEBPS/content.opf']!), [
        'text/Chapter 1.xhtml',
        'text/Chapter 2.xhtml',
        'text/Chapter 9.xhtml',
        'text/Chapter 10.xhtml',
      ]);
    });
  });

  group('index.md', () {
    test('opens the book wherever it sorts', () async {
      final dir = folder('book', ['01 One.md', '02 Two.md', 'index.md']);
      final files = await exportBook(dir);
      expect(spineOf(files['OEBPS/content.opf']!), [
        'text/index.xhtml',
        'text/01 One.xhtml',
        'text/02 Two.xhtml',
      ]);
      final nav = XmlDocument.parse(files['OEBPS/nav.xhtml']!);
      expect(
        [for (final a in nav.findAllElements('a')) a.innerText],
        ['index', '01 One', '02 Two'],
      );
    });

    test('is a chapter like another when it is not at the root', () {
      final dir = folder('deep', ['a.md', 'Part/index.md', 'Part/b.md']);
      final tree = ExportTreePages.walk(dir);
      expect(
        [for (final entry in ExportTreeBook.chapters(tree)) entry.rel],
        ['Part/b.md', 'Part/index.md', 'a.md'],
      );
    });
  });

  group('the nav', () {
    EpubChapterEntry chapter(
      String name, {
      String folder = '',
      bool opens = false,
    }) => (
      id: name,
      href: 'OEBPS/text/$name.xhtml',
      title: name,
      svg: false,
      folder: folder,
      opensFolder: opens,
    );

    /// The nav's outline: each entry's text, its children indented.
    String outline(List<EpubChapterEntry> chapters) {
      final nav = XmlDocument.parse(
        epubNavXhtml(chapters: chapters, title: 'T', language: 'en'),
      );
      final out = StringBuffer();
      void walk(XmlElement list, int depth) {
        for (final item in list.childElements) {
          final head = item.childElements.first;
          final href = head.getAttribute('href');
          out.writeln(
            '${'  ' * depth}${head.innerText}'
            '${href == null ? '' : ' -> ${Uri.decodeFull(href)}'}',
          );
          for (final child in item.childElements.skip(1)) {
            walk(child, depth + 1);
          }
        }
      }

      walk(nav.findAllElements('ol').first, 0);
      return out.toString();
    }

    test('nests a folder under its entry, its own page as the target', () {
      expect(
        outline([
          chapter('index'),
          chapter('00 Part One', folder: 'Part One', opens: true),
          chapter('01 First', folder: 'Part One'),
          chapter('01 Third', folder: 'Part Two'),
          chapter('02 Sub', folder: 'Part Two/Sub'),
          chapter('End'),
        ]),
        'index -> text/index.xhtml\n'
        'Part One -> text/00 Part One.xhtml\n'
        '  01 First -> text/01 First.xhtml\n'
        'Part Two\n'
        '  01 Third -> text/01 Third.xhtml\n'
        '  Sub\n'
        '    02 Sub -> text/02 Sub.xhtml\n'
        'End -> text/End.xhtml\n',
      );
    });

    test('keeps an own page that is not first as a chapter', () {
      expect(
        outline([
          chapter('Deeper', folder: 'Part/Deeper'),
          chapter('00 Part', folder: 'Part', opens: true),
        ]),
        'Part\n'
        '  Deeper\n'
        '    Deeper -> text/Deeper.xhtml\n'
        '  00 Part -> text/00 Part.xhtml\n',
      );
    });
  });

  test('a book converted into notes is its chapters in order, the index '
      'first, its parts nested', () async {
    final library = p.join(tmp.path, 'library');
    Directory(library).createSync();
    final source = writeTestEpub(
      p.join(tmp.path, 'parts.epub'),
      title: 'Parts',
      metadata:
          '<dc:creator>Someone</dc:creator>'
          '<dc:language>en</dc:language>',
      chapters: [
        (path: 'p1.xhtml', body: '<h1>Part One</h1><p>An epigraph.</p>'),
        (path: 'c1.xhtml', body: '<h1>First</h1><p>One.</p>'),
        (path: 'c2.xhtml', body: '<h1>Second</h1><p>Two.</p>'),
        (path: 'p2.xhtml', body: '<h1>Part Two</h1><p>More.</p>'),
        (path: 'c3.xhtml', body: '<h1>Third</h1><p>Three.</p>'),
      ],
      nav:
          '<ol>'
          '<li><a href="p1.xhtml">Part One</a><ol>'
          '<li><a href="c1.xhtml">First</a></li>'
          '<li><a href="c2.xhtml">Second</a></li></ol></li>'
          '<li><a href="p2.xhtml">Part Two</a><ol>'
          '<li><a href="c3.xhtml">Third</a></li></ol></li>'
          '</ol>',
    ).path;
    await convertEpub((
      source: source,
      name: null,
      libraryRoot: library,
      parent: '',
      staging: p.join(library, '.epub.niman-tmp-1'),
      oneNote: false,
      attachments: 'assets',
      words: _words,
    ));

    final files = await exportBook(p.join(library, 'Parts'));
    expect(spineOf(files['OEBPS/content.opf']!), [
      'text/index.xhtml',
      'text/01 Part One/00 Part One.xhtml',
      'text/01 Part One/01 First.xhtml',
      'text/01 Part One/02 Second.xhtml',
      'text/02 Part Two/00 Part Two.xhtml',
      'text/02 Part Two/01 Third.xhtml',
    ]);

    final nav = XmlDocument.parse(files['OEBPS/nav.xhtml']!);
    final top = nav.findAllElements('ol').first.childElements.toList();
    expect(top, hasLength(3));
    // The index, then each part an entry with its chapters under it, its
    // own page the entry's target.
    expect(
      Uri.decodeFull(top[0].getElement('a')!.getAttribute('href')!),
      'text/index.xhtml',
    );
    for (final (at, name) in [(1, 'One'), (2, 'Two')]) {
      expect(
        Uri.decodeFull(top[at].getElement('a')!.getAttribute('href')!),
        'text/0$at Part $name/00 Part $name.xhtml',
      );
      expect(top[at].getElement('ol'), isNotNull);
    }
    expect(
      [
        for (final item in top[1].getElement('ol')!.childElements)
          item.innerText,
      ],
      ['01 First', '02 Second'],
    );
  });
}
