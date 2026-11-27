// A note in UTF-16 or UTF-32 with its byte order mark is read as the text it
// holds and written back in the encoding it had (#1332): it used to be read
// as Windows-1252, opened as mojibake, and one keystroke saved the mojibake
// as UTF-8.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/markdown/note_encoding.dart';
import 'package:niman/src/markdown/note_framing.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:path/path.dart' as p;

/// [text] as the file of [encoding] holds it, byte order mark first: the
/// slow, obviously right version the encoder is held to.
List<int> fileOf(NoteEncoding encoding, String text) {
  final out = <int>[];
  void unit(int value, int width, {required bool little}) {
    final bytes = [for (var i = 0; i < width; i++) (value >> (8 * i)) & 0xFF];
    out.addAll(little ? bytes : bytes.reversed);
  }

  final little =
      encoding == NoteEncoding.utf16le || encoding == NoteEncoding.utf32le;
  final wide32 =
      encoding == NoteEncoding.utf32le || encoding == NoteEncoding.utf32be;
  for (final point in '\u{FEFF}$text'.runes) {
    if (wide32) {
      unit(point, 4, little: little);
    } else if (point > 0xFFFF) {
      final v = point - 0x10000;
      unit(0xD800 + (v >> 10), 2, little: little);
      unit(0xDC00 + (v & 0x3FF), 2, little: little);
    } else {
      unit(point, 2, little: little);
    }
  }
  return out;
}

const List<NoteEncoding> _wide = [
  NoteEncoding.utf16le,
  NoteEncoding.utf16be,
  NoteEncoding.utf32le,
  NoteEncoding.utf32be,
];

const _samples = {
  'ASCII': '# Title\n\nsome words\n',
  'Cyrillic': '# Заголовок\n\nнемного слов\n',
  'CJK': '# 日本語の題\n\nいくつかの言葉\n',
  'astral': '# 🎉 party\n\n𝄞 clef\n',
};

