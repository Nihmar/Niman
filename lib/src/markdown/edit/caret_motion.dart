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
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

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

  /// The start of the caret's line, past its indentation.
  lineTextStart,

  /// The start of the note.
  documentStart,

  /// The end of the note.
  documentEnd,
}

/// Whether [unit] is part of a word: a letter, a digit, or an underscore.
///
/// The rule editors share, and the one a writer expects: `snake_case_name`
/// moves
/// as one word, `due parole` as two, and punctuation belongs to neither side.
bool _wordChar(String unit) => _wordPattern.hasMatch(unit);

/// Compiled once: a keystroke-rate caller compiling it per character was the
/// most expensive part of a word motion.
final RegExp _wordPattern = RegExp(r'^[\p{L}\p{N}_]$', unicode: true);

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
/// and the platform `TextSelection` cannot use (#376).
(int, int) _expand(String text, int at, {required int fallback}) {
  if (at < 0 || at >= text.length) return (fallback, fallback + 1);
  final (unitStart, unitEnd) = _clusterAt(text, at);
  final unit = text.substring(unitStart, unitEnd);
  if (!_wordChar(unit)) return (unitStart, unitEnd);
  var start = unitStart;
  var end = unitEnd;
  while (start > 0 &&
      _wordChar(String.fromCharCode(text.codeUnitAt(start - 1)))) {
    start--;
  }
  while (end < text.length &&
      _wordChar(String.fromCharCode(text.codeUnitAt(end)))) {
    end++;
  }
  // A run that stopped inside a cluster — the accent after its letter, half a
  // pair — takes that cluster whole rather than cutting it, so both ends of
  // the range stand on a boundary.
  return (_clusterAt(text, start).$1, _clusterAt(text, end - 1).$2);
}

/// The grapheme cluster of [text] that holds code unit [at], as
/// `(start, end)`.
///
/// The string twin of [_lastUnit] and [_firstUnit], with the one difference a
/// click needs: [at] need not stand on a cluster boundary. An offset in the
/// middle of a surrogate pair is answered with the pair, because that is the
/// whole of what it sits on.
(int, int) _clusterAt(String text, int at) {
  final from = at - _window < 0 ? 0 : at - _window;
  final to = at + _window > text.length ? text.length : at + _window;
  var start = from;
  for (final unit in text.substring(from, to).characters) {
    final end = start + unit.length;
    if (at < end) return (start, end);
    start = end;
  }
  // The window always reaches past [at], so the loop has answered by here.
  return (text.length, text.length);
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
/// a motion off either end stops at it.
SelectionModel moveCaret(
  SelectionModel selection,
  CaretMotion motion, {
  required SourceBuffer buffer,
  bool extend = false,
}) {
  final from = selection.extent;
  final to = switch (motion) {
    CaretMotion.characterLeft => _characterLeft(buffer, from),
    CaretMotion.characterRight => _characterRight(buffer, from),
    CaretMotion.wordLeft => _wordLeft(buffer, from),
    CaretMotion.wordRight => _wordRight(buffer, from),
    CaretMotion.lineStart => buffer.offsetOfLine(buffer.lineOf(from)),
    CaretMotion.lineTextStart => _textStart(buffer, from),
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
  return at - _lastUnit(buffer, at).length;
}

/// One grapheme cluster right of [at].
int _characterRight(SourceBuffer buffer, int at) {
  if (at >= buffer.length) return buffer.length;
  return at + _firstUnit(buffer, at).length;
}

/// The start of the word before [at]: back over punctuation and space, then
/// over
/// the word itself.
int _wordLeft(SourceBuffer buffer, int at) {
  var index = at;
  while (index > 0 && !_wordChar(_lastUnit(buffer, index))) {
    index -= _unitLengthBefore(buffer, index);
  }
  while (index > 0 && _wordChar(_lastUnit(buffer, index))) {
    index -= _unitLengthBefore(buffer, index);
  }
  return index;
}

/// The start of the word after [at]: past punctuation and space, then to the
/// end
/// of the word — which is where the *next* press starts from, as editors do.
int _wordRight(SourceBuffer buffer, int at) {
  var index = at;
  while (index < buffer.length && !_wordChar(_firstUnit(buffer, index))) {
    index += _unitLengthAt(buffer, index);
  }
  while (index < buffer.length && _wordChar(_firstUnit(buffer, index))) {
    index += _unitLengthAt(buffer, index);
  }
  return index;
}

/// The end of the line the caret is on, before its terminator.
int _lineEnd(SourceBuffer buffer, int at) {
  final line = buffer.lineOf(at);
  return buffer.offsetOfLine(line) + buffer.lineLengthAt(line);
}

/// The start of the line's text, past its indentation.
int _textStart(SourceBuffer buffer, int at) {
  final line = buffer.lineOf(at);
  final start = buffer.offsetOfLine(line);
  final text = buffer.lineAt(line);
  var index = 0;
  while (index < text.length && (text[index] == ' ' || text[index] == '\t')) {
    index++;
  }
  return start + index;
}

/// How far either side of the caret a grapheme cluster is looked for.
///
/// A cluster is a handful of code units — an emoji with its modifiers, a
/// letter with its accents, a `\r\n` — so a window this wide always holds the
/// whole of the one next to the caret, and of the one [wordRangeAt] expands a
/// click's offset to. What it replaces copied the note from its start to the
/// caret (or from the caret to its end) on every press, and several times per
/// character of a word motion.
const int _window = 64;

/// The grapheme cluster ending at [at].
String _lastUnit(SourceBuffer buffer, int at) {
  final from = at - _window < 0 ? 0 : at - _window;
  return buffer.substring(from, at).characters.last;
}

/// The grapheme cluster starting at [at].
String _firstUnit(SourceBuffer buffer, int at) {
  final to = at + _window > buffer.length ? buffer.length : at + _window;
  return buffer.substring(at, to).characters.first;
}

/// How many code units the grapheme cluster ending at [at] takes.
int _unitLengthBefore(SourceBuffer buffer, int at) =>
    _lastUnit(buffer, at).length;

/// How many code units the grapheme cluster starting at [at] takes.
int _unitLengthAt(SourceBuffer buffer, int at) => _firstUnit(buffer, at).length;
