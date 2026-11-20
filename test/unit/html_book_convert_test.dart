// Converting an HTML book to notes (#1294): the job end to end into a
// temporary library — an AO3 work a note a chapter and in one note, a work
// of one chapter, a book with no profile — its links, its pictures, its
// refusals, its progress, and a stop that leaves nothing behind.
//
// HTML is written in pieces, and a space between two would be a word of
// the page: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/html/book/html_book_job.dart';
import 'package:niman/src/import/html/book/html_book_preview.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_convert_types.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:path/path.dart' as p;

const List<int> _png = [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3];

String _name(List<int> bytes, String extension) =>
    '${sha256.convert(bytes)}$extension';

/// A paragraph of [length] characters of placeholder words.
String _paragraph(int length) {
  final words = StringBuffer();
  while (words.length < length) {
    words.write('lorem ipsum dolor ');
  }
  return '<p>${words.toString().substring(0, length)}</p>';
}

void main() {
  late Directory tmp;
  late String library;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_html_book_');
    library = p.join(tmp.path, 'library');
    Directory(library).createSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  /// A copy of a fixture in the folder a page is saved in, with its pictures.
  String fixture(String name) {
    final file = File(p.join(tmp.path, 'saved', name))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(
        File('test/fixtures/html_book/$name').readAsBytesSync(),
      );
    return file.path;
  }

  String page(String name, String html) {
    final file = File(p.join(tmp.path, 'saved', name))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(html);
    return file.path;
  }

  HtmlConvertRequest request(
    String source, {
    HtmlBookSplit split = HtmlBookSplit.chapters,
    String parent = '',
    LinkType linkType = LinkType.wikilink,
  }) => (
    source: source,
    name: null,
    libraryRoot: library,
    parent: parent,
    staging: p.joinAll([
      library,
      if (parent.isNotEmpty) ...parent.split('/'),
      '.html.niman-tmp-1',
    ]),
    attachments: 'assets',
    linkType: linkType,
    extent: HtmlExtent.body,
    importedOn: DateTime(2026, 11, 20),
    book: split,
    words: defaultBookWords,
  );

  String read(String relative) =>
      File(p.joinAll([library, ...relative.split('/')])).readAsStringSync();

  /// Everything under the library, as `/`-separated relative paths.
  List<String> tree() => [
    for (final entry in Directory(library).listSync(recursive: true))
      p.relative(entry.path, from: library).replaceAll(r'\', '/'),
  ]..sort();

  Future<FetchedPicture?> noFetch(String url) async => null;

  group('an AO3 work, a note a chapter', () {
    late HtmlConverted converted;

    setUp(() async {
      converted = await convertHtmlBook(
        request(fixture('ao3.html')),
        fetch: noFetch,
      );
    });

    test('is a folder named after it, a note a chapter and an index', () {
      expect(converted, (
        made: 'Placeholder Title',
        open: 'Placeholder Title/index.md',
        notes: 3,
        pictures: 0,
      ));
      expect(tree(), [
        'Placeholder Title',
        'Placeholder Title/01 Chapter 1.md',
        'Placeholder Title/02 The Placeholder Storm.md',
        'Placeholder Title/03 Chapter 3.md',
        'Placeholder Title/index.md',
      ]);
    });

    test("has an index with the work's metadata, summary and contents", () {
      expect(
        read('Placeholder Title/index.md'),
        '---\n'
        'title: Placeholder Title\n'
        'author:\n  - Placeholder Author\n'
        'language: en\n'
        'published: 2025-07-15\n'
        'series: Placeholder Saga\n'
        'series_index: 2\n'
        'description: Alpha beta gamma delta. Epsilon zeta eta theta. '
        'Iota kappa lambda.\n'
        'tags:\n  - Slow Burn\n  - Found Family\n  - Hurt/Comfort\n'
        'source: https://archiveofourown.org/works/1234567\n'
        'imported: 2026-11-20\n'
        'fandom:\n  - Placeholder Fandom - Placeholder Creator\n'
        'rating:\n  - Teen And Up Audiences\n'
        'warnings:\n  - Creator Chose Not To Use Archive Warnings\n'
        'category:\n  - F/M\n  - Gen\n'
        'relationships:\n  - Alpha Person & Beta Person\n'
        'characters:\n  - Alpha Person\n  - Beta Person\n  - Gamma Person\n'
        'completed: 2025-07-17\n'
        'words: 41128\n'
        '---\n'
        '\n'
        '# Placeholder Title\n'
        '\n'
        '*Placeholder Author*\n'
        '\n'
        '**Summary**\n'
        '\n'
        '> Alpha beta gamma delta. Epsilon zeta eta theta.\n'
        '>\n'
        '> Iota kappa lambda.\n'
        '\n'
        '**Notes**\n'
        '\n'
        '> Mu nu xi omicron pi rho sigma.\n'
        '\n'
        '- Translation into Italiano available: '
        '[Placeholder Translation](<https://archiveofourown.org/works/7654321>)'
        ' by [Other Author]'
        '(<https://archiveofourown.org/users/Other/pseuds/Other>)\n'
        '\n'
        '## Contents\n'
        '\n'
        '- [Chapter 1](01%20Chapter%201.md)\n'
        '- [Chapter 2: The Placeholder Storm]'
        '(02%20The%20Placeholder%20Storm.md)\n'
        '- [Chapter 3](03%20Chapter%203.md)\n',
      );
    });

    test('names a chapter after its title, else its heading', () {
      expect(
        tree().where((path) => path.endsWith('.md')).map(p.basename),
        containsAll([
          '01 Chapter 1.md',
          '02 The Placeholder Storm.md',
          '03 Chapter 3.md',
        ]),
      );
    });

    test("quotes a chapter's notes above it and its end notes below", () {
      expect(
        read('Placeholder Title/02 The Placeholder Storm.md'),
        '# Chapter 2: The Placeholder Storm\n'
        '\n'
        '**Chapter Notes**\n'
        '\n'
        '> Chapter notes: tau upsilon phi.\n'
        '\n'
        'First line of the second chapter.\n'
        '\n'
        'Second line of the second chapter.\n'
        '\n'
        '**Chapter End Notes**\n'
        '\n'
        '> End notes: chi psi omega.\n',
      );
    });

    test('makes a line of the text a paragraph', () {
      expect(
        read('Placeholder Title/03 Chapter 3.md'),
        '# Chapter 3\n'
        '\n'
        'First line of the third chapter.\n'
        '\n'
        'Last line of the third chapter.\n',
      );
    });

    test('drops the link to the end notes, and points a link at them', () {
      final all = tree()
          .where((path) => path.endsWith('.md'))
          .map(read)
          .join('\n');
      expect(all, isNot(contains('See the end of the chapter')));
      // The first chapter's own link lands in the note that has them.
      expect(
        read('Placeholder Title/01 Chapter 1.md'),
        contains('[link to the end notes](02%20The%20Placeholder%20Storm.md)'),
      );
    });

    test('leaves out a picture it cannot find', () {
      final first = read('Placeholder Title/01 Chapter 1.md');
      expect(first, isNot(contains('niman-picture')));
      expect(first, isNot(contains('![')));
    });
  });

  test('an AO3 work in one note has its metadata in its frontmatter', () async {
    final converted = await convertHtmlBook(
      request(fixture('ao3.html'), split: HtmlBookSplit.oneNote),
      fetch: noFetch,
    );
    expect(converted, (
      made: 'Placeholder Title.md',
      open: 'Placeholder Title.md',
      notes: 1,
      pictures: 0,
    ));
    expect(tree(), ['Placeholder Title.md']);
    final note = read('Placeholder Title.md');
    expect(note, startsWith('---\ntitle: Placeholder Title\n'));
    expect(note, contains('\nwords: 41128\n---\n\n# Placeholder Title\n\n'));
    expect(note, contains('\n## Chapter 1\n'));
    expect(note, contains('\n## Chapter 2: The Placeholder Storm\n'));
    expect(note, contains('\n**Summary**\n\n> Alpha beta gamma delta.'));
    // A link into the book is the heading it lands on.
    expect(note, contains('(#Chapter%202%3A%20The%20Placeholder%20Storm)'));
    expect(note, isNot(contains('## Contents')));
  });

  group('an AO3 work of one chapter', () {
    test('is a folder of one note, or one note', () async {
      await convertHtmlBook(
        request(fixture('ao3_single.html')),
        fetch: noFetch,
      );
      expect(tree(), [
        'One Shot',
        'One Shot/01 One Shot.md',
        'One Shot/index.md',
      ]);
      expect(
        read('One Shot/01 One Shot.md'),
        '# One Shot\n'
        '\n'
        'Only chapter, first line.\n'
        '\n'
        'Only chapter, second line.\n'
        '\n'
        '**End Notes**\n'
        '\n'
        '> Work end notes: placeholder.\n',
      );
    });

    test('in one note has no chapter heading', () async {
      await convertHtmlBook(
        request(fixture('ao3_single.html'), split: HtmlBookSplit.oneNote),
        fetch: noFetch,
      );
      final note = read('One Shot.md');
      expect(note, contains('# One Shot\n\n**Summary**'));
      expect(note, isNot(contains('## ')));
      expect(note, contains('Only chapter, second line.'));
    });
  });

  group('a book by its headings', () {
    String novel() {
      File(p.join(tmp.path, 'saved', 'Novel_files', 'map.png'))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(_png);
      return page(
        'Novel.html',
        '<html lang="en"><head><title>The Novel</title>'
            '<meta name="author" content="Ada"></head><body>'
            '<h1>The Novel</h1>'
            '<ul><li><a href="#c1">Chapter 1: Arrival</a></li>'
            '<li><a href="#c2">Chapter 2: Home</a></li>'
            '<li><a href="#c3">The Last</a></li></ul>'
            '<h2 id="c1">Chapter 1: Arrival</h2>'
            '${_paragraph(6000)}<h3 id="sec">A section</h3>${_paragraph(3000)}'
            '<p><img src="Novel_files/map.png" alt="Map"> '
            '<img src="https://example.org/far.png" alt="Far"></p>'
            '<h2 id="c2">Chapter 2: Home</h2>'
            '<p>Back to <a href="#c1">the start</a>, to '
            '<a href="#sec">the section</a>, to '
            '<a href="https://example.org/out">the web</a>.</p>'
            '${_paragraph(6000)}'
            '<h2 id="c3">The Last</h2>${_paragraph(6000)}'
            '</body></html>',
      );
    }

    test(
      'is a folder, a note a chapter, its links and pictures kept',
      () async {
        final converted = await convertHtmlBook(
          request(novel(), parent: 'Books'),
          fetch: noFetch,
        );
        const folder = 'Books/The Novel';
        expect(converted, (
          made: folder,
          open: '$folder/index.md',
          notes: 4,
          pictures: 1,
        ));
        expect(tree(), [
          'Books',
          folder,
          '$folder/00 Front matter.md',
          '$folder/01 Arrival.md',
          '$folder/02 Home.md',
          '$folder/03 The Last.md',
          '$folder/assets',
          '$folder/assets/${_name(_png, '.png')}',
          '$folder/index.md',
        ]);
        // The contents the page opens with, now links to the notes.
        expect(
          read('$folder/00 Front matter.md'),
          '# Front matter\n'
          '\n'
          '- [Chapter 1: Arrival](01%20Arrival.md)\n'
          '\n'
          '- [Chapter 2: Home](02%20Home.md)\n'
          '\n'
          '- [The Last](03%20The%20Last.md)\n',
        );
        final second = read('$folder/02 Home.md');
        expect(second, startsWith('# Chapter 2: Home\n\nBack to [the start]'));
        expect(second, contains('(01%20Arrival.md)'));
        // A link that lands on a section is that section's heading.
        expect(second, contains('(01%20Arrival.md#A%20section)'));
        expect(second, contains('[the web](<https://example.org/out>)'));
        final first = read('$folder/01 Arrival.md');
        expect(first, startsWith('# Chapter 1: Arrival\n'));
        expect(first, contains('\n## A section\n'));
        // The copy beside the note: relative to it.
        expect(first, contains('![Map](assets/${_name(_png, '.png')})'));
        // A web picture that did not come keeps its address.
        expect(first, contains('![Far](https://example.org/far.png)'));
      },
    );

    test('has an index with what the page says of itself', () async {
      await convertHtmlBook(request(novel()), fetch: noFetch);
      expect(
        read('The Novel/index.md'),
        '---\n'
        'title: The Novel\n'
        'author:\n  - Ada\n'
        'language: en\n'
        'imported: 2026-11-20\n'
        '---\n'
        '\n'
        '# The Novel\n'
        '\n'
        '*Ada*\n'
        '\n'
        '## Contents\n'
        '\n'
        '- [Chapter 1: Arrival](01%20Arrival.md)\n'
        '- [Chapter 2: Home](02%20Home.md)\n'
        '- [The Last](03%20The%20Last.md)\n',
      );
    });

    test('in one note keeps its pictures in the library', () async {
      final converted = await convertHtmlBook(
        request(novel(), split: HtmlBookSplit.oneNote, parent: 'Books'),
        fetch: noFetch,
      );
      expect(converted.made, 'Books/The Novel.md');
      expect(tree(), [
        'Books',
        'Books/The Novel.md',
        'assets',
        'assets/${_name(_png, '.png')}',
      ]);
      final note = read('Books/The Novel.md');
      expect(note, contains('![[assets/${_name(_png, '.png')}]]'));
      expect(note, contains('\n## Chapter 2: Home\n'));
      expect(note, contains('[the start](#Chapter%201%3A%20Arrival)'));
      expect(note, contains('[the section](#A%20section)'));
    });

    test('in one note writes Markdown links to a Markdown library', () async {
      await convertHtmlBook(
        request(
          novel(),
          split: HtmlBookSplit.oneNote,
          parent: 'Books',
          linkType: LinkType.markdown,
        ),
        fetch: noFetch,
      );
      expect(
        read('Books/The Novel.md'),
        contains('![Map](../assets/${_name(_png, '.png')})'),
      );
    });

    test('is named free beside a folder that has its name', () async {
      await convertHtmlBook(request(novel()), fetch: noFetch);
      final second = await convertHtmlBook(
        request(novel()).copyWithStaging('.html.niman-tmp-2'),
        fetch: noFetch,
      );
      expect(second.made, 'The Novel 2');
      expect(tree(), contains('The Novel 2/index.md'));
    });
  });

  test('a page that is no book is refused, and nothing is left', () async {
    final source = page('Short.html', '<h1>Short</h1><p>Text.</p>');
    await expectLater(
      convertHtmlBook(request(source), fetch: noFetch),
      throwsA(
        isA<HtmlRefused>().having(
          (error) => error.reason,
          'reason',
          HtmlRefusal.notABook,
        ),
      ),
    );
    expect(tree(), isEmpty);
  });

  test('a stop leaves nothing in the library', () async {
    var steps = 0;
    await expectLater(
      convertHtmlBook(
        request(fixture('ao3.html')),
        fetch: noFetch,
        stopped: () => ++steps > 4,
      ),
      throwsA(isA<HtmlConvertStopped>()),
    );
    expect(tree(), isEmpty);
  });

  test('a cancel that comes at the moving in leaves nothing', () async {
    await expectLater(
      convertHtmlBook(
        request(fixture('ao3.html')),
        fetch: noFetch,
        mayFinish: () async => false,
      ),
      throwsA(isA<HtmlConvertStopped>()),
    );
    expect(tree(), isEmpty);
  });

  test('says how far it has got: the notes, then the index', () async {
    final seen = <HtmlConvertProgress>[];
    await convertHtmlBook(
      request(fixture('ao3.html')),
      fetch: noFetch,
      progress: seen.add,
    );
    expect(seen.map((step) => step.what).where((what) => what != 'map.png'), [
      '01 Chapter 1.md',
      '02 The Placeholder Storm.md',
      '03 Chapter 3.md',
      'index.md',
    ]);
    expect(seen.last.done, seen.last.total - 1);
  });

  group('the preview', () {
    test('counts what a note a chapter would make', () async {
      final preview = await previewHtmlBook(
        fixture('ao3.html'),
        defaultBookWords,
      );
      expect(preview!.title, 'Placeholder Title');
      expect(preview.authors, ['Placeholder Author']);
      expect(preview.notes, 3);
      expect(preview.folders, 0);
      expect(tree(), isEmpty);
    });

    test('is null for a page that is no book', () async {
      expect(
        await previewHtmlBook(
          page('Short.html', '<h1>Short</h1><p>Text.</p>'),
          defaultBookWords,
        ),
        isNull,
      );
    });
  });
}

extension on HtmlConvertRequest {
  /// The same request staged in the hidden folder [staging].
  HtmlConvertRequest copyWithStaging(String staging) => (
    source: source,
    name: name,
    libraryRoot: libraryRoot,
    parent: parent,
    staging: p.join(p.dirname(this.staging), staging),
    attachments: attachments,
    linkType: linkType,
    extent: extent,
    importedOn: importedOn,
    book: book,
    words: words,
  );
}
