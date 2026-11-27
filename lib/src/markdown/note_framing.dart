/// What a note's file wraps its text in, which a save writes back (#1056).
///
/// The editor holds every note as plain text with `\n` endings and no byte
/// order mark, which keeps the buffer and everything that reads it simple.
/// The file may have had more: CRLF lines, a UTF-8 BOM, a UTF-16 encoding.
/// Opening such a note and changing one character used to rewrite the whole
/// file — every line ending, the BOM gone — so version control showed every
/// line changed and the sync's line-based merge saw every line differ from
/// the other device's copy. The loader notes what the file had
/// (`NoteFraming.of`) and every save puts it back (`apply`, `applyToSlice`,
/// `encode`).
library;

import 'package:niman/src/markdown/line_ending.dart';
import 'package:niman/src/markdown/note_encoding.dart';

/// The line ending, the byte order mark and the encoding of a note's file.
final class NoteFraming {
  /// A file with [lineEnding] lines, in [encoding], and a BOM when [bom]
  /// (a UTF-16 or UTF-32 file always has one: it is how they are told).
  const new({
    this.lineEnding = LineEnding.lf,
    this.bom = false,
    this.encoding = NoteEncoding.utf8,
    this.windows1252 = false,
  });

  /// What the file of [bytes] had; [text] is [bytes] decoded, with its line
  /// endings as they were (the ending is counted in it). [encoding] is what
  /// the decode found (`decodeNoteBytes`): the encoding of a note read by a
  /// reader that does not say is told from the bytes' own mark.
  factory of({
    required List<int> bytes,
    required String text,
    NoteEncoding? encoding,
    bool windows1252 = false,
  }) {
    final wide = encoding ?? NoteEncoding.wideOf(bytes) ?? NoteEncoding.utf8;
    return NoteFraming(
      lineEnding: LineEnding.dominantOf(text),
      bom: wide.isWide || hasUtf8Bom(bytes),
      encoding: wide,
      windows1252: windows1252,
    );
  }

  /// A note with nothing to put back: `\n` lines, UTF-8 and no BOM.
  static const NoteFraming plain = NoteFraming();

  /// The ending most of the file's lines had.
  final LineEnding lineEnding;

  /// Whether the file began with a byte order mark. The decoder drops it, so
  /// the text the editor holds does not have it.
  final bool bom;

  /// How the file's text is turned into bytes: UTF-8, or the UTF-16 or
  /// UTF-32 its byte order mark declared (#1332).
  final NoteEncoding encoding;

  /// Whether some bytes of the file were not UTF-8 and were read as
  /// Windows-1252 (#1367): the save writes the note as UTF-8, and the reader
  /// is told so when the note opens.
  final bool windows1252;

  /// Whether [bytes] begin with the UTF-8 byte order mark.
  static bool hasUtf8Bom(List<int> bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF;

  /// [lfText] — the note as the editor holds it — as the file has it, as
  /// text: its line endings and its byte order mark ([encode] makes bytes).
  String apply(String lfText) => applyToSlice(lfText, first: true);

  /// One piece of the note, as the file has it: [first] for the piece the
  /// file begins with, which carries the BOM. A piece is cut at line ends,
  /// so no `\r\n` is ever split between two.
  String applyToSlice(String lfSlice, {required bool first}) {
    final lines = lineEnding.apply(lfSlice);
    return bom && first ? '\u{FEFF}$lines' : lines;
  }

  /// [text] — what [apply] or [applyToSlice] made — as the bytes of the
  /// file, in its encoding.
  List<int> encode(String text) => encoding.encode(text);
}
