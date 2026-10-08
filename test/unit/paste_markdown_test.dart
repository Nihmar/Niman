// Paste as Markdown (#531): the clipboard's HTML through the capture's own
// conversion, its relative links resolved against the page it came from,
// and that page linked under it; the plain text when there is no HTML.
//
// The HTML and the expected text run on across their pieces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/paste/clipboard_html.dart';
import 'package:niman/src/capture/paste/paste_markdown.dart';

final Uri _page = Uri.parse('https://app.example.com/blog/offline-first');

void main() {
  group('clipboardMarkdown', () {
    test('the HTML is Markdown, the page linked under it', () {
      final markdown = clipboardMarkdown(
        ClipboardHtml(
          '<p><b>Conflicts</b> should read as a <i>choice</i>.</p>'
          '<ul><li>Show both versions</li><li>Keep the time</li></ul>',
          source: _page,
        ),
      );
      expect(
        markdown,
        '**Conflicts** should read as a *choice*.\n'
        '\n'
        '- Show both versions\n'
        '\n'
        '- Keep the time\n'
        '\n'
        '— [app.example.com](<https://app.example.com/blog/offline-first>)',
      );
    });

    test("the link says the page's title when the HTML has one", () {
      final markdown = clipboardMarkdown(
        ClipboardHtml(
          '<html><head><title>Offline-first, ten [years] later</title>'
          '</head><body><p>Words.</p></body></html>',
          source: _page,
        ),
      );
      expect(
        markdown,
        endsWith(
          r'— [Offline-first, ten \[years\] later]'
          '(<https://app.example.com/blog/offline-first>)',
        ),
      );
    });

    test('relative links and pictures resolve against the page', () {
      final markdown = clipboardMarkdown(
        ClipboardHtml(
          '<p><a href="../sync">the sync</a> and <a href="#notes">notes</a>'
          '</p><p><img src="/img/a.png" alt="A"></p>',
          source: _page,
        ),
      )!;
      expect(markdown, contains('[the sync](<https://app.example.com/sync>)'));
      expect(
        markdown,
        contains('[notes](<https://app.example.com/blog/offline-first#notes>)'),
      );
      expect(markdown, contains('![A](https://app.example.com/img/a.png)'));
    });

    test('without a page nothing is resolved, and nothing is linked', () {
      final markdown = clipboardMarkdown(
        const ClipboardHtml(
          '<p><a href="https://example.com/x">x</a> '
          '<img src="relative.png" alt="gone"> '
          '<img src="https://example.com/y.png" alt="kept"></p>',
        ),
      );
      expect(
        markdown,
        '[x](<https://example.com/x>) ![kept](https://example.com/y.png)',
      );
    });

    test('a picture not on the web is left out', () {
      final markdown = clipboardMarkdown(
        ClipboardHtml(
          '<p>Before <img src="data:image/png;base64,AAAA" alt="inline">'
          '<img src="blob:https://app.example.com/1" alt="blob"> after</p>',
          source: _page,
        ),
      )!;
      expect(markdown, isNot(contains('data:')));
      expect(markdown, isNot(contains('blob:')));
      expect(markdown, startsWith('Before'));
    });

    test("the page's words stay words", () {
      expect(
        clipboardMarkdown(const ClipboardHtml('<p>#tag and [[link]]</p>')),
        r'\#tag and \[\[link\]\]',
      );
    });

    test('HTML with no text comes to nothing', () {
      expect(clipboardMarkdown(const ClipboardHtml('<div> </div>')), isNull);
    });
  });

  group('choosePaste', () {
    test('HTML is pasted as Markdown, with its page', () {
      final choice = choosePaste(
        clip: ClipboardHtml('<p>Hello <b>world</b></p>', source: _page),
        plain: 'Hello world',
      )!;
      expect(choice.markdown, isTrue);
      expect(choice.text, startsWith('Hello **world**'));
      expect(choice.link, _page);
    });

    test('no HTML pastes the plain text', () {
      final choice = choosePaste(plain: 'Hello world')!;
      expect(choice.markdown, isFalse);
      expect(choice.text, 'Hello world');
      expect(choice.link, isNull);
    });

    test('HTML that says nothing pastes the plain text', () {
      final choice = choosePaste(
        clip: const ClipboardHtml('<span></span>'),
        plain: 'text',
      )!;
      expect(choice.markdown, isFalse);
      expect(choice.text, 'text');
    });

    test('an empty clipboard pastes nothing', () {
      expect(choosePaste(), isNull);
      expect(choosePaste(plain: ''), isNull);
    });
  });

  group('the bytes of a clipboard target', () {
    test('UTF-8, with or without its mark and a closing NUL', () {
      final bytes = utf8.encode('<p>café</p>');
      expect(decodeClipboardText(Uint8List.fromList(bytes)), '<p>café</p>');
      expect(
        decodeClipboardText(Uint8List.fromList([0xEF, 0xBB, 0xBF, ...bytes])),
        '<p>café</p>',
      );
      expect(
        decodeClipboardText(Uint8List.fromList([...bytes, 0])),
        '<p>café</p>',
      );
    });

    test('UTF-16, as Firefox has put it on the X11 clipboard', () {
      List<int> le(String text) => [
        for (final unit in text.codeUnits) ...[unit & 0xFF, unit >> 8],
      ];
      List<int> be(String text) => [
        for (final unit in text.codeUnits) ...[unit >> 8, unit & 0xFF],
      ];
      expect(
        decodeClipboardText(
          Uint8List.fromList([0xFF, 0xFE, ...le('<p>é</p>')]),
        ),
        '<p>é</p>',
      );
      expect(
        decodeClipboardText(Uint8List.fromList([0xFE, 0xFF, ...be('日本')])),
        '日本',
      );
      expect(
        decodeClipboardText(
          Uint8List.fromList([...le('https://example.com/'), 0, 0]),
        ),
        'https://example.com/',
      );
    });

    test("a source target's first line is the page", () {
      expect(
        clipboardSourceUrl('https://example.com/a\nThe title'),
        Uri.parse('https://example.com/a'),
      );
      expect(clipboardSourceUrl('about:blank'), isNull);
      expect(clipboardSourceUrl('file:///home/me/a.html'), isNull);
      expect(clipboardSourceUrl(null), isNull);
    });
  });
}
