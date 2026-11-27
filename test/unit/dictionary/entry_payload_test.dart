// The text of an entry's bytes under the `.ifo`'s `sametypesequence`: `h`
// for a pack of ours, and the other StarDict layouts a pack brought later may
// use.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/entry_payload.dart';

Uint8List _bytes(List<Object> parts) {
  final out = BytesBuilder();
  for (final part in parts) {
    switch (part) {
      case final int byte:
        out.addByte(byte);
      case final String text:
        out.add(utf8.encode(text));
      case final List<int> raw:
        out.add(raw);
    }
  }
  return out.takeBytes();
}

void main() {
  test('one type: the bytes are the text', () {
    expect(EntryPayload.text(_bytes(['<p>x</p>']), 'h'), '<p>x</p>');
    expect(EntryPayload.text(_bytes(['plain']), 'm'), 'plain');
    expect(
      EntryPayload.text(_bytes(['d\u{00E9}j\u{00E0}']), 'h'),
      'd\u{00E9}j\u{00E0}',
    );
  });

  test('one binary type holds no text', () {
    expect(EntryPayload.text(_bytes([1, 2, 3]), 'W'), '');
    expect(EntryPayload.text(Uint8List(0), 'h'), '');
  });

  test('a malformed UTF-8 byte is replaced, never thrown', () {
    expect(EntryPayload.text(_bytes(['a', 0xFF, 'b']), 'h'), 'a\u{FFFD}b');
  });

  test('several types: the first h is read, else the first m', () {
    expect(
      EntryPayload.text(_bytes(['plain', 0, '<p>x</p>']), 'mh'),
      '<p>x</p>',
    );
    expect(EntryPayload.text(_bytes(['plain', 0, 'rest']), 'mm'), 'plain');
    expect(EntryPayload.text(_bytes(['x']), 'mh'), 'x');
  });

  test('a binary field is skipped by its size', () {
    // W: u32 size 3, three bytes; then the last field m.
    final bytes = _bytes([
      [0, 0, 0, 3],
      [9, 9, 9],
      'tail',
    ]);
    expect(EntryPayload.text(bytes, 'Wm'), 'tail');
  });

  test('without a sequence each field names its type', () {
    expect(EntryPayload.text(_bytes(['m', 'plain', 0]), null), 'plain');
    expect(
      EntryPayload.text(_bytes(['m', 'plain', 0, 'h', '<b>x</b>', 0]), null),
      '<b>x</b>',
    );
    expect(
      EntryPayload.text(
        _bytes([
          'W',
          [0, 0, 0, 2],
          [7, 7],
          'm',
          'after',
          0,
        ]),
        null,
      ),
      'after',
    );
  });

  test('a cut entry does not throw', () {
    expect(EntryPayload.text(_bytes(['W', 0, 0]), null), '');
    expect(EntryPayload.text(_bytes(['m', 'cut']), null), 'cut');
  });
}
