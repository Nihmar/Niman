/// The one rule every path reads a note by (#353).
///
/// A note's file is plain bytes, and a `.md` from an imported vault may
/// carry bytes that are not UTF-8 (Latin-1, say). The editor loader used to
/// decode strictly and call such a file "not text", so the editor refused to
/// open it while note ops, the index, the widget and export read the same
/// file leniently — one note, two answers. Now every path decodes by
/// [decodeNoteText], so a file the rest of the app has accepted as a note
/// opens in the editor too.
///
/// A byte that is not part of a UTF-8 sequence is read as the Windows-1252
/// character it is there (Latin-1 above `0xA0`): `caf\xE9` is `café`. It
/// used to become U+FFFD, and the first save — or a Replace all that
/// matched another word — wrote U+FFFD back over the byte, so an accent the
/// user never touched was gone from the file. Read as the character it
/// most likely is, the text survives, and saving writes it as UTF-8: the
/// file's encoding changes, the words in it do not (decided 2026-09-28).
///
/// The loader still refuses a file that is not text at all (issue #156):
/// [looksBinary] is that judgement, kept apart from the decode so it can be
/// read and tested on its own.
library;

import 'dart:convert';

/// [bytes] as a note's text: UTF-8, with every byte that is not part of a
/// UTF-8 sequence read as its Windows-1252 character. This is the rule the
/// editor loader, note ops, the index, the widget, export and replace all
/// read by.
String decodeNoteText(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return _decodeMixed(bytes);
  }
}

/// [bytes] decoded by [decodeNoteText] as they arrive, for a reader that
/// streams a note rather than holding it: a UTF-8 sequence cut between two
/// chunks is decoded whole, once the rest of it has come.
Stream<String> decodeNoteTextStream(Stream<List<int>> bytes) async* {
  var carry = const <int>[];
  await for (final chunk in bytes) {
    final data = carry.isEmpty ? chunk : <int>[...carry, ...chunk];
    final cut = _completeUpTo(data);
    carry = data.sublist(cut);
    if (cut > 0) yield decodeNoteText(data.sublist(0, cut));
  }
  if (carry.isNotEmpty) yield decodeNoteText(carry);
}

/// The share of a file's bytes that may be outside any UTF-8 sequence
/// before it is read as a binary file rather than a note: one in three.
const double _undecodableRatio = 0.3;

/// Whether [bytes] are a binary file rather than a note's text.
///
/// A NUL byte says binary outright — no text a person writes carries one,
/// and every image, archive and executable is full of them. Failing that, a
/// file with a high ratio of bytes that belong to no UTF-8 sequence is
/// binary too. A Latin-1 word such as `caf\xE9` has one such byte in four
/// and is text.
bool looksBinary(List<int> bytes) {
  for (final byte in bytes) {
    if (byte == 0) return true;
  }
  if (bytes.isEmpty) return false;
  var undecodable = 0;
  var at = 0;
  while (at < bytes.length) {
    final length = _sequenceLength(bytes, at);
    if (length == 0) {
      undecodable++;
      at++;
    } else {
      at += length;
    }
  }
  return undecodable / bytes.length > _undecodableRatio;
}

/// [bytes], which are not all UTF-8: each valid run decoded as UTF-8, each
/// byte outside one as its Windows-1252 character.
String _decodeMixed(List<int> bytes) {
  final out = StringBuffer();
  const utf8Strict = Utf8Decoder();
  var run = 0;
  var at = 0;
  while (at < bytes.length) {
    final length = _sequenceLength(bytes, at);
    if (length > 0) {
      at += length;
      continue;
    }
    if (run < at) out.write(utf8Strict.convert(bytes, run, at));
    out.writeCharCode(_windows1252(bytes[at]));
    at++;
    run = at;
  }
  if (run < bytes.length) out.write(utf8Strict.convert(bytes, run));
  return out.toString();
}

/// The length of the well-formed UTF-8 sequence starting at [at], or 0 when
/// none does (a stray continuation byte, a lead byte whose sequence is cut
/// short, an overlong form, a surrogate, a code point past U+10FFFF).
int _sequenceLength(List<int> bytes, int at) {
  final lead = bytes[at];
  if (lead < 0x80) return 1;
  bool continuation(int offset, [int low = 0x80, int high = 0xBF]) {
    final index = at + offset;
    if (index >= bytes.length) return false;
    final byte = bytes[index];
    return byte >= low && byte <= high;
  }

  if (lead >= 0xC2 && lead <= 0xDF) return continuation(1) ? 2 : 0;
  if (lead == 0xE0) {
    return continuation(1, 0xA0) && continuation(2) ? 3 : 0;
  }
  if ((lead >= 0xE1 && lead <= 0xEC) || lead == 0xEE || lead == 0xEF) {
    return continuation(1) && continuation(2) ? 3 : 0;
  }
  if (lead == 0xED) {
    return continuation(1, 0x80, 0x9F) && continuation(2) ? 3 : 0;
  }
  if (lead == 0xF0) {
    return continuation(1, 0x90) && continuation(2) && continuation(3) ? 4 : 0;
  }
  if (lead >= 0xF1 && lead <= 0xF3) {
    return continuation(1) && continuation(2) && continuation(3) ? 4 : 0;
  }
  if (lead == 0xF4) {
    return continuation(1, 0x80, 0x8F) && continuation(2) && continuation(3)
        ? 4
        : 0;
  }
  return 0;
}

/// How much of [data] can be decoded now without cutting a UTF-8 sequence
/// the next chunk may complete: all of it, unless it ends inside one.
int _completeUpTo(List<int> data) {
  // A sequence is at most four bytes: its lead is among the last four.
  for (var back = 1; back <= 4 && back <= data.length; back++) {
    final at = data.length - back;
    final byte = data[at];
    if (byte >= 0x80 && byte <= 0xBF) continue;
    final needs = switch (byte) {
      >= 0xC2 && <= 0xDF => 2,
      >= 0xE0 && <= 0xEF => 3,
      >= 0xF0 && <= 0xF4 => 4,
      _ => 1,
    };
    return at + needs > data.length ? at : data.length;
  }
  return data.length;
}

/// The Windows-1252 character of [byte], a byte outside any UTF-8
/// sequence: Latin-1 for `0xA0`–`0xFF`, the typographic characters
/// Windows puts in `0x80`–`0x9F`, and the C1 control a byte there stands
/// for where Windows-1252 has none (`0x81`, `0x8D`, `0x8F`, `0x90`,
/// `0x9D`).
int _windows1252(int byte) {
  if (byte < 0x80 || byte > 0x9F) return byte;
  return const <int>[
    0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F, //
    0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, //
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178, //
  ][byte - 0x80];
}
