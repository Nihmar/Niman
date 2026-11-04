import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/render/dead_link_ranges.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';

/// What the source view marks on a line beyond its colours, as offsets
/// local to the line: the selection and the IME's composing range, the
/// words the spelling flags, the links that name nothing, and the find
/// bar's matches.
///
/// Read as each line is built, off the view's own state through the narrow
/// callbacks it is handed.
final class SourceLineMarks {
  /// The marks on the lines of [_buffer]'s note.
  new({
    required this._buffer,
    required this._selection,
    required this._composing,
    required this._spellCheck,
    required this._tokensAt,
    required this._deadLinks,
    required this._linkHrefAt,
    required this._findMatches,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// The range the IME is composing, in note offsets, or empty.
  final TextRange Function() _composing;

  /// The spelling checker, or null.
  final EditorSpellCheck? Function() _spellCheck;

  /// A line's tokens, or null while they are not known.
  final List<Token>? Function(int index) _tokensAt;

  /// The note's dead links, or null.
  final ValueListenable<DeadLinks>? Function() _deadLinks;

  /// The target a reference link at a token start of a line resolved to.
  final String? Function(int index, int start) _linkHrefAt;

  /// The find bar's matches, or null.
  final SourceMatches? Function() _findMatches;

  /// The part of the selection that falls inside line [index], as offsets
  /// local to that line, or null when none of it does.
  ///
  /// The selection is painted as a *background on the runs it covers* rather
  /// than
  /// as rectangles over them: the runs already know how to wrap, and a
  /// rectangle
  /// would have to be recomputed from the layout on every frame that moved
  /// anything.
  (int, int)? selectionIn(int index) {
    final selection = _selection();
    if (selection.isCollapsed) return null;
    return _rangeIn(index, selection.start, selection.end);
  }

  /// The part of the IME's composing range inside line [index], underlined
  /// the way every text field shows the word being composed.
  (int, int)? composingIn(int index) {
    final composing = _composing();
    if (!composing.isValid || composing.isCollapsed) return null;
    return _rangeIn(index, composing.start, composing.end);
  }

  /// The words the checker flags on line [index], as offsets local to it.
  List<TextRange> misspelledIn(int index) {
    if (_spellCheck() == null) return const <TextRange>[];
    return spellRanges(index, _buffer().lineAt(index));
  }

  /// The misspelled ranges of line [index], whose text is [text]: the ranges
  /// the checker finds outside what the tokenizer says is not prose (code,
  /// maths, links, markers).
  ///
  /// A line whose tokens are not known yet is not judged at all, and nothing
  /// is cached for it: judged, its skip set would be empty and the whole line
  /// — code, links and maths included — would come back underlined, and on a
  /// long note that first judgement is what the styler's reading lands on
  /// (#373). It is judged on the frame the tokens arrive.
  List<TextRange> spellRanges(int index, String text) {
    final spell = _spellCheck();
    if (spell == null) return const <TextRange>[];
    final tokens = _tokensAt(index);
    if (tokens == null) return const <TextRange>[];
    return spell.rangesFor(index, text, skip: spellSkipRanges(tokens));
  }

  /// The links of line [index] that name nothing, local to the line.
  List<TextRange> deadLinksIn(int index, StyledLine styled) {
    final dead = _deadLinks()?.value;
    if (dead == null || dead.isEmpty) return const <TextRange>[];
    return deadLinkRanges(
      styled,
      dead,
      hrefOf: (start) => _linkHrefAt(index, start),
    );
  }

  /// The find bar's matches on line [index], as offsets local to it.
  List<(int, int, bool)> foundIn(int index) {
    final matches = _findMatches();
    if (matches == null) return const <(int, int, bool)>[];
    final buffer = _buffer();
    final start = buffer.offsetOfLine(index);
    return matches.within(start, start + buffer.lineLengthAt(index)).toList();
  }

  /// `[from, to)` of the note, as offsets local to line [index], or null.
  (int, int)? _rangeIn(int index, int from, int to) {
    final buffer = _buffer();
    final start = buffer.offsetOfLine(index);
    final end = start + buffer.lineLengthAt(index);
    final a = from < start ? start : from;
    final b = to > end ? end : to;
    if (a >= b) return null;
    return (a - start, b - start);
  }
}
