// A note as HTML (#24): parsed whole by the Markdown package, with Niman's
// own constructs found by the read view's rules and drawn as it draws them.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';

String body(
  String text, {
  Map<String, String> images = const {},
  Map<String, String> links = const {},
}) => NoteHtml(
  NoteHtmlSource(text: text, title: 't', images: images, links: links),
).body();

void main() {
  test('Markdown is HTML, with ids on the headings', () {
    final html = body('# Title\n\nSome **bold** and _em_.\n');
    expect(html, contains('<h1 id="title">Title</h1>'));
    expect(html, contains('<strong>bold</strong>'));
    expect(html, contains('<em>em</em>'));
  });

  test('frontmatter is not on the page', () {
    final html = body('---\ntitle: x\n---\nText\n');
    expect(html, isNot(contains('title: x')));
    expect(html, contains('<p>Text</p>'));
  });

  test('a formula is an SVG, and the underscores in it are not emphasis', () {
    final html = body(
      r'Where $a_1 + b_1$ and $c_2$ hold.'
      '\n',
    );
    expect(html, contains('<svg '));
    expect(html, isNot(contains('<em>')));
    expect(html, isNot(contains(r'$')));
  });

  test('a math block is a centred formula', () {
    final html = body('Before\n\n\$\$\n\\frac{a}{b}\n\$\$\n\nAfter\n');
    expect(html, contains('<div class="math-block"><svg '));
    expect(html, isNot(contains('<p><div')));
  });

  test('TeX that does not parse is shown as written', () {
    final html = body(
      r'Bad $\frac{a}{$ here'
      '\n',
    );
    expect(html, contains(r'<code class="math-source">$\frac{a}{$</code>'));
  });

  test('one note alone: a wikilink is highlighted text', () {
    final html = body('See [[Other note#Part|there]] and [[Plain]].\n');
    expect(html, contains('<span class="wikilink">there</span>'));
    expect(html, contains('<span class="wikilink">Plain</span>'));
    expect(html, isNot(contains('<a ')));
  });

  test('many notes: a wikilink goes to its page, and to its heading', () {
    final html = body(
      'See [[Other note#Part One|there]].\n',
      links: {'Other note': 'Other%20note.html'},
    );
    expect(
      html,
      contains(
        '<a class="wikilink" href="Other%20note.html#part-one">there</a>',
      ),
    );
  });

  test('a Markdown link to a note is repointed when the export says so', () {
    final html = body(
      '[x](Other.md) and [y](https://example.com)\n',
      links: {'Other.md': 'Other.html'},
    );
    expect(html, contains('<a href="Other.html">x</a>'));
    expect(html, contains('<a href="https://example.com">y</a>'));
  });

  test('pictures the export read are embedded; others stay as written', () {
    final html = body(
      '![[photo.png]] ![[missing.png]] ![alt](img/a%20b.png)\n',
      images: {
        'photo.png': 'data:image/png;base64,AAA',
        'img/a b.png': 'data:image/png;base64,BBB',
      },
    );
    expect(
      html,
      contains('<img class="embed" src="data:image/png;base64,AAA"'),
    );
    expect(html, contains('<span class="embed">![[missing.png]]</span>'));
    expect(html, contains('src="data:image/png;base64,BBB"'));
  });

  test("a task's box shows its state and cannot be ticked", () {
    final html = body('- [x] done\n- [ ] open\n');
    expect(
      html,
      contains('<input type="checkbox" checked="true" disabled="">'),
    );
    expect(html, contains('<input type="checkbox" disabled="">'));
  });

  test('a tag and a highlight', () {
    final html = body('A #tag/sub and ==marked== text\n');
    expect(html, contains('<span class="tag">#tag/sub</span>'));
    expect(html, contains('<mark>marked</mark>'));
  });

  test('a fence is coloured and never read for constructs', () {
    final html = body('```dart\nfinal a = r"\$x\$ [[no]] #no";\n```\n');
    expect(
      html,
      contains('<pre class="code"><code class="hljs language-dart">'),
    );
    expect(html, contains('hljs-keyword'));
    expect(html, isNot(contains('wikilink')));
    expect(html, isNot(contains('<svg')));
  });

  test('a fence inside a list item stays in the item', () {
    final html = body('1. one\n\n   ```\n   code\n   ```\n\n2. two\n');
    expect(html, contains('<ol>'));
    expect(RegExp('<ol').allMatches(html), hasLength(1));
    expect(html, contains('<pre class="code">'));
  });

  test('a callout is framed in its colour; a folding one is <details>', () {
    final html = body('> [!warning]- Mind the gap\n> Body with \$x\$.\n');
    expect(html, contains('<details class="callout" data-callout="warning"'));
    expect(html, contains('<summary class="callout-title">Mind the gap'));
    expect(html, contains('<div class="callout-body"><p>Body with <svg '));
  });

  test('a plain quote keeps its constructs', () {
    final html = body('> quoted #tag and `code`\n');
    expect(html, contains('<blockquote>'));
    expect(html, contains('<span class="tag">#tag</span>'));
    expect(html, contains('<code>code</code>'));
  });

  test('raw HTML is shown as the source it is', () {
    final html = body('<div onclick="x()">hi</div>\n\ninline <b>b</b>\n');
    expect(html, contains('<pre class="html-source">'));
    expect(html, contains('&lt;div onclick'));
    expect(html, contains('&lt;b&gt;b&lt;/b&gt;'));
  });

  test('a construct in an attribute is its plain text', () {
    final html = body(
      r'![a $x$ #t](p.png)'
      '\n',
    );
    expect(html, contains(r'alt="a $x$ #t"'));
  });

  test("a fence's indent counts a tab as columns", () {
    // CommonMark 4.5: a tab advances to the next multiple of four, so the
    // two columns of fence indent come out of it and two stay.
    final html = body('  ```\n\tvar x = 1;\n  ```\n');
    expect(html, contains('  var x = 1;'));
  });

  test("the note's own sentinel characters stay the text they are", () {
    // The masking tokens are private-use pairs around a number; a note that
    // holds the pair itself must not index into the pieces (#63 review, L2).
    final html = body('A \uE00199\uE002 glyph, and a \uE0010\uE002 one.\n');
    expect(html, contains('\uE00199\uE002'));
    expect(html, contains('\uE0010\uE002'));
    // The constructs still land where they should.
    expect(
      body('Text **bold** \uE00199\uE002.'),
      contains('<strong>bold</strong>'),
    );
  });

  test('the page is one file with its title and the fonts only if needed', () {
    final page = htmlPage(title: 'A <b>', body: '<p>x</p>');
    expect(page, startsWith('<!DOCTYPE html>'));
    expect(page, contains('<title>A &lt;b&gt;</title>'));
    expect(page, isNot(contains('@font-face')));
  });
}
