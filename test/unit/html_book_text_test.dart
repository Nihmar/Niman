// HTML is written in pieces, and a space between two would be a word of
// the page: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
// A book's text as Markdown lines (#1294): where each chapter opens, the
// headings moved to the level the notes want, the title left out of the
// front matter, and what a chapter's file is named.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/html/book/html_book_reader.dart';
import 'package:niman/src/import/html/book/html_book_text.dart';

const ({String chapter, String opening, String contents}) _words = (
  chapter: 'Chapter {n}',
  opening: 'Front matter',
  contents: 'Contents',
);

final Uri _base = Uri.file('/site/book.html');

HtmlBook _book(
  String html, {
  List<String> titles = const [],
  int level = 2,
  String title = 'The Novel',
}) => HtmlBook(
  profile: HtmlBookProfile.headings,
  title: title,
  authors: const [],
  fields: const [],
  html: html,
  chapters: [
    for (final (index, name) in titles.indexed)
      (marker: chapterMarker(index), title: name),
  ],
  headingLevel: level,
);

String _chapter(int index, String heading) =>
    '<div id="${chapterMarker(index)}"></div>$heading';

void main() {
  group('the chapters', () {
    final book = _book(
      '<h1>The Novel</h1><p>By a hand.</p>'
      '${_chapter(0, '<h2>One</h2>')}<p>First.</p><h3>A section</h3><p>Next.</p>'
      '${_chapter(1, '<h2>Two</h2>')}<p>Second.</p>',
      titles: ['One', 'Two'],
    );

    test('open at the line of their heading', () {
      final text = convertBookText(
        book,
        base: _base,
        oneNote: false,
        words: _words,
      );
      expect(text.entries, [
        (title: 'One', depth: 0, line: 4),
        (title: 'Two', depth: 0, line: 12),
      ]);
      expect(text.lines[4], '# One');
      expect(text.lines[12], '# Two');
    });

    test('are headed `#` in a note a chapter, under the title otherwise', () {
      final each = convertBookText(
        book,
        base: _base,
        oneNote: false,
        words: _words,
      );
      expect(each.lines, contains('## A section'));
      final one = convertBookText(
        book,
        base: _base,
        oneNote: true,
        words: _words,
      );
      expect(one.lines[4], '## One');
      expect(one.lines, contains('### A section'));
    });

    test('are named by the words handed in when the book names none', () {
      final text = convertBookText(
        _book(
          '${_chapter(0, '<h2></h2>')}<p>Text.</p>'
          '${_chapter(1, '<h2>Two</h2>')}<p>More.</p>',
          titles: ['', 'Two'],
        ),
        base: _base,
        oneNote: false,
        words: _words,
      );
      expect(text.entries.map((entry) => entry.title), ['Chapter 1', 'Two']);
    });
  });

  test('the title, as the heading before the first chapter, is not said', () {
    final text = convertBookText(
      _book(
        '<h1>The Novel</h1><p>By a hand.</p>'
        '${_chapter(0, '<h2>One</h2>')}<p>First.</p>',
        titles: ['One'],
      ),
      base: _base,
      oneNote: false,
      words: _words,
    );
    expect(text.lines.join('\n'), isNot(contains('The Novel')));
    expect(text.lines.join('\n'), contains('By a hand.'));
  });

  test('a book with no chapter heading keeps its headings as they are', () {
    final text = convertBookText(
      _book(
        '${_chapter(0, '')}<h3>Part</h3><p>Text.</p>',
        titles: ['The Novel'],
        level: 0,
      ),
      base: _base,
      oneNote: true,
      words: _words,
    );
    expect(text.lines.first, '### Part');
  });

  group('the pictures', () {
    test('are named by their order, each src once', () {
      final text = convertBookText(
        _book(
          '${_chapter(0, '<h2>One</h2>')}'
          '<p><img src="a.png" alt="A"> <img src="b.png"> '
          '<img src="a.png"></p>'
          '<p><img src="javascript:alert(1)"></p>',
          titles: ['One'],
        ),
        base: _base,
        oneNote: false,
        words: _words,
      );
      expect(text.pictureSrcs, ['a.png', 'b.png']);
      final all = text.lines.join('\n');
      expect(all, contains('![A](niman-picture:0)'));
      expect(all, contains('![](niman-picture:1)'));
      expect(all, isNot(contains('javascript')));
    });
  });

  group('shiftHeadings', () {
    test('moves headings, within # to ######, and spares fenced code', () {
      expect(shiftHeadings(['## A', '```', '## code', '```', '###### Z'], -1), [
        '# A',
        '```',
        '## code',
        '```',
        '##### Z',
      ]);
      expect(shiftHeadings(['# A', '###### Z'], 2), ['### A', '###### Z']);
      expect(shiftHeadings(['# A'], -3), ['# A']);
    });
  });

  group("a chapter's file is named", () {
    test('by its title when its heading has one after the number', () {
      expect(chapterFileTitle('Chapter 3: The Storm'), 'The Storm');
      expect(chapterFileTitle('Capitolo 12 - La tempesta'), 'La tempesta');
      expect(chapterFileTitle('Chapter IV. The Storm'), 'The Storm');
      expect(chapterFileTitle('Chapter 3 – The Storm'), 'The Storm');
    });

    test('by its heading when it has only the number', () {
      expect(chapterFileTitle('Chapter 3'), 'Chapter 3');
      expect(chapterFileTitle('Prologue'), 'Prologue');
      expect(chapterFileTitle('The Storm'), 'The Storm');
      expect(chapterFileTitle('Chapter 3:'), 'Chapter 3:');
    });
  });
}
