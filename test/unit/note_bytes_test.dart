// The one rule every path reads a note's bytes by (#353): UTF-8, and a byte
// outside any UTF-8 sequence read as its Windows-1252 character — never
// U+FFFD, which a save then wrote over the byte for good.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/note_bytes.dart';

void main() {
  group('decodeNoteText', () {
    test('UTF-8 reads as UTF-8', () {
      expect(decodeNoteText(utf8.encode('città — 日本 🎉')), 'città — 日本 🎉');
    });

    test('a byte outside UTF-8 is its Windows-1252 character', () {
      expect(decodeNoteText(<int>[0x63, 0x61, 0x66, 0xE9]), 'café');
      // The typographic range Windows puts where Latin-1 has controls.
      expect(decodeNoteText(<int>[0x80, 0x93, 0x61, 0x94, 0x85]), '€“a”…');
      // A byte Windows-1252 leaves undefined stands for its C1 control.
      expect(decodeNoteText(<int>[0x81]), '\u0081');
      expect(decodeNoteText(<int>[0xFF]), 'ÿ');
    });

    test('UTF-8 and stray bytes mixed in one note both survive', () {
      expect(
        decodeNoteText(<int>[...utf8.encode('è'), 0xE9, ...utf8.encode('!')]),
        'èé!',
      );
    });

    test('an ill-formed sequence is read byte by byte', () {
      // Cut short at the end.
      expect(decodeNoteText(<int>[0xE2, 0x82]), 'â‚');
      // Overlong.
      expect(decodeNoteText(<int>[0xC0, 0xAF]), 'À¯');
      // A surrogate encoded as UTF-8.
      expect(decodeNoteText(<int>[0xED, 0xA0, 0x80]), 'í €');
    });

    test('whatever the bytes, no U+FFFD is made up', () {
      final all = List<int>.generate(256, (byte) => byte);
      expect(decodeNoteText(all), isNot(contains('�')));
    });
  });

  group('decodeNoteTextStream', () {
    test('a sequence cut between two chunks is decoded whole', () async {
      final bytes = <int>[
        ...utf8.encode('a città 🎉 '),
        0xE9,
        ...utf8.encode(' fine'),
      ];
      final whole = decodeNoteText(bytes);
      for (var cut = 0; cut <= bytes.length; cut++) {
        final chunks = Stream<List<int>>.fromIterable([
          bytes.sublist(0, cut),
          bytes.sublist(cut),
        ]);
        expect(
          (await decodeNoteTextStream(chunks).toList()).join(),
          whole,
          reason: 'cut at $cut',
        );
      }
    });

    test('a stray byte at the very end is read, not dropped', () async {
      final chunks = Stream<List<int>>.fromIterable([
        utf8.encode('caf'),
        <int>[0xE9],
      ]);
      expect((await decodeNoteTextStream(chunks).toList()).join(), 'café');
    });
  });

  group('looksBinary', () {
    test('a Latin-1 note is text, a NUL or a run of stray bytes is not', () {
      expect(looksBinary(<int>[0x63, 0x61, 0x66, 0xE9, 0x0A]), isFalse);
      expect(looksBinary(<int>[0x61, 0x00, 0x62]), isTrue);
      expect(looksBinary(List<int>.filled(64, 0xFF)), isTrue);
      expect(looksBinary(const <int>[]), isFalse);
    });

    test('a note that holds U+FFFD itself is text', () {
      // Valid UTF-8 for the replacement character: a character like any
      // other, not a sign of a binary file.
      expect(looksBinary(utf8.encode('�' * 20)), isFalse);
    });

    test('a valid UTF-8 note takes one native decode, no byte walk (#496)', () {
      // The two Dart passes over the bytes — a NUL scan and a UTF-8
      // sequence walk — ran before the native decode on every note.
      final decodes = noteBytesNativeDecodes;
      final walks = noteBytesWalks;
      expect(looksBinary(utf8.encode('città — 日本 🎉\n')), isFalse);
      expect(noteBytesNativeDecodes - decodes, 1);
      expect(noteBytesWalks - walks, 0);
    });

    test('NUL bytes are weighed by their share, not refused outright', () {
      // A third of the file: binary, and so a UTF-16 file it reads.
      expect(looksBinary(List<int>.filled(64, 0)), isTrue);
      // One stray NUL in a note that is otherwise text: read as text, the
      // same answer the index, replace and export give it.
      final stray = <int>[
        ...utf8.encode('a long note, '),
        0,
        ...utf8.encode('and then more text\n'),
      ];
      expect(looksBinary(stray), isFalse);
    });
  });
}
