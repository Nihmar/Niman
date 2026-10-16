/// What a note's file wraps its text in, which a save writes back (#1056).
///
/// The editor holds every note as plain text with `\n` endings and no byte
/// order mark, which keeps the buffer and everything that reads it simple.
/// The file may have had more: CRLF lines, a UTF-8 BOM. Opening such a note
/// and changing one character used to rewrite the whole file — every line
/// ending, the BOM gone — so version control showed every line changed and
/// the sync's line-based merge saw every line differ from the other device's
/// copy. The loader notes what the file had (`NoteFraming.of`) and every save
/// puts it back (`apply`, `applyToSlice`).
library;

import 'package:niman/src/markdown/line_ending.dart';

/// The line ending and the byte order mark of a note's file.
final class NoteFraming {
  /// A file with [lineEnding] lines, and a BOM when [bom].
  const new({this.lineEnding = LineEnding.lf, this.bom = false});

  /// What the file of [bytes] had; [text] is [bytes] decoded, with its line
  /// endings as they were (the ending is counted in it).
  factory of({required List<int> bytes, required String text}) => NoteFraming(
    lineEnding: LineEnding.dominantOf(text),
    bom: hasUtf8Bom(bytes),
  );

  /// A note with nothing to put back: `\n` lines and no BOM.
  static const NoteFraming plain = NoteFraming();

  /// The ending most of the file's lines had.
  final LineEnding lineEnding;

  /// Whether the file began with the UTF-8 byte order mark. The decoder drops
  /// it, so the text the editor holds does not have it.
  final bool bom;

  /// Whether [bytes] begin with the UTF-8 byte order mark.
  static bool hasUtf8Bom(List<int> bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF;

  /// [lfText] — the note as the editor holds it — as the file has it.
  String apply(String lfText) => applyToSlice(lfText, first: true);

  /// One piece of the note, as the file has it: [first] for the piece the
  /// file begins with, which carries the BOM. A piece is cut at line ends,
  /// so no `\r\n` is ever split between two.
  String applyToSlice(String lfSlice, {required bool first}) {
    final lines = lineEnding.apply(lfSlice);
    return bom && first ? '\u{FEFF}$lines' : lines;
  }
}
