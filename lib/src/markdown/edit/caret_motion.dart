// Where the caret goes when a key is pressed (#245, phase 3).
//
// The *logical* motions, which are pure functions of the note and the caret and
// are therefore testable without a device, a widget or a keyboard: one
// character
// at a time over grapheme clusters (not code units — an emoji is one press, not
// two), one word at a time over the word rule editors share, and the line and
// note ends. The *visual* motions — up and down over wrapped rows — need the
// layout that drew the line, so they live in the surface, which has the
// `RenderParagraph` to ask.
//
// Every motion takes `extend`, because shift plus an arrow is the same
// arithmetic
// with the anchor held: the caret is one model, not two.
// `characters` comes with Flutter (`package:flutter/widgets.dart` re-exports
// it), so a grapheme cluster is available without a dependency of our own.
import 'package:niman/src/markdown/edit/grapheme_steps.dart';
import 'package:niman/src/markdown/edit/line_prefix.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

export 'package:niman/src/markdown/edit/grapheme_steps.dart' show isWordChar;

/// One press of a movement key.
enum CaretMotion {
  /// One grapheme cluster to the left.
  characterLeft,

  /// One grapheme cluster to the right.
  characterRight,

  /// The start of the word before the caret.
  wordLeft,

  /// The start of the word after the caret.
  wordRight,

  /// The start of the caret's line.
  lineStart,

  /// The end of the caret's line.
  lineEnd,

  /// The start of the caret's line's text, past its indentation and any
  /// marker — a list item's, its task box, a quote's, a heading's — or,
  /// from there, the start of the line (#545).
  lineTextStart,

  /// The start of the note.
  documentStart,

  /// The end of the note.
  documentEnd,
}

/// The range of the word [offset] is in, as `(start, end)`.
///
/// What a double click selects, and the same word rule the word motions use: a
/// letter, a digit or an underscore is a word character, so `snake_case_name`
/// selects whole. An offset that sits on no word character — a space, a comma —
/// selects that one character, which is what editors do rather than selecting
/// the nothing between two words.
///
/// A *character* here is a grapheme cluster, not a code unit — the same rule
/// the character motions use — so a range never holds half of an emoji, and
/// what a copy carries survives a round trip (#376).
(int, int) wordRangeAt(String text, int offset) {
  final at = offset.clamp(0, text.length);
  if (at >= text.length && at > 0) {
    // Past the last character: the word ends here, so expand from the end.
    return _expand(text, at - 1, fallback: at - 1);
  }
  return _expand(text, at, fallback: at);
}

/// Expands around [at] over the word characters that touch it.
///
/// The unit the offset sits on, and the two ends of the answer, are grapheme
/// clusters rather than code units. The offset need not be on a boundary: a
/// click or a long press in the middle of a surrogate pair sits on half an
/// emoji, and answering with that half is a range the selection, the clipboard
/// and the platform `TextSelection` cannot use (#376). A cluster is a word
/// character by its first code point, so a letter with an accent after it, a
/// Thai syllable or a letter outside the BMP is part of its word (#1346).
(int, int) _expand(String text, int at, {required int fallback}) {
  if (at < 0 || at >= text.length) return (fallback, fallback + 1);
  final steps = GraphemeSteps.ofString(text);
  // The cluster holding code unit [at]: from the boundary before the unit
  // after it, to the boundary that follows.
  final unitStart = steps.previous(at + 1);
  final unitEnd = steps.next(unitStart);
  if (!isWordChar(text.substring(unitStart, unitEnd))) {
    return (unitStart, unitEnd);
  }
  return (
    steps.runBackward(unitStart, word: true),
    steps.runForward(unitEnd, word: true),
  );
}

/// The run of non-whitespace the caret [offset] is in, as `(start, end)`.
///
/// This is what `live` mode's per-word reveal calls the caret's *word*, and it
/// is deliberately **not** [wordRangeAt]: that one answers what a double click
/// selects, so it stops at a marker — `**bold**` would give you `bold`, and
/// the `**` the writer is editing would stay hidden. A run is everything the
/// caret can reach without crossing a space, so it *contains* the syntax that
/// delimits the word, which is exactly what has to be drawn while the caret is
/// in it (`docs/records/unified-surface.md` §8.6.2, the per-word refinement).
///
/// An offset that sits on whitespace is that one character: there is no run to
/// be in, and the caller wants a range either way.
(int, int) runAround(String text, int offset) {
  if (text.isEmpty) return (0, 0);
  final at = offset.clamp(0, text.length);
  // A caret at or past the end belongs to the last character's run, the way a
  // caret typed at the end of a line is in the word it just finished.
  return _runAt(text, at >= text.length ? text.length - 1 : at);
}

/// The run [at] is in, or [at] alone when it is whitespace.
(int, int) _runAt(String text, int at) {
  if (_isBlank(text.codeUnitAt(at))) return (at, at + 1);
  var start = at;
  var end = at + 1;
  while (start > 0 && !_isBlank(text.codeUnitAt(start - 1))) {
    start--;
  }
  while (end < text.length && !_isBlank(text.codeUnitAt(end))) {
    end++;
  }
  return (start, end);
}

