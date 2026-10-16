/// A note's links read a slice at a time (#1040), for the mention a row of
/// "Links to this note" shows.
///
/// Only the first mention of the target is shown, so the referrer is not read
/// whole: a slice of it is read, its links listed, and the reader asks for the
/// next one only when the first did not name the target. A character note
/// linked from line 3 of a 40 MB manuscript costs one slice, not 40 MB.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/markdown/note_load.dart' show normalizedLineEndings;

/// How many bytes one slice reads, to the end of the block it stops in.
const int spotSliceBytes = 256 * 1024;

/// How many bytes one slice may grow to when no block ends within
/// [spotSliceBytes] (a single paragraph of a novel): a slice is never cut
/// inside one before that.
const int spotSliceMaxBytes = 16 * 1024 * 1024;

/// Where the next slice of a note starts: a byte, and the line it is on.
typedef SpotCursor = ({int offset, int line});

/// The cursor at the start of a note.
const SpotCursor spotCursorStart = (offset: 0, line: 0);

/// The links of one slice of a note, with their lines counted from the
/// note's start, and where the next slice starts; null when the note ends
/// with this one.
typedef SpotSlice = ({List<LinkSpot> spots, SpotCursor? next});

/// The slice of the note file at absolute [path] that starts at [from]: work
/// for a background isolate. A slice ends where a block does (after a blank
/// line outside a code fence), so no link is cut in two.
SpotSlice linkSpotSliceOfFile(
  String path,
  SpotCursor from, {
  int sliceBytes = spotSliceBytes,
}) {
  final file = File(path).openSync();
  try {
    final length = file.lengthSync();
    var want = sliceBytes;
    while (true) {
      file.setPositionSync(from.offset);
      final bytes = file.readSync(want);
      final ends = from.offset + bytes.length >= length;
      var cut = bytes.length;
      if (!ends) {
        cut = blockEnd(bytes);
        if (cut == 0) {
          if (want < spotSliceMaxBytes) {
            want = math.min(want * 2, spotSliceMaxBytes);
            continue;
          }
          cut = _characterEnd(bytes);
        }
      }
      final read = cut == bytes.length ? bytes : bytes.sublist(0, cut);
      var text = decodeNoteText(read);
      if (from.offset == 0 && text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
        text = text.substring(1);
      }
      final lines = _lineBreaks(normalizedLineEndings(text));
      final spots = <LinkSpot>[
        for (final s in linkSpotsOf(text))
          (
            target: s.target,
            markdown: s.markdown,
            embed: s.embed,
            line: s.line + from.line,
            context: s.context,
          ),
      ];
      return (
        spots: spots,
        next: from.offset + cut >= length
            ? null
            : (offset: from.offset + cut, line: from.line + lines),
      );
    }
  } finally {
    file.closeSync();
  }
}

int _lineBreaks(String text) {
  var n = 0;
  for (var at = text.indexOf('\n'); at != -1; at = text.indexOf('\n', at + 1)) {
    n++;
  }
  return n;
}

/// The end of the last block in [bytes]: the index after the newline of the
/// last blank line that is not inside a code fence; 0 when there is none.
int blockEnd(List<int> bytes) {
  var cut = 0;
  var fence = 0; // the fence character open, or 0
  var fenceLength = 0;
  var start = 0;
  while (start < bytes.length) {
    var end = start;
    while (end < bytes.length && bytes[end] != 0x0A) {
      end++;
    }
    // A line with no newline yet may go on in the next slice.
    if (end == bytes.length) break;
    var s = start;
    var spaces = 0;
    while (s < end && bytes[s] == 0x20 && spaces < 3) {
      s++;
      spaces++;
    }
    var e = end;
    while (e > s && (bytes[e - 1] == 0x0D || bytes[e - 1] == 0x20)) {
      e--;
    }
    final blank = s == e;
    if (!blank && (bytes[s] == 0x60 || bytes[s] == 0x7E)) {
      var run = 0;
      while (s + run < e && bytes[s + run] == bytes[s]) {
        run++;
      }
      if (run >= 3) {
        if (fence == 0) {
          fence = bytes[s];
          fenceLength = run;
        } else if (bytes[s] == fence && run >= fenceLength && s + run == e) {
          fence = 0;
        }
      }
    } else if (blank && fence == 0) {
      cut = end + 1;
    }
    start = end + 1;
  }
  return cut;
}

/// The length of [bytes] cut where a character begins, for a block longer
/// than a slice may be.
int _characterEnd(List<int> bytes) {
  var cut = bytes.length;
  // Back over UTF-8 continuation bytes to the one that starts the character.
  while (cut > 0 && (bytes[cut - 1] & 0xC0) == 0x80) {
    cut--;
  }
  if (cut > 0 && bytes[cut - 1] >= 0xC0) cut--;
  return cut == 0 ? bytes.length : cut;
}
