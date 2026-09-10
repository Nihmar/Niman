/// The editor's spelling state: which line ranges to underline (T-PP-09).
///
/// Line-oriented and lazy on purpose. The editor asks about a line only when
/// it lays it out, so the cost is O(visible lines), never O(file) — the same
/// budget the incremental highlighter keeps (`editor/highlight_sync.dart`).
/// A line's answer is cached by its text, and each word's verdict is cached
/// once, so re-scrolling and a repeated word cost nothing.
library;

import 'dart:ui' show TextRange;

import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/spellcheck/hunspell_spell_checker.dart';
import 'package:copist/src/spellcheck/spell_checker.dart';
import 'package:copist/src/spellcheck/spell_issue.dart';
import 'package:flutter/foundation.dart';

/// Ranges in [tokens] the checker must not look at.
///
/// Code, math, links, frontmatter, tags and Markdown markers are not prose;
/// flagging identifiers or URLs as misspelled is noise, not a typo.
List<TextRange> spellSkipRanges(List<Token> tokens) => <TextRange>[
  for (final token in tokens)
    if (_skipKinds.contains(token.kind))
      TextRange(start: token.start, end: token.end),
];

const Set<TokenKind> _skipKinds = <TokenKind>{
  TokenKind.codeInline,
  TokenKind.codeFence,
  TokenKind.codeLanguage,
  TokenKind.mathInline,
  TokenKind.mathBlock,
  TokenKind.link,
  TokenKind.image,
  TokenKind.wikilink,
  TokenKind.frontmatter,
  TokenKind.horizontalRule,
  TokenKind.headingMarker,
  TokenKind.listMarker,
  TokenKind.taskBox,
  TokenKind.tag,
};

/// One line handed to [EditorSpellCheck.scan]: its text and the ranges the
/// checker must ignore.
typedef SpellLine = ({String text, List<TextRange> skip});

/// One checked line: the text it was checked for and the ranges found.
final class _CheckedLine {
  const new(this.text, this.ranges);

  final String text;
  final List<TextRange> ranges;
}

/// The document-level spelling state the editor's span builder consults.
final class EditorSpellCheck extends ChangeNotifier {
  /// Creates the state over [createChecker] (the system engine by default).
  ///
  /// [_dictionary] is the user's chosen dictionary name (null = the
  /// machine's locale); [setDictionary] changes it later.
  new({this._dictionary, SpellChecker Function()? createChecker})
    : _override = createChecker;

  final SpellChecker Function()? _override;
  String? _dictionary;

  /// The active dictionary name (null = the machine's locale).
  String? get dictionary => _dictionary;

  /// Changes the dictionary: the current engine is dropped, its word
  /// verdicts and line ranges forgotten, and a new one builds on the next
  /// request.
  void setDictionary(String? dictionary) {
    if (_dictionary == dictionary) return;
    _dictionary = dictionary;
    _checker?.dispose();
    _checker = null;
    _lines.clear();
    _words.clear();
    notifyListeners();
  }

  SpellChecker _newChecker() =>
      _override?.call() ?? createSpellChecker(dictionary: _dictionary);

  /// Prose words: a letter run, apostrophes and inner hyphens allowed.
  static final RegExp _word = RegExp(r"[\p{L}][\p{L}'’-]*", unicode: true);

  SpellChecker? _checker;
  bool _enabled = true;
  final Map<int, _CheckedLine> _lines = <int, _CheckedLine>{};
  final Map<String, bool> _words = <String, bool>{};

  /// Whether underlining is on.
  bool get enabled => _enabled;

  /// Whether an engine and dictionary loaded (false = nothing to underline).
  bool get available {
    if (!_enabled) return false;
    return (_checker ??= _newChecker()).available;
  }

  /// Turns underlining on/off (a settings toggle).
  void setEnabled({required bool enabled}) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (!enabled) _lines.clear();
    notifyListeners();
  }

  /// Forgets every line (a note was loaded into the same editor).
  void reset() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }

  /// The misspelled ranges of [line], within [line]'s own coordinates.
  ///
  /// [skip] comes from [spellSkipRanges]. The first call for a text checks it
  /// and caches; later calls are a string compare. Nothing is computed while
  /// [enabled] is false or the engine is unavailable.
  List<TextRange> rangesFor(
    int index,
    String line, {
    required List<TextRange> skip,
  }) {
    if (!_enabled) return const <TextRange>[];
    final cached = _lines[index];
    if (cached != null && cached.text == line) return cached.ranges;
    final checker = _checker ??= _newChecker();
    if (!checker.available) return const <TextRange>[];
    final ranges = _checkLine(checker, line, skip);
    _lines[index] = _CheckedLine(line, ranges);
    return ranges;
  }

  /// Every misspelling in [lines], in reading order, with suggestions.
  ///
  /// The panel's whole-note pass, unlike the per-visible-line [rangesFor];
  /// capped so a mostly-code note cannot build an unbounded list, and
  /// sharing the same word-verdict cache.
  List<SpellIssue> scan(List<SpellLine> lines) {
    if (!_enabled) return const <SpellIssue>[];
    final checker = _checker ??= _newChecker();
    if (!checker.available) return const <SpellIssue>[];
    final issues = <SpellIssue>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final match in _word.allMatches(line.text)) {
        final start = match.start;
        final end = match.end;
        if (_covered(start, end, line.skip)) continue;
        final word = match.group(0)!;
        if (!_checkable(word)) continue;
        final correct = _words[word] ??= checker.isCorrect(word);
        if (correct) continue;
        issues.add(
          SpellIssue(
            line: i,
            start: start,
            end: end,
            word: word,
            lineText: line.text,
            suggestions: checker.suggest(word),
          ),
        );
        if (issues.length >= maxIssues) return issues;
      }
    }
    return issues;
  }

  /// The most issues the panel lists.
  static const int maxIssues = 200;

  List<TextRange> _checkLine(
    SpellChecker checker,
    String line,
    List<TextRange> skip,
  ) {
    final ranges = <TextRange>[];
    for (final match in _word.allMatches(line)) {
      final start = match.start;
      final end = match.end;
      if (_covered(start, end, skip)) continue;
      final word = match.group(0)!;
      if (!_checkable(word)) continue;
      final correct = _words[word] ??= checker.isCorrect(word);
      if (!correct) ranges.add(TextRange(start: start, end: end));
    }
    return ranges;
  }

  /// Whether [start]..[end] touches any skip range.
  static bool _covered(int start, int end, List<TextRange> skip) {
    for (final range in skip) {
      if (range.start < end && start < range.end) return true;
    }
    return false;
  }

  /// Camel-case and one-letter runs are almost always identifiers, not words;
  /// hunspell would flag both. The word cache is keyed on the original text,
  /// so this stays a cheap gate.
  static bool _checkable(String word) {
    if (word.length < 2) return false;
    for (var i = 1; i < word.length; i++) {
      final unit = word.codeUnitAt(i);
      if (unit >= 0x41 && unit <= 0x5A) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _checker?.dispose();
    _checker = null;
    super.dispose();
  }
}
