// A chapter of an EPUB, from its XHTML to the Markdown the read view draws:
// its structure kept, its words escaped wherever Markdown or the app's own
// extensions would read them as syntax.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/xhtml_markdown.dart';
import 'package:niman/src/markdown/extension_masker.dart';

void main() {
  final pictures = <String>[];
  final links = <String>[];
  final converter = XhtmlMarkdown(
    picture: (src) {
      if (src.startsWith('missing')) return null;
      pictures.add(src);
      return 'pic:$src';
    },
    link: (href) {
      links.add(href);
      return 'link:$href';
    },
  );

  setUp(() {
    pictures.clear();
    links.clear();
  });

  ChapterMarkdown convert(String body) => converter.convert(
    '<?xml version="1.0" encoding="utf-8"?>'
    '<html xmlns="http://www.w3.org/1999/xhtml"><head><title>T</title>'
    '<style>p { color: red }</style></head><body>$body</body></html>',
  );

  String markdown(String body) => convert(body).markdown;

  group('blocks', () {
    test('headings and paragraphs, a blank line apart', () {
      expect(
        markdown('<h1>One</h1><p>First   para.</p><h3>Three</h3><p>Two</p>'),
        '# One\n\nFirst para.\n\n### Three\n\nTwo',
      );
    });

    test('emphasis, strong, strike and code', () {
      expect(
        markdown(
          '<p><em>a</em> <strong>b</strong> <del>c</del> <code>d</code> '
          '<i> e </i>f</p>',
        ),
        '*a* **b** ~~c~~ `d` *e* f',
      );
    });

    test('a code span holding a backtick is fenced with two', () {
      expect(markdown('<p><code>a`b</code></p>'), '`` a`b ``');
    });

    test('a line break is a hard break', () {
      expect(markdown('<p>one<br/>two</p>'), 'one\\\ntwo');
    });

    test('lists, nested, numbered from their start', () {
      expect(
        markdown(
          '<ul><li>a<ul><li>a1</li></ul></li><li>b</li></ul>'
          '<ol start="3"><li>c</li><li>d<ol><li>d1</li></ol></li></ol>',
        ),
        '- a\n\n  - a1\n\n- b\n\n3. c\n\n4. d\n\n   1. d1',
      );
    });

    test('a list item of paragraphs is one line', () {
      expect(markdown('<ul><li><p>a</p><p>b</p></li></ul>'), '- a b');
    });

    test('a quote, and a quote in a quote', () {
      expect(
        markdown(
          '<blockquote><p>a</p><blockquote><p>b</p></blockquote>'
          '</blockquote>',
        ),
        '> a\n\n> > b',
      );
    });

    test('preformatted text is fenced, as it is', () {
      expect(
        markdown('<pre>let *a* = 1;\n  #b</pre>'),
        '```\nlet *a* = 1;\n  #b\n```',
      );
      expect(markdown('<pre>```x```</pre>'), '~~~~\n```x```\n~~~~');
    });

    test('a rule', () {
      expect(markdown('<p>a</p><hr/><p>b</p>'), 'a\n\n---\n\nb');
    });

    test('a table, its first row the header, short rows filled', () {
      expect(
        markdown(
          '<table><tr><th>A</th><th>B</th></tr>'
          '<tr><td>1</td><td>x|y</td></tr><tr><td>2</td></tr></table>',
        ),
        '| A | B |\n| --- | --- |\n| 1 | x\\|y |\n| 2 |  |',
      );
    });

    test('containers are walked, their loose words a paragraph', () {
      expect(
        markdown('<section><div>loose <b>words</b><p>para</p></div></section>'),
        'loose **words**\n\npara',
      );
    });

    test('scripts and styles are not words', () {
      expect(markdown('<p>a<script>var x = 1;</script></p>'), 'a');
    });
  });

  group('escaping', () {
    test("a book's #word is not a tag", () {
      expect(markdown('<p>see #chapter</p>'), r'see \#chapter');
    });

    test('dollars are not math', () {
      expect(markdown(r'<p>$5 and $6</p>'), r'\$5 and \$6');
    });

    test('brackets are not a wikilink', () {
      expect(markdown('<p>[[x]]</p>'), r'\[\[x\]\]');
    });

    test('stars and underscores are not emphasis', () {
      expect(markdown('<p>*a* _b_</p>'), r'\*a\* \_b\_');
    });

    test('the extensions: highlight, sub, sup, embed', () {
      expect(
        markdown('<p>==a== ~b~ ^c^ !x &amp;</p>'),
        r'\=\=a\=\= \~b\~ \^c\^ \!x \&',
      );
    });

    test('a paragraph opening like a list is escaped', () {
      expect(markdown('<p>1. at the start</p>'), r'1\. at the start');
      expect(markdown('<p>2) also</p>'), r'2\) also');
      expect(markdown('<p>- a dash</p>'), r'\- a dash');
      expect(markdown('<p>+ a plus</p>'), r'\+ a plus');
    });

    test('a heading opening with a number is not a list', () {
      expect(markdown('<h2>1. One</h2>'), '## 1. One');
    });

    test("the app's extensions find nothing in a book's words", () {
      final text = markdown(
        r'<p>#tag $5 and $6 $$x$$ [[note]] ![[pic.png]] ==hi==</p>',
      );
      expect(const ExtensionMasker().mask(text).spans, isEmpty, reason: text);
    });

    test('a backslash is kept as one', () {
      expect(markdown(r'<p>a\b</p>'), r'a\\b');
    });
  });

  group('anchors', () {
    test('an id is the line its block starts on', () {
      final chapter = convert(
        '<h1 id="top">T</h1><p id="p1">a</p>'
        '<p>b<span id="inner">c</span></p><ul><li id="li">x</li></ul>',
      );
      expect(chapter.anchors, {'top': 0, 'p1': 2, 'inner': 4, 'li': 6});
    });

    test('a container id is the line of its first block', () {
      final chapter = convert(
        '<p>a</p><section id="s"><div id="d"><p>b</p></div></section>',
      );
      expect(chapter.anchors, {'s': 2, 'd': 2});
    });

    test('an id on a multi-line block does not shift the next', () {
      final chapter = convert('<pre>a\nb\nc</pre><p id="after">d</p>');
      expect(chapter.anchors, {'after': 6});
      expect(chapter.markdown.split('\n')[6], 'd');
    });
  });

  group('math', () {
    test('a formula SVG is its TeX again, inline and display', () {
      expect(
        markdown(
          '<p>a <svg class="math" role="img" aria-label="x^2+1">'
          '<path/></svg> b</p>'
          '<div class="math-block"><svg class="math math-display" '
          r'aria-label="\frac{a}{b}"><path/></svg></div>',
        ),
        r'a $x^2+1$ b'
        '\n\n'
        r'$$\frac{a}{b}$$',
      );
    });

    test('a dollar inside the TeX is escaped for the app syntax', () {
      expect(
        markdown(r'<p><svg class="math" aria-label="a\$b"/></p>'),
        r'$a\$b$',
      );
    });

    test('an SVG with no TeX source is still a picture', () {
      expect(
        markdown('<p><svg><image xlink:href="a.png"/></svg></p>'),
        '![](pic:a.png)',
      );
    });
  });

  group('pictures and links', () {
    test('a picture is named by the book', () {
      expect(
        markdown('<p><img src="../img/a.png" alt="An *A*"/></p>'),
        r'![An \*A\*](pic:../img/a.png)',
      );
      expect(pictures, ['../img/a.png']);
    });

    test('pictures are inline, as a browser has them; an SVG image is one', () {
      expect(
        markdown(
          '<img src="a.png"/><svg><image xlink:href="b.jpg"/></svg>'
          '<div><img src="c.gif"/></div>',
        ),
        '![](pic:a.png)![](pic:b.jpg)\n\n![](pic:c.gif)',
      );
    });

    test('a picture the book does not have is left out', () {
      expect(markdown('<p>a<img src="missing.png"/></p>'), 'a');
    });

    test('a link is named by the book, its words escaped', () {
      expect(
        markdown('<p><a href="ch2.xhtml#s1">Part #2</a></p>'),
        r'[Part \#2](<link:ch2.xhtml#s1>)',
      );
      expect(links, ['ch2.xhtml#s1']);
    });

    test('a link with no href or no words is its words', () {
      expect(markdown('<p><a id="x">here</a><a href="a"> </a></p>'), 'here');
      expect(links, isEmpty);
    });
  });
}
