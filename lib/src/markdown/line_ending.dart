/// The line ending a note is written with (#1056).
///
/// The editor holds every note with `\n` (`normalizedLineEndings`), which
/// keeps the buffer and everything that reads it simple. A note that came
/// with another ending is written back with it: opening a CRLF note and
/// changing one character used to rewrite every line as LF, so version
/// control showed the whole file changed and the sync's line-based merge saw
/// every line differ from the other device's copy.
library;

/// How a note's lines end on disk.
enum LineEnding {
  /// `\n`, Unix: the editor's own, and what a note with no `\r` has.
  lf('\n'),

  /// `\r\n`, Windows.
  crlf('\r\n'),

  /// A lone `\r`, the classic Mac OS: a note that was written so is read as
  /// lines (`normalizedLineEndings`) and written back so.
  cr('\r');

  new(this.sequence);

  /// The characters that end a line.
  final String sequence;

  /// The ending most of the lines of [text] — as read from disk, before it
  /// was normalized — end with; `\n` when the note has no `\r` or when the
  /// kinds are equally many (a note with no preference keeps the editor's).
  ///
  /// A note mixing the three is written with the dominant one: every line
  /// ends alike after a save, which is the one change a save makes to such a
  /// file. O(the number of `\r` in the text) searches, native ones: a note
  /// with none costs one scan, and a CRLF note of 2.7 M lines about as many
  /// searches.
  static LineEnding dominantOf(String text) {
    var at = text.indexOf('\r');
    if (at < 0) return lf;
    var withLf = 0;
    var alone = 0;
    while (at >= 0) {
      if (at + 1 < text.length && text.codeUnitAt(at + 1) == 0x0A) {
        withLf++;
        at = text.indexOf('\r', at + 2);
      } else {
        alone++;
        at = text.indexOf('\r', at + 1);
      }
    }
    var newlines = 0;
    for (var i = text.indexOf('\n'); i >= 0; i = text.indexOf('\n', i + 1)) {
      newlines++;
    }
    final bare = newlines - withLf;
    if (withLf > bare && withLf >= alone) return crlf;
    if (alone > bare && alone > withLf) return cr;
    return lf;
  }

  /// [lfText] — a text whose lines end with `\n`, as the editor holds a note
  /// — with this ending instead. The same string when this is [lf].
  String apply(String lfText) =>
      this == lf ? lfText : lfText.replaceAll('\n', sequence);
}
