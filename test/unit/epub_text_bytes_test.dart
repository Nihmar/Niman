// A text file of an EPUB, from bytes to a string (#1312): by its byte order
// mark, else by the encoding its XML declaration names, else as UTF-8.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_text_bytes.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

/// [text] as UTF-16, [bom] first when it is true.
Uint8List utf16(String text, {required bool bigEndian, bool bom = true}) {
  final out = BytesBuilder();
  void unit(int value) => out.add(
    bigEndian ? [value >> 8, value & 0xFF] : [value & 0xFF, value >> 8],
  );
  if (bom) unit(0xFEFF);
  text.codeUnits.forEach(unit);
  return out.takeBytes();
}

void main() {
  const words = 'Café – naïve 😀 日本語';

  group('decodeEpubText', () {
    test('UTF-8 is read as it is, a byte order mark left out', () {
      expect(decodeEpubText(utf8.encode(words)), words);
      expect(decodeEpubText(Uint8List.fromList([0xEF, 0xBB, 0xBF, 0x61])), 'a');
    });

    test('UTF-16, little or big endian, by its byte order mark', () {
      expect(decodeEpubText(utf16(words, bigEndian: false)), words);
      expect(decodeEpubText(utf16(words, bigEndian: true)), words);
    });

    test('UTF-16 with no mark is told by its `<?`', () {
      const xml = '<?xml version="1.0"?><a>$words</a>';
      expect(decodeEpubText(utf16(xml, bigEndian: false, bom: false)), xml);
      expect(decodeEpubText(utf16(xml, bigEndian: true, bom: false)), xml);
    });

    test('a lone surrogate is U+FFFD, an odd last byte is dropped', () {
      final bytes = Uint8List.fromList([
        ...utf16('a', bigEndian: false),
        0,
        0xD8,
        0x62,
      ]);
      expect(decodeEpubText(bytes), 'a\u{FFFD}');
    });

    test('the byte order mark wins over a declaration that says otherwise', () {
      const xml = '<?xml version="1.0" encoding="UTF-8"?><a>$words</a>';
      expect(decodeEpubText(utf16(xml, bigEndian: false)), xml);
    });

    test('windows-1252 and ISO-8859-1 declared: every byte its character', () {
      // 0x93 0x94 0x80 are Windows' quotes and euro; 0xC3 0xA9 are two
      // letters of Latin-1, not the UTF-8 of one.
      final bytes = [
        ...latin1.encode('<?xml version="1.0" encoding="'),
        ...'windows-1252'.codeUnits,
        ...latin1.encode('"?><p>caf'),
        0xE9, 0x20, 0x93, 0x61, 0x94, 0x20, 0x80, 0x20, 0xC3, 0xA9, //
      ];
      expect(
        decodeEpubText(Uint8List.fromList(bytes)),
        '<?xml version="1.0" encoding="windows-1252"?><p>café “a” € Ã©',
      );
      final iso = Uint8List.fromList([
        ...latin1.encode("<?xml version='1.0' encoding='ISO-8859-1'?>"),
        0xE9,
      ]);
      expect(decodeEpubText(iso), endsWith('é'));
    });

    test('a UTF-8 file, declared or not, is lenient about a bad byte', () {
      const head = '<?xml version="1.0" encoding="utf-8"?>';
      expect(
        decodeEpubText(Uint8List.fromList([...head.codeUnits, 0xE9, 0x61])),
        '$head\u{FFFD}a',
      );
      expect(decodeEpubText(Uint8List.fromList([0xE9, 0x61])), '\u{FFFD}a');
    });

    test('an encoding it does not know is read as UTF-8', () {
      final bytes = utf8.encode(
        '<?xml version="1.0" encoding="x-unknown"?>$words',
      );
      expect(decodeEpubText(Uint8List.fromList(bytes)), endsWith(words));
    });

    test('an empty file is an empty string', () {
      expect(decodeEpubText(Uint8List(0)), '');
    });
  });

  group('a book written in another encoding', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('niman_epub_'));
    tearDown(() => dir.deleteSync(recursive: true));

    String markdownOf(List<int> chapter) => readEpub(
      writeTestEpub(
        p.join(dir.path, 'a.epub'),
        chapters: [(path: 'a.xhtml', body: '')],
        encoded: {'a.xhtml': chapter},
      ).path,
      p.join(dir.path, 'pictures'),
    ).markdown;

    String xhtml(String body, {String declaration = ''}) =>
        '$declaration<html xmlns="http://www.w3.org/1999/xhtml">'
        '<head><title>x</title></head><body><p>$body</p></body></html>';

    test('UTF-16 chapters, little and big endian, read as their text', () {
      final page = xhtml(
        words,
        declaration: '<?xml version="1.0" encoding="UTF-16"?>',
      );
      expect(markdownOf(utf16(page, bigEndian: false)), '$words\n');
      expect(markdownOf(utf16(page, bigEndian: true)), '$words\n');
    });

    test('a windows-1252 chapter reads as its text', () {
      final bytes = [
        ...latin1.encode(
          '<?xml version="1.0" encoding="windows-1252"?>'
          '<html><body><p>caf',
        ),
        ...[0xE9, 0x20, 0x93, 0x61, 0x94],
        ...latin1.encode('</p></body></html>'),
      ];
      expect(markdownOf(bytes), 'café “a”\n');
    });
  });
}
