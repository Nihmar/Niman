// #928: the exported page leaves a trailing block id (`## Title ^abc`,
// `A paragraph. ^abc`) out of the text it draws, as the read view does, and
// gives the block an `id` a `[[note#^abc]]` link lands on.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/html_spans.dart' show blockAnchor;
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:xml/xml.dart';

String _body(String text, {Map<String, String> links = const {}}) =>
    NoteHtml(NoteHtmlSource(text: text, title: 't', links: links)).body();

/// The ids a body holds, in document order.
List<String> _ids(String html) => [
  for (final element in XmlDocument.parse('<r>$html</r>').findAllElements('*'))
    ?element.getAttribute('id'),
];

void main() {
  group('a heading that ends with a block id', () {
    test("draws the text alone, with its own id and the block's", () {
      final html = _body('## Title ^abc\n');
      expect(html, contains('<h2 id="title">'));
      expect(html, contains('<span id="block.abc">Title</span>'));
      expect(html, isNot(contains('^abc')));
    });

    test('a setext heading too', () {
      final html = _body('Title ^abc\n=====\n');
      expect(html, contains('<h1 id="title"><span id="block.abc">Title'));
      expect(html, isNot(contains('^abc')));
    });

    test('a heading without one is as it was', () {
      expect(_body('## Title\n'), '<h2 id="title">Title</h2>\n');
    });

    test('the exported page does not show it', () async {
      final payload = await exportNote(
        text: '## Title ^abc\n\nA paragraph. ^def\n',
        title: 'T',
        path: 'Notes/T.md',
        root: '/lib',
        language: 'en',
        format: ExportFileFormat.html,
      );
      final page = String.fromCharCodes(payload.bytes);
      expect(page, isNot(contains('^abc')));
      expect(page, isNot(contains('^def')));
      expect(page, contains('id="block.abc"'));
      expect(page, contains('<p id="block.def">A paragraph.</p>'));
    });
  });

  group('a paragraph that ends with a block id', () {
    test('draws the text alone, on a <p> that carries the id', () {
      final html = _body('A paragraph. ^abc\n');
      expect(html, '<p id="block.abc">A paragraph.</p>\n');
    });

    test('its inline formatting is kept', () {
      final html = _body('Some **bold** ^abc\n\nSome _em_ and `code` ^def\n');
      expect(
        html,
        contains('<p id="block.abc">Some <strong>bold</strong></p>'),
      );
      expect(
        html,
        contains(
          '<p id="block.def">Some <em>em</em> and <code>code</code></p>',
        ),
      );
    });

    test('the id of a paragraph of several lines is at its last', () {
      final html = _body('first line\nsecond line ^abc\n');
      expect(html, contains('<p id="block.abc">first line\nsecond line</p>'));
    });

    test('a caret that does not end the text is text', () {
      final html = _body('2 ^ 3 and x ^y z\n\nsee ^abc here\n');
      expect(html, contains('<p>2 ^ 3 and x ^y z</p>'));
      expect(html, contains('<p>see ^abc here</p>'));
      expect(_ids(html), isEmpty);
    });

    test('a list item has no <p>: the text carries the id', () {
      final html = _body('- one ^abc\n- two\n');
      expect(html, contains('<li><span id="block.abc">one</span></li>'));
      expect(html, contains('<li>two</li>'));
      expect(html, isNot(contains('^abc')));
    });

    test('a task item keeps its box', () {
      final html = _body('- [ ] one ^abc\n');
      expect(html, contains('<input type="checkbox"'));
      expect(html, contains('<span id="block.abc">one</span>'));
    });

    test('a loose list item and a quote have a <p> to carry it', () {
      final html = _body('- one ^abc\n\n- two\n\n> quoted ^def\n');
      expect(html, contains('<p id="block.abc">one</p>'));
      expect(html, contains('<p id="block.def">quoted</p>'));
    });

    test('a line of only an id names the block above, and draws nothing', () {
      final html = _body('> a quote\n> goes on\n\n^abc\n\nafter\n');
      expect(html, contains('<span id="block.abc"></span>'));
      expect(html, isNot(contains('^abc')));
      expect(html, contains('<p>after</p>'));
    });

    test('an id that is in a fence is code', () {
      final html = _body('```\ncode ^abc\n```\n');
      expect(html, contains('code ^abc'));
      expect(_ids(html), isEmpty);
    });

    test('the first block with an id owns it', () {
      final html = _body('one ^abc\n\ntwo ^abc\n');
      expect(_ids(html), ['block.abc']);
      expect(html, isNot(contains('^abc')));
      expect(html, contains('<p>two</p>'));
    });

    test('the plain writer, without hooks, draws the text as written', () {
      expect(
        TreeHtml('A paragraph. ^abc\n').render(),
        '<p>A paragraph. ^abc</p>\n',
      );
    });
  });

  group('a link to a block', () {
    final links = {'Other': 'Other.html'};

    test('goes to the id the block carries', () {
      final linking = _body('See [[Other#^abc|there]].\n', links: links);
      final target = _body('A paragraph. ^abc\n');
      final href = RegExp('href="([^"]*)"').firstMatch(linking)!.group(1)!;
      expect(href, 'Other.html#${blockAnchor('abc')}');
      final fragment = href.substring(href.indexOf('#') + 1);
      expect(_ids(target), contains(fragment));
    });

    test("reaches a heading's block, a list item's and a quote's", () {
      const ids = ['h-1', 'item', 'Quote9'];
      final target = _body(
        '## Heading ^h-1\n\n- list ^item\n\n> quoted ^Quote9\n',
      );
      for (final id in ids) {
        final linking = _body('[[Other#^$id]]\n', links: links);
        final href = RegExp('href="([^"]*)"').firstMatch(linking)!.group(1)!;
        expect(_ids(target), contains(href.split('#').last), reason: id);
      }
    });

    test('never lands on a heading of the same name', () {
      final html = _body('## Abc\n\nA paragraph. ^abc\n');
      expect(_ids(html), ['abc', 'block.abc']);
    });

    test('a heading link still lands on the heading', () {
      final linking = _body('[[Other#Title]]\n', links: links);
      expect(linking, contains('href="Other.html#title"'));
      expect(_ids(_body('## Title ^abc\n')), ['title', 'block.abc']);
    });
  });
}