void main() {
  group('a note with a UTF-16 or UTF-32 byte order mark', () {
    for (final encoding in _wide) {
      for (final MapEntry(key: name, value: text) in _samples.entries) {
        test('${encoding.name} $name is the text it holds', () {
          final bytes = fileOf(encoding, text);
          expect(NoteEncoding.wideOf(bytes), encoding);
          expect(decodeNoteText(bytes), text);
          final decoded = decodeNoteBytes(bytes)!;
          expect(decoded.text, text);
          expect(decoded.encoding, encoding);
          expect(decoded.lenient, isFalse);
          expect(looksBinary(bytes), isFalse);
          expect(encoding.encode('\u{FEFF}$text'), bytes);
        });
      }
    }

    test('an empty UTF-16 note is empty, and written back with its mark', () {
      final bytes = fileOf(NoteEncoding.utf16le, '');
      expect(bytes, [0xFF, 0xFE]);
      expect(decodeNoteText(bytes), '');
      expect(decodeNoteBytes(bytes)!.encoding, NoteEncoding.utf16le);
    });

    test('a UTF-16 file of odd length is not read as UTF-16', () {
      final bytes = [...fileOf(NoteEncoding.utf16le, 'abc'), 0x20];
      expect(NoteEncoding.wideOf(bytes), isNull);
    });

    test('UTF-32 needs code points: a UTF-16 LE file that starts with a '
        'NUL character stays UTF-16', () {
      final bytes = fileOf(NoteEncoding.utf16le, '\u0000abcd');
      expect(bytes.take(4), [0xFF, 0xFE, 0x00, 0x00]);
      expect(NoteEncoding.wideOf(bytes), NoteEncoding.utf16le);
    });

    test('UTF-32 with a code point past U+10FFFF is not UTF-32', () {
      final bytes = [0xFF, 0xFE, 0, 0, 0x41, 0, 0x11, 0];
      expect(NoteEncoding.wideOf(bytes), isNot(NoteEncoding.utf32le));
    });

    test('UTF-8, with or without its mark, and Windows-1252, are not wide', () {
      expect(NoteEncoding.wideOf(utf8.encode('\u{FEFF}# café')), isNull);
      expect(NoteEncoding.wideOf(utf8.encode('# café')), isNull);
      expect(NoteEncoding.wideOf(<int>[0x63, 0x61, 0x66, 0xE9]), isNull);
      expect(NoteEncoding.wideOf(const <int>[]), isNull);
    });

    test('property: what is decoded is encoded back byte for byte, lone '
        'surrogates in UTF-16 included', () {
      final random = Random(1332);
      const pieces = ['a', 'é', 'ж', '日', '🎉', '\n', '\r\n', ' '];
      for (var round = 0; round < 300; round++) {
        final out = StringBuffer();
        for (var i = 0, n = random.nextInt(30); i < n; i++) {
          out.write(pieces[random.nextInt(pieces.length)]);
        }
        final text = out.toString();
        for (final encoding in _wide) {
          // A lone surrogate is something UTF-16 holds and UTF-32 does not.
          final probe =
              encoding == NoteEncoding.utf16le ||
                  encoding == NoteEncoding.utf16be
              ? '$text${String.fromCharCode(0xD83D)}x'
              : text;
          final bytes = fileOf(encoding, probe);
          final read = decodeNoteBytes(bytes);
          if (read == null) continue;
          expect(read.encoding, encoding, reason: '$encoding $probe');
          expect(read.text, probe);
          expect(encoding.encode('\u{FEFF}${read.text}'), bytes);
        }
      }
    });

    test('a stream of chunks cut anywhere is read as the whole is', () async {
      final text = _samples['Cyrillic']! * 40;
      for (final encoding in _wide) {
        final bytes = fileOf(encoding, text);
        for (final size in [1, 3, 5, 64, 1000, bytes.length]) {
          final chunks = Stream<List<int>>.fromIterable([
            for (var at = 0; at < bytes.length; at += size)
              bytes.sublist(at, min(at + size, bytes.length)),
          ]);
          expect(
            (await decodeNoteTextStream(chunks).toList()).join(),
            text,
            reason: '${encoding.name} in chunks of $size',
          );
        }
      }
    });

    test(
      'two Latin-1 letters that look like a mark, mid-file, stay Latin-1',
      () async {
        // `ÿþ` is FF FE; only the start of a file can be a byte order mark.
        final bytes = <int>[
          ...List.filled(10, 0x61),
          0xFF,
          0xFE,
          ...List.filled(10, 0x62),
        ];
        final chunks = Stream<List<int>>.fromIterable([
          bytes.sublist(0, 11),
          bytes.sublist(11),
        ]);
        expect(
          (await decodeNoteTextStream(chunks).toList()).join(),
          '${'a' * 10}ÿþ${'b' * 10}',
        );
      },
    );
  });

  group('a UTF-16 or UTF-32 note loaded, edited by a character and saved', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('niman_enc'));
    tearDown(() => dir.deleteSync(recursive: true));

    /// Loads [original], types [typed] after [after], writes it back the way
    /// a save does — framing, then the encoding — and answers the file.
    Future<List<int>> editAndSave(
      NoteEncoding encoding,
      String text, {
      required String after,
      required String typed,
    }) async {
      final file = File(p.join(dir.path, 'note.md'))
        ..writeAsBytesSync(fileOf(encoding, text));
      final loaded = loadNoteSync(file.path) as LoadedNote;
      expect(loaded.text, text.replaceAll('\r\n', '\n'));
      expect(loaded.framing.encoding, encoding);
      expect(loaded.framing.bom, isTrue);
      final buffer = loaded.buffer;
      buffer.insert(buffer.text.indexOf(after) + after.length, typed);
      final slice = loaded.framing.applyToSlice(buffer.text, first: true);
      await saveNoteStream(
        root: dir.path,
        rel: 'note.md',
        produce: (index) async =>
            index > 0 ? null : Uint8List.fromList(loaded.framing.encode(slice)),
      );
      return file.readAsBytesSync();
    }

    for (final encoding in _wide) {
      for (final MapEntry(key: name, value: text) in _samples.entries) {
        test(
          '${encoding.name} $name: one character of the file changes',
          () async {
            final saved = await editAndSave(
              encoding,
              text,
              after: 'words'.contains('w') && name == 'ASCII' ? 'some' : '\n',
              typed: 'X',
            );
            final after = name == 'ASCII' ? 'some' : '\n';
            expect(
              saved,
              fileOf(encoding, text.replaceFirst(after, '${after}X')),
            );
          },
        );
      }
    }

    test('a CRLF note in UTF-16 keeps both', () async {
      const text = '# Заголовок\r\nслова\r\n';
      final saved = await editAndSave(
        NoteEncoding.utf16le,
        text,
        after: 'слова',
        typed: '!',
      );
      expect(
        saved,
        fileOf(NoteEncoding.utf16le, text.replaceFirst('слова', 'слова!')),
      );
    });

    test('the framing of a UTF-8 note says UTF-8', () {
      final file = File(p.join(dir.path, 'a.md'))
        ..writeAsBytesSync(utf8.encode('\u{FEFF}# café\r\n'));
      final loaded = loadNoteSync(file.path) as LoadedNote;
      expect(loaded.framing.encoding, NoteEncoding.utf8);
      expect(loaded.framing.bom, isTrue);
      expect(NoteFraming.plain.encoding, NoteEncoding.utf8);
    });
  });
}
