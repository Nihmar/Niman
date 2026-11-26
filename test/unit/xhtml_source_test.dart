// XHTML given to the HTML parser (#1304): an XML document's self-closed
// elements are empty ones, and the parser would open them and hold the rest
// of the page in them.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/from_html/html_markdown.dart';
import 'package:niman/src/markdown/from_html/xhtml_source.dart';

void main() {
  group('expandSelfClosed', () {
    test('writes a self-closed element that is not void as a pair', () {
      expect(
        expandSelfClosed('<head><title/></head><p><a id="p1"/>Text</p>'),
        '<head><title></title></head><p><a id="p1"></a>Text</p>',
      );
      expect(
        expandSelfClosed('<span class="x" />'),
        '<span class="x" ></span>',
      );
      expect(expandSelfClosed('<epub:x a="1"/>'), '<epub:x a="1"></epub:x>');
    });

    test('keeps the slash of a void element', () {
      const source =
          '<p>a<br/>b<img src="a.png" alt=""/><hr/></p>'
          '<meta charset="utf-8"/><link rel="x" href="y"/>';
      expect(expandSelfClosed(source), source);
      expect(expandSelfClosed('<BR/><IMG src="a"/>'), '<BR/><IMG src="a"/>');
    });

    test('leaves what is not a start tag as it is', () {
      const source =
          '<!DOCTYPE html><?pi a="<b/>"?><!-- <i/> -->'
          '<![CDATA[ <u/> ]]><p title="a/>b" alt=\'<s/>\'>1 < 2 and 3 > 2</p>';
      expect(expandSelfClosed(source), source);
    });

    test('expands the ones around them, and a document that ends oddly', () {
      expect(
        expandSelfClosed('<!-- <i/> --><b/><p title="a/>b"><u/></p><i'),
        '<!-- <i/> --><b></b><p title="a/>b"><u></u></p><i',
      );
      expect(expandSelfClosed('<a href="x/>'), '<a href="x/>');
    });
  });

  group('HtmlMarkdown, told it is XHTML', () {
    final converter = HtmlMarkdown(picture: (src) => src, link: (href) => href);

    test('a self-closed <title/> does not swallow the page', () {
      const page =
          '<html><head><title/></head><body><p>Kept.</p></body></html>';
      expect(converter.convert(page, xhtml: true).markdown, 'Kept.');
    });

    test('a self-closed <script/> and <style/> do not either', () {
      const page =
          '<html><head><script src="a.js"/><style/></head>'
          '<body><p>Kept.</p></body></html>';
      expect(converter.convert(page, xhtml: true).markdown, 'Kept.');
    });

    test('an empty anchor wraps nothing, and keeps its place', () {
      final chapter = converter.convert(
        '<html><body><a id="c1"/><h1>Title</h1><p><a id="p1"/>One</p>'
        '<a id="p2"/><p>Two</p></body></html>',
        xhtml: true,
      );
      expect(chapter.markdown, '# Title\n\nOne\n\nTwo');
      expect(chapter.anchors['p1'], 2);
    });

    test('an empty emphasis or link does not style what follows', () {
      final chapter = converter.convert(
        '<html><body><p><em/>plain <a href="x"/>text</p><p>after</p>'
        '</body></html>',
        xhtml: true,
      );
      expect(chapter.markdown, 'plain text\n\nafter');
    });

    test('a page of HTML is read as a browser reads it', () {
      // Not told, nothing is rewritten: a captured page's `<title/>` opens a
      // title there, as it does in every browser.
      const page = '<html><head><title/></head><body><p>x</p></body></html>';
      expect(converter.convert(page).markdown, isNot('x'));
      expect(converter.convert(page, xhtml: true).markdown, 'x');
    });
  });
}
