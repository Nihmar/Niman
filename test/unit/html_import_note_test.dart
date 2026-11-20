// The note an imported HTML page becomes (#1293): its frontmatter, its
// heading, its pictures and the links that point into the page.
//
// HTML is written in pieces, and a space between two would be a word of
// the page: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/html/html_note.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:path/path.dart' as p;

final Uri _file = Uri.file(p.join(p.current, 'site', 'page.html'));
final DateTime _day = DateTime(2026, 11, 20);

HtmlPage _page(
  String html, {
  String title = 'The Storm',
  String? source,
  String? author,
  Uri? baseUrl,
}) => HtmlPage(
  title: title,
  html: html,
  isArticle: false,
  source: source,
  author: author,
  baseUrl: baseUrl,
);

String _note(
  String html, {
  String title = 'The Storm',
  Map<String, String> pictures = const {},
  LinkType linkType = LinkType.wikilink,
  String folder = '',
  Uri? baseUrl,
}) => htmlNote(
  _page(html, title: title, baseUrl: baseUrl),
  imported: _day,
  file: _file,
  pictures: pictures,
  linkType: linkType,
  folder: folder,
);

void main() {
  group('the frontmatter', () {
    test('has the source, the day and the author, then the title', () {
      final text = htmlNote(
        _page(
          '<p>Hello.</p>',
          source: 'https://example.org/post/1',
          author: 'Ada Lovelace',
        ),
        imported: _day,
        file: _file,
      );
      expect(
        text,
        '---\n'
        'source: https://example.org/post/1\n'
        'imported: 2026-11-20\n'
        'author: Ada Lovelace\n'
        '---\n'
        '\n'
        '# The Storm\n'
        '\n'
        'Hello.\n',
      );
    });

    test('has only the day when the page says nothing of itself', () {
      final text = _note('<p>Hello.</p>');
      expect(text, startsWith('---\nimported: 2026-11-20\n---\n'));
      expect(text, isNot(contains('source:')));
      expect(text, isNot(contains('author:')));
    });

    test('quotes what YAML would read as more', () {
      final text = htmlNote(
        _page('<p>x</p>', author: 'Smith: the younger', source: 'https://a.b/'),
        imported: _day,
        file: _file,
      );
      expect(text, contains('author: "Smith: the younger"'));
    });

    test('is a title and no body for an empty page', () {
      expect(_note(''), endsWith('---\n\n# The Storm\n'));
    });
  });

  group('the heading', () {
    test('is the title, and a first heading that repeats it is dropped', () {
      final text = _note('<h1>The Storm</h1><p>It rained.</p>');
      expect(text, endsWith('# The Storm\n\nIt rained.\n'));
      expect('# The Storm'.allMatches(text), hasLength(1));
    });

    test('is not dropped when it says something else', () {
      final text = _note('<h2>Part one</h2><p>It rained.</p>');
      expect(text, endsWith('# The Storm\n\n## Part one\n\nIt rained.\n'));
    });

    test('is written as text: nothing in a title is Markdown', () {
      final text = _note('<p>x</p>', title: 'C# and [links] *now*');
      expect(text, contains(r'# C\# and \[links\] \*now\*'));
    });
  });

  group('the links', () {
    test('into the page point at the heading they land in', () {
      final text = _note(
        '<p id="top">Start. <a href="#storm">The storm</a>, '
        '<a href="#late">late</a>.</p>'
        '<h2 id="storm">Rain (heavy)</h2><p>Wet.</p>'
        '<p id="late">Later, <a href="#top">back</a>.</p>',
      );
      // Before any heading: the note's own title. On a heading: itself.
      // Under one: the last before it, its parentheses escaped.
      expect(text, contains('[The storm](#Rain%20%28heavy%29)'));
      expect(text, contains('[late](#Rain%20%28heavy%29)'));
      expect(text, contains('[back](#The%20Storm)'));
      expect(text, isNot(contains('niman-anchor')));
    });

    test('into the page keep an id the page does not have as it is', () {
      final text = _note('<h2>One</h2><p><a href="#nowhere">x</a></p>');
      expect(text, contains('[x](#nowhere)'));
    });

    test('are not fooled by a comment line in a code block', () {
      final text = _note(
        '<h2>Real</h2><pre><code># not a heading\nls\n</code></pre>'
        '<p id="after">After. <a href="#after">self</a></p>',
      );
      expect(text, contains('[self](#Real)'));
    });

    test('to the web stay, and so do relative ones to other files', () {
      final text = _note(
        '<p><a href="https://example.org/a?b=1#c">web</a> and '
        '<a href="other/page.html#part">local</a> and '
        '<a href="mailto:me@example.org">mail</a></p>',
      );
      expect(text, contains('[web](<https://example.org/a?b=1#c>)'));
      expect(text, contains('[local](<other/page.html#part>)'));
      expect(text, contains('[mail](<mailto:me@example.org>)'));
    });
  });

  group('the pictures', () {
    test('lists each src once, in order', () {
      final page = _page(
        '<img src="a.png"><p><img src="b.png"><img src="a.png"></p>'
        '<img src="data:image/png;base64,AAAA">',
      );
      expect(htmlPictureSrcs(page), [
        'a.png',
        'b.png',
        'data:image/png;base64,AAAA',
      ]);
    });

    test('that were kept are embedded as the library embeds its own', () {
      final text = _note(
        '<p><img src="Page_files/a.png" alt="A tree"></p>',
        pictures: {'Page_files/a.png': 'assets/abc.png'},
      );
      expect(text, contains('![[assets/abc.png]]'));
    });

    test(
      "are Markdown links from the note's folder, in a Markdown library",
      () {
        final text = _note(
          '<p><img src="Page_files/a.png" alt="A tree"></p>',
          pictures: {'Page_files/a.png': 'assets/abc.png'},
          linkType: LinkType.markdown,
          folder: 'Reading/Web',
        );
        expect(text, contains('![A tree](../../assets/abc.png)'));
      },
    );

    test('that did not come: a web one keeps its address', () {
      final text = _note(
        '<p><img src="https://example.org/a.png" alt="x"></p>',
      );
      expect(text, contains('![x](https://example.org/a.png)'));
    });

    test('that did not come: a relative one of a <base> page keeps its '
        'absolute address', () {
      final text = _note(
        '<p><img src="img/a.png" alt="x"></p>',
        baseUrl: Uri.parse('https://example.org/blog/'),
      );
      expect(text, contains('![x](https://example.org/blog/img/a.png)'));
    });

    test('that did not come: a local one, and a data: one, are left out', () {
      final text = _note(
        '<p>Before <img src="gone.png"> <img src="data:image/png;base64,@@">'
        ' after</p>',
      );
      expect(text, contains('Before'));
      expect(text, isNot(contains('![')));
      expect(text, isNot(contains('gone.png')));
      expect(text, isNot(contains('data:')));
    });
  });
}
