// The writer's ways out (`html_hooks.dart`): what a page built on it —
// the export — draws its own way, and what it leaves to `cmark-gfm`'s form.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/html/html_hooks.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';

final class _Hooks extends HtmlHooks {
  const new();

  @override
  String? leaf(LeafNode leaf, List<String> lines) =>
      leaf.kind == BlockKind.fencedCode ? '<pre class="mine"/>' : null;

  @override
  String? callout(Callout callout, String body, String? title) =>
      '<aside data-type="${callout.type}">[$title]$body</aside>';

  @override
  String? headingId(String text) => text.toLowerCase().replaceAll(' ', '-');

  @override
  String? inline(InlineNode node) => switch (node) {
    MathNode(:final tex) => '<m>$tex</m>',
    TagNode(:final name) => '<t>$name</t>',
    HtmlNode() => '&lt;raw&gt;',
    _ => null,
  };

  @override
  String? linkTarget(String destination) => switch (destination) {
    'note.md' => '',
    'other.md' => 'other.html',
    _ => null,
  };

  @override
  String? imageSource(String destination) => 'data:$destination';

  @override
  bool get xhtml => true;
}

String _page(String text) => TreeHtml(text, hooks: const _Hooks()).render();

void main() {
  test('a block the page draws, and one it leaves', () {
    expect(_page('```\nx\n```\n\n    code'), contains('<pre class="mine"/>'));
    expect(_page('    code'), '<pre><code>code\n</code></pre>\n');
  });

  test("a callout's frame, its title's inlines and its body", () {
    expect(
      _page('> [!tip] **T**\n> body'),
      '<aside data-type="tip">[<strong>T</strong>]<p>body</p>\n</aside>\n',
    );
  });

  test('a heading has the id the page gives it', () {
    expect(_page('## Two Words'), '<h2 id="two-words">Two Words</h2>\n');
  });

  test("the app's constructs and raw HTML, as the page draws them", () {
    expect(_page(r'a $x$ #t <b>'), '<p>a <m>x</m> <t>t</t> &lt;raw&gt;</p>\n');
  });

  test('a link repointed, one standing alone, a picture read elsewhere', () {
    expect(
      _page('[a](other.md) [b](note.md) [c](https://x.y) ![p](p.png)'),
      '<p><a href="other.html">a</a> <span>b</span> '
      '<a href="https://x.y">c</a> <img src="data:p.png" alt="p" /></p>\n',
    );
  });

  test("a footnote's attributes have values, as XHTML needs", () {
    final page = _page('a[^1]\n\n[^1]: b');
    expect(page, contains('data-footnote-ref=""'));
    expect(page, contains('data-footnotes=""'));
    expect(page, contains('data-footnote-backref=""'));
  });
}
