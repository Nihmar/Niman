// Whether an HTML page is a book, and the book it is (#1294): the AO3
// profile's metadata, chapters and what it drops, and the rule that makes a
// page with no profile a book by its headings.
//
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/book/book_render.dart';
import 'package:niman/src/import/html/book/html_book_reader.dart';
import 'package:niman/src/import/html/html_page.dart';

HtmlBook? _read(String html, {String title = 'Page', String? language}) =>
    readHtmlBook(
      HtmlPage(
        title: title,
        html: html,
        isArticle: false,
        language: language,
        author: 'Ada',
        source: 'https://example.org/novel',
      ),
    );

String _fixture(String name) =>
    File('test/fixtures/html_book/$name').readAsStringSync();

/// The body of a page, as `readHtmlPage` hands it to the reader.
HtmlBook? _readFile(String name) {
  final bytes = File('test/fixtures/html_book/$name').readAsBytesSync();
  return readHtmlBook(
    readHtmlPage(bytes, fileName: name, extent: HtmlExtent.body),
  );
}

/// A paragraph of [length] characters of placeholder words.
String _paragraph(int length) {
  final words = StringBuffer();
  while (words.length < length) {
    words.write('lorem ipsum dolor ');
  }
  return '<p>${words.toString().substring(0, length)}</p>';
}

/// A page of [chapters] chapters under [level] headings, each [length]
/// characters long, with a title above.
String _novel({
  int chapters = 4,
  int length = 6000,
  String level = 'h2',
  String extra = '',
}) {
  final sections = [
    for (var i = 1; i <= chapters; i++)
      '<$level id="c$i">Chapter $i: Name $i</$level>${_paragraph(length)}',
  ];
  return '<h1>The Novel</h1>${_paragraph(100)}$extra${sections.join()}';
}

void main() {
  group('an AO3 download', () {
    final book = _readFile('ao3.html')!;

    test('is recognized, with its title and authors', () {
      expect(book.profile, HtmlBookProfile.ao3);
      expect(book.title, 'Placeholder Title');
      expect(book.authors, ['Placeholder Author']);
    });

    test('has a chapter for each heading, as the book calls it', () {
      expect(book.chapters.map((chapter) => chapter.title), [
        'Chapter 1',
        'Chapter 2: The Placeholder Storm',
        'Chapter 3',
      ]);
      expect(book.headingLevel, 2);
    });

    test('says everything about itself in its frontmatter', () {
      expect(
        bookFrontmatter(book.fieldsImportedOn('2026-11-20')),
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
        'words: 41128\n',
      );
    });

    test('keeps the summary and the notes, quoted, and the related works', () {
      expect(book.introHtml, contains('<strong>Summary</strong>'));
      expect(book.introHtml, contains('Alpha beta gamma delta'));
      expect(book.introHtml, contains('<strong>Notes</strong>'));
      expect(book.introHtml, contains('Placeholder Translation'));
      expect(book.introHtml, isNot(contains('Rating')));
    });

    test("quotes a chapter's notes at its top and its end notes below", () {
      final html = book.html;
      expect(
        html.indexOf('Chapter notes: tau'),
        lessThan(html.indexOf('First line of the second chapter')),
      );
      expect(
        html.indexOf('First line of the second chapter'),
        lessThan(html.indexOf('End notes: chi')),
      );
    });

    test('drops what the Archive adds around the work', () {
      final html = book.html;
      expect(html, isNot(contains('Preface')));
      expect(html, isNot(contains('Afterword')));
      expect(html, isNot(contains('drop by the Archive')));
      expect(html, isNot(contains('Works inspired by this one')));
      expect(html, isNot(contains('See the end of the chapter')));
      expect(html, isNot(contains('dl class="tags"')));
    });
  });

  group('a work of one chapter', () {
    final book = _readFile('ao3_single.html')!;

    test('is one chapter, titled as the work, with no heading of its own', () {
      expect(book.chapters.map((chapter) => chapter.title), ['One Shot']);
      expect(book.headingLevel, 0);
      expect(book.html, isNot(contains('<h2')));
    });

    test('takes its language from the page and every author it links', () {
      expect(book.authors, ['First Author', 'Second Author']);
      expect(
        bookFrontmatter(book.fieldsImportedOn('2026-11-20')),
        'title: One Shot\n'
        'author:\n  - First Author\n  - Second Author\n'
        'language: it\n'
        'published: 2024-01-02\n'
        'description: A short placeholder summary.\n'
        'source: https://archiveofourown.org/works/555\n'
        'imported: 2026-11-20\n'
        'fandom:\n  - Placeholder Fandom\n'
        'rating:\n  - General Audiences\n'
        'warnings:\n  - No Archive Warnings Apply\n'
        'words: 1205\n',
      );
    });

    test("keeps the work's end notes after its text", () {
      expect(
        book.html.indexOf('Only chapter, second line'),
        lessThan(book.html.indexOf('Work end notes')),
      );
    });
  });

  test('a page that looks like AO3 but links no work is not one', () {
    final html = _fixture('ao3.html')
        .replaceAll('archiveofourown.org/works/1234567', 'example.org/w/1');
    expect(_read(html), isNull);
  });

  group('a book by its headings', () {
    test("is the headings that repeat, with the page's own metadata", () {
      final book = _read(_novel(), title: 'The Novel', language: 'en')!;
      expect(book.profile, HtmlBookProfile.headings);
      expect(book.headingLevel, 2);
      expect(book.chapters.map((chapter) => chapter.title), [
        for (var i = 1; i <= 4; i++) 'Chapter $i: Name $i',
      ]);
      expect(
        bookFrontmatter(book.fieldsImportedOn('2026-11-20')),
        'title: The Novel\n'
        'author:\n  - Ada\n'
        'language: en\n'
        'source: https://example.org/novel\n'
        'imported: 2026-11-20\n',
      );
    });

    test('takes the shallowest level that repeats', () {
      // One h1, four h2s, and h3s inside each: the chapters are the h2s.
      final html = _novel().replaceAll(
        '</p><h2',
        '</p><h3>Section</h3>${_paragraph(50)}<h2',
      );
      expect(_read(html)!.headingLevel, 2);
      // Chapters under h3 alone.
      expect(_read(_novel(level: 'h3'))!.headingLevel, 3);
    });

    test('marks each chapter before its heading, whose id it leaves', () {
      final book = _read(_novel())!;
      expect(
        book.html,
        contains('<div id="niman-chapter-0"></div><h2 id="c1">'),
      );
    });

    test('is not one with fewer than three chapters', () {
      expect(_read(_novel(chapters: 2)), isNull);
    });

    test('is not one when it is short', () {
      expect(_read(_novel(length: 200)), isNull);
    });

    test('is not one when most of its sections are short', () {
      // Two long sections among eight of a line each: an article, not a
      // novel.
      final html = StringBuffer('<h1>Reference</h1>');
      for (var i = 0; i < 8; i++) {
        html.write('<h2>Short $i</h2><p>One line.</p>');
      }
      html
        ..write('<h2>Long</h2>${_paragraph(12000)}')
        ..write('<h2>Longer</h2>${_paragraph(12000)}');
      expect(_read(html.toString()), isNull);
    });

    test('does not count the headings of a menu or a footer', () {
      final html =
          '<nav><h2>Menu</h2><h2>More</h2><h2>Other</h2></nav>'
          '${_novel(chapters: 2)}<footer><h2>A</h2><h2>B</h2></footer>';
      expect(_read(html), isNull);
    });
  });
}