/// Whether [char] is whitespace a run breaks at.
///
/// The space and the tab are the ones a note is written with; the rest are the
/// line's own terminator and the non-breaking space a paste can bring in, kept
/// for the same reason `\r\n` is one line break rather than a character in the
/// middle of a word.
bool _isBlank(int char) =>
    char == 0x20 || // space
    char == 0x09 || // tab
    char == 0x0A || // line feed
    char == 0x0D || // carriage return
    char == 0x0B || // vertical tab
    char == 0x0C || // form feed
    char == 0xA0; // no-break space

/// The caret [selection] moved by [motion] through [buffer].
///
/// With [extend] the anchor stays where it was, which is what shift does;
/// without
/// it the new position becomes both ends. The result is always inside the note:
/// a motion off either end stops at it. [verbatimQuotes] says which lines are a
/// verbatim block's, where a `#` or a `-` is text ([verbatimQuotesOf]).
SelectionModel moveCaret(
  SelectionModel selection,
  CaretMotion motion, {
  required SourceBuffer buffer,
  bool extend = false,
  int? Function(int line)? verbatimQuotes,
}) {
  final from = selection.extent;
  int body(int line) =>
      lineBodyStart(buffer, line, verbatim: verbatimQuotes?.call(line));
  final to = switch (motion) {
    CaretMotion.characterLeft => _characterLeft(buffer, from),
    CaretMotion.characterRight => _characterRight(buffer, from),
    CaretMotion.wordLeft => _wordLeft(buffer, from, body),
    CaretMotion.wordRight => _wordRight(buffer, from, body),
    CaretMotion.lineStart => buffer.offsetOfLine(buffer.lineOf(from)),
    CaretMotion.lineTextStart => _textStart(buffer, from, body),
    CaretMotion.lineEnd => _lineEnd(buffer, from),
    CaretMotion.documentStart => 0,
    CaretMotion.documentEnd => buffer.length,
  };
  return extend
      ? SelectionModel(anchor: selection.anchor, extent: to)
      : SelectionModel.at(to);
}

/// One grapheme cluster left of [at].
int _characterLeft(SourceBuffer buffer, int at) {
  if (at <= 0) return 0;
  return GraphemeSteps.ofBuffer(buffer).previous(at);
}

/// One grapheme cluster right of [at].
int _characterRight(SourceBuffer buffer, int at) {
  if (at >= buffer.length) return buffer.length;
  return GraphemeSteps.ofBuffer(buffer).next(at);
}

/// The start of the word before [at], or the end of the line above when [at]
/// stands at the head of its own.
///
/// At the head of a line — only the syntax before its text, which
/// [lineBodyStart] measures, before the caret — `Ctrl+←` is the line's motion,
/// not the note's: it goes to the end of the line above, the way it does at the
/// head of any line. Skipping a marker, the spaces and the previous line's
/// closing punctuation to land *inside* its last word is what a writer does not
/// expect (#528).
///
/// Mid-line it is the word motion, unchanged: back over punctuation and
/// space, then over the word itself.
int _wordLeft(SourceBuffer buffer, int at, int Function(int line) body) {
  final line = buffer.lineOf(at);
  if (line > 0 && at <= body(line)) {
    final above = line - 1;
    return buffer.offsetOfLine(above) + buffer.lineLengthAt(above);
  }
  final steps = GraphemeSteps.ofBuffer(buffer);
  return steps.runBackward(steps.runBackward(at, word: false), word: true);
}

/// The start of the word after [at], or the head of the line below when [at]
/// stands at the end of its own.
///
/// The twin of [_wordLeft]: at the end of a line's text — the terminator after
/// the caret — `Ctrl+→` is the line's motion, not the note's: it goes to the
/// head of the line below, past its indentation and any marker, rather than
/// crossing the break to stop at the end of the next line's first word (#528).
///
/// Mid-line it is the word motion, unchanged: past punctuation and space, then
/// to the end of the word — which is where the *next* press starts from, as
/// editors do.
int _wordRight(SourceBuffer buffer, int at, int Function(int line) body) {
  final line = buffer.lineOf(at);
  if (line + 1 < buffer.lineCount && at >= _lineEnd(buffer, at)) {
    return body(line + 1);
  }
  final steps = GraphemeSteps.ofBuffer(buffer);
  return steps.runForward(steps.runForward(at, word: false), word: true);
}

/// The end of the line the caret is on, before its terminator.
int _lineEnd(SourceBuffer buffer, int at) {
  final line = buffer.lineOf(at);
  return buffer.offsetOfLine(line) + buffer.lineLengthAt(line);
}

/// Where Home goes: the start of the line's text, past its indentation and
/// any marker ([lineBodyStart]) — an item's content, not its bullet — or,
/// when the caret is there already, the start of the line, so that both
/// are a key away (#545).
///
/// A caret that stands *before* the text — in the indentation, among a
/// heading's hashes, between a bullet and its space — goes to the start of
/// the line at once: Home never moves the caret right, save from the start
/// of the line itself, where it toggles back to the text.
int _textStart(SourceBuffer buffer, int at, int Function(int line) body) {
  final line = buffer.lineOf(at);
  final head = buffer.offsetOfLine(line);
  final start = body(line);
  return at > head && at <= start ? head : start;
}
