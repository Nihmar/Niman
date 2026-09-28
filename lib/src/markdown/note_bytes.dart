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
/// The loader still refuses a file that is not text at all (issue #156):
/// [looksBinary] is that judgement, kept apart from the decode so it can be
/// read and tested on its own.
library;

import 'dart:convert';

/// [bytes] decoded as UTF-8 leniently (`allowMalformed: true`): a byte that
/// is not UTF-8 becomes U+FFFD, and a note with a broken byte is still a
/// note. This is the rule the editor loader, note ops, the index, the widget
/// and export all read by.
String decodeNoteText(List<int> bytes) =>
    utf8.decode(bytes, allowMalformed: true);

/// The share of a file's bytes that may decode to U+FFFD before it is read
/// as a binary file rather than a note: one in three.
const double _undecodableRatio = 0.3;

/// Whether [bytes] are a binary file rather than a note's text.
///
/// A NUL byte says binary outright — no text a person writes carries one,
/// and every image, archive and executable is full of them. Failing that, a
/// file whose lenient decode is a high ratio of replacement characters
/// (U+FFFD, one per undecodable byte) is binary too. A Latin-1 word such as
/// `caf\xE9` decodes with a single replacement and is text.
bool looksBinary(List<int> bytes) {
  for (final byte in bytes) {
    if (byte == 0) return true;
  }
  if (bytes.isEmpty) return false;
  var undecodable = 0;
  for (final unit in decodeNoteText(bytes).codeUnits) {
    if (unit == 0xFFFD) undecodable++;
  }
  return undecodable / bytes.length > _undecodableRatio;
}
