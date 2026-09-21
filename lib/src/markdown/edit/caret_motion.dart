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
bool _wordChar(String unit) =>
    RegExp(r'^[\p{L}\p{N}_]$', unicode: true).hasMatch(unit);

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
  final before = buffer.substring(0, at);
  return at - before.characters.last.length;
}

/// One grapheme cluster right of [at].
int _characterRight(SourceBuffer buffer, int at) {
  if (at >= buffer.length) return buffer.length;
  final after = buffer.substring(at, buffer.length);
  return at + after.characters.first.length;
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
  return buffer.offsetOfLine(line) + buffer.lineAt(line).length;
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

/// The grapheme cluster ending at [at].
String _lastUnit(SourceBuffer buffer, int at) =>
    buffer.substring(0, at).characters.last;

/// The grapheme cluster starting at [at].
String _firstUnit(SourceBuffer buffer, int at) =>
    buffer.substring(at, buffer.length).characters.first;

/// How many code units the grapheme cluster ending at [at] takes.
int _unitLengthBefore(SourceBuffer buffer, int at) =>
    _lastUnit(buffer, at).length;

/// How many code units the grapheme cluster starting at [at] takes.
int _unitLengthAt(SourceBuffer buffer, int at) => _firstUnit(buffer, at).length;
