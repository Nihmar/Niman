// Reading an HTML file to import (#1293): its charset, its title, what it
// says of itself, and the part of it that becomes the note.
//
// HTML is written in pieces, and a space between two would be a word of
// the page: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_page.dart';

Uint8List _bytes(String html) => Uint8List.fromList(utf8.encode(html));

HtmlPage _read(
  String html, {
  String fileName = 'Saved page.html',
  HtmlExtent extent = HtmlExtent.article,
}) => readHtmlPage(_bytes(html), fileName: fileName, extent: extent);

/// A page with an article long enough for Readability, around a menu.
String _articlePage({String head = '', String title = ''}) {
  const paragraph =
      'The old road ran along the river, past the mill, the church and the '
      'long, quiet orchard, and every evening, when the light went amber, '
      'the villagers walked it slowly, talking of the harvest, the weather, '
      'and the news that came, late and garbled, from the city.';
  return '<html><head>$head<title>$title</title></head><body>'
      '<nav><a href="/home">Home</a> <a href="/about">About the site</a></nav>'
      '<article><h1>The Long Road Home</h1>'
      '${List.filled(8, '<p>$paragraph</p>').join()}</article>'
      '<footer>Copyright somebody</footer></body></html>';
}

void main() {
  group('an .xhtml file is read as XML (#1304)', () {
    const xhtml =
        '<html><head><title/></head><body><h1>Heading</h1>'
        '<p>The text <a id="x"/>after an anchor.</p></body></html>';

    test('a self-closed <title/> is empty and the text stays', () {
      final page = _read(xhtml, fileName: 'page.xhtml', extent: .body);
      expect(page.html, contains('The text'));
      expect(page.html, contains('after an anchor.'));
      expect(page.title, 'Heading');
    });

    test('the extension is not case-sensitive', () {
      final page = _read(xhtml, fileName: 'PAGE.XHTML', extent: .body);
      expect(page.html, contains('The text'));
    });

    test('a .html file keeps the HTML reading, as a browser has it', () {
      final page = _read(xhtml, fileName: 'page.html', extent: .body);
      expect(page.html, isNot(contains('The text')));
    });
  });

  group('the title', () {
    test('is the <title>', () {
      final page = _read(
        '<title>  My   notes </title><h1>Else</h1><p>Short.</p>',
      );
      expect(page.title, 'My notes');
    });

    test('falls to og:title, then the first <h1>, then the file name', () {
      expect(
        _read(
          '<meta property="og:title" content="Shared title">'
          '<h1>Else</h1><p>Short.</p>',
        ).title,
        'Shared title',
      );
      expect(_read('<h1>The  first</h1><h1>Second</h1>').title, 'The first');
      expect(_read('<p>No title at all.</p>').title, 'Saved page');
    });

    test("is the article's, with the site name cut off, when there is one", () {
      final page = _read(
        _articlePage(
          title: 'The Long Road Home Through The Village - Village Gazette',
        ),
      );
      expect(page.isArticle, isTrue);
      expect(page.title, 'The Long Road Home Through The Village');
    });
  });

  group('the charset', () {
    test('is read from a Windows-1252 <meta>', () {
      final bytes = Uint8List.fromList([
        ...latin1.encode('<meta charset="windows-1252"><title>Caf'),
        0xE9,
        ...latin1.encode('</title><p>Cr'),
        0xE8,
        ...latin1.encode('me br'),
        0xFB,
        ...latin1.encode('l'),
        0xE9,
        ...latin1.encode('e</p>'),
      ]);
      final page = readHtmlPage(bytes, fileName: 'a.html');
      expect(page.title, 'Café');
      expect(page.html, contains('Crème brûlée'));
    });

    test('is UTF-8 with a byte order mark', () {
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('<title>Città</title><p>Perché</p>'),
      ]);
      final page = readHtmlPage(bytes, fileName: 'a.html');
      expect(page.title, 'Città');
      expect(page.html, contains('Perché'));
    });

    test('is UTF-16 with its byte order mark', () {
      final units = '<title>Tokyo 東京</title><p>x</p>'.codeUnits;
      final bytes = Uint8List.fromList([
        0xFF,
        0xFE,
        for (final unit in units) ...[unit & 0xFF, unit >> 8],
      ]);
      expect(readHtmlPage(bytes, fileName: 'a.html').title, 'Tokyo 東京');
    });

    test('refuses one that is not decoded rather than guess', () {
      final bytes = _bytes(
        '<meta charset="shift_jis"><title>x</title><p>y</p>',
      );
      expect(
        () => readHtmlPage(bytes, fileName: 'a.html'),
        throwsA(
          isA<HtmlRefused>().having(
            (error) => error.reason,
            'reason',
            HtmlRefusal.unsupportedCharset,
          ),
        ),
      );
    });
  });

  group('what the page says of itself', () {
    test('has its canonical link as the source', () {
      final page = _read(
        '<link rel="canonical" href="https://example.org/post/1">'
        '<meta property="og:url" content="https://other.example/x">'
        '<p>Short.</p>',
      );
      expect(page.source, 'https://example.org/post/1');
    });

    test('has og:url when there is no canonical link', () {
      expect(
        _read(
          '<meta property="og:url" content="https://example.org/a"><p>x</p>',
        ).source,
        'https://example.org/a',
      );
    });

    test('has no source that is not an absolute web address', () {
      expect(
        _read('<link rel="canonical" href="/post/1"><p>x</p>').source,
        isNull,
      );
      expect(
        _read('<link rel="canonical" href="file:///a/b.html"><p>x</p>').source,
        isNull,
      );
      expect(_read('<p>x</p>').source, isNull);
    });

    test('has its author from <meta name="author">, else rel="author"', () {
      expect(
        _read('<meta name="author" content="Ada Lovelace"><p>x</p>').author,
        'Ada Lovelace',
      );
      expect(
        _read('<p>By <a rel="author" href="/ada"> Ada  Byron </a></p>').author,
        'Ada Byron',
      );
      expect(_read('<p>x</p>').author, isNull);
    });

    test('has its language from <html lang>', () {
      expect(_read('<html lang="it"><p>x</p></html>').language, 'it');
      expect(_read('<p>x</p>').language, isNull);
    });

    test('has the web address its <base> names', () {
      final page = _read('<base href="https://cdn.example/site/"><p>x</p>');
      expect(page.baseUrl, Uri.parse('https://cdn.example/site/'));
      expect(_read('<base href="/local/"><p>x</p>').baseUrl, isNull);
    });
  });

  group('the part that becomes the note', () {
    test('is the article, the menu and the footer left out', () {
      final page = _read(_articlePage());
      expect(page.isArticle, isTrue);
      expect(page.html, contains('The old road ran along the river'));
      expect(page.html, isNot(contains('About the site')));
      expect(page.html, isNot(contains('Copyright somebody')));
    });

    test('keeps the classes the converter reads', () {
      final page = _read(
        _articlePage().replaceFirst(
          '</article>',
          '<pre><code class="language-dart">var x;</code></pre></article>',
        ),
      );
      expect(page.html, contains('language-dart'));
    });

    test('is the whole body when there is too little text for an article', () {
      final page = _read(
        '<body><nav>Home | About</nav><h1>Short page</h1>'
        '<p>Only a few words.</p><footer>Bye</footer></body>',
      );
      expect(page.isArticle, isFalse);
      expect(page.html, contains('Home | About'));
      expect(page.html, contains('Only a few words.'));
      expect(page.html, contains('Bye'));
    });

    test('is the whole body, whatever Readability would say, when asked', () {
      final page = _read(_articlePage(), extent: HtmlExtent.body);
      expect(page.isArticle, isFalse);
      expect(page.html, contains('About the site'));
      expect(page.html, contains('Copyright somebody'));
    });

    test('has no body of a page without one', () {
      expect(_read('').html, isEmpty);
    });
  });
}
