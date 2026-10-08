// Windows' `HTML Format` block (#531): a header of byte offsets into the
// UTF-8 block, then the HTML. The offsets count bytes, so a character of
// more than one byte before the fragment is where reading them as
// characters would cut in the wrong place.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/paste/cf_html.dart';

/// A CF_HTML block as a browser writes it: [before] and [after] the
/// fragment are its context, and the offsets are worked out in bytes.
Uint8List block(
  String fragment, {
  String before = '<html><body>\r\n<!--StartFragment-->',
  String after = '<!--EndFragment-->\r\n</body>\r\n</html>',
  String? source,
  bool context = true,
}) {
  String header(int startHtml, int endHtml, int startFrag, int endFrag) =>
      'Version:0.9\r\n'
      'StartHTML:${_ten(startHtml)}\r\n'
      'EndHTML:${_ten(endHtml)}\r\n'
      'StartFragment:${_ten(startFrag)}\r\n'
      'EndFragment:${_ten(endFrag)}\r\n'
      '${source == null ? '' : 'SourceURL:$source\r\n'}';
  final none = context ? 0 : -1;
  final headerLength = utf8.encode(header(none, none, 0, 0)).length;
  final beforeLength = utf8.encode(before).length;
  final fragmentLength = utf8.encode(fragment).length;
  final afterLength = utf8.encode(after).length;
  final startFragment = headerLength + beforeLength;
  final endFragment = startFragment + fragmentLength;
  final text =
      header(
        context ? headerLength : -1,
        context ? endFragment + afterLength : -1,
        startFragment,
        endFragment,
      ) +
      before +
      fragment +
      after;
  return Uint8List.fromList([...utf8.encode(text), 0, 0, 0]);
}

String _ten(int n) => n < 0 ? '-1' : n.toString().padLeft(10, '0');

void main() {
  test('the fragment and its context are read at their byte offsets', () {
    final read = parseCfHtml(
      block(
        '<li>one</li><li>two</li>',
        before: '<html><body>\r\n<ul><!--StartFragment-->',
        after: '<!--EndFragment--></ul>\r\n</body>\r\n</html>',
        source: 'https://example.com/list',
      ),
    )!;
    expect(read.fragment, '<li>one</li><li>two</li>');
    expect(read.html, startsWith('<html><body>'));
    expect(read.html, contains('<ul><!--StartFragment--><li>one'));
    expect(read.html, endsWith('</html>'));
    expect(read.source, Uri.parse('https://example.com/list'));
  });

  test('characters of several bytes before the fragment do not move it', () {
    final read = parseCfHtml(
      block(
        '<p>naïve café — 日本語</p>',
        before:
            '<html><head><title>Ça va? 東京</title></head><body>\r\n'
            '<!--StartFragment-->',
        source: 'https://example.com/caf%C3%A9',
      ),
    )!;
    expect(read.fragment, '<p>naïve café — 日本語</p>');
    expect(read.html, contains('<title>Ça va? 東京</title>'));
    expect(read.source.toString(), 'https://example.com/caf%C3%A9');
  });

  test('without context (-1) the fragment is the HTML', () {
    final read = parseCfHtml(block('<b>bold</b> words', context: false))!;
    expect(read.fragment, '<b>bold</b> words');
    expect(read.html, contains('<b>bold</b> words'));
  });

  test('offsets past the block fall back to the markers', () {
    const text =
        'Version:0.9\r\n'
        'StartHTML:0000099999\r\n'
        'EndHTML:0000099999\r\n'
        'StartFragment:0000099999\r\n'
        'EndFragment:0000099999\r\n'
        '<html><body><!--StartFragment--><i>it</i><!--EndFragment-->'
        '</body></html>';
    final read = parseCfHtml(Uint8List.fromList(utf8.encode(text)))!;
    expect(read.fragment, '<i>it</i>');
    expect(read.html, startsWith('<html><body>'));
    expect(read.source, isNull);
  });

  test('a source that is not a web page is not a source', () {
    final read = parseCfHtml(block('<p>x</p>', source: 'about:blank'))!;
    expect(read.source, isNull);
  });

  test('a block with no header, or nothing after it, is no HTML', () {
    expect(parseCfHtml(Uint8List.fromList(utf8.encode('<p>x</p>'))), isNull);
    expect(parseCfHtml(Uint8List(0)), isNull);
    expect(
      parseCfHtml(
        Uint8List.fromList(utf8.encode('Version:0.9\r\nStartHTML:-1\r\n')),
      ),
      isNull,
    );
  });
}
