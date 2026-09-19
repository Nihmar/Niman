/// The editor's spelling state: which line ranges to underline (T-PP-09).
///
/// Line-oriented and lazy on purpose. The editor asks about a line only when
/// it lays it out, so the cost is O(visible lines), never O(file) — the same
/// budget the incremental highlighter keeps (`editor/highlight_sync.dart`).
/// A line's answer is cached by its text, and each word's verdict is cached
/// once, so re-scrolling and a repeated word cost nothing.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/spellcheck/hunspell_spell_checker.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:niman/src/spellcheck/personal_dictionary_spell_checker.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/strings.dart';

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

/// One line handed to [EditorSpellCheck.startScan]: its text and the
/// ranges the checker must ignore.
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
  /// [dictionaries] are the user's chosen dictionary names; an empty list
  /// means the machine's locale. [setDictionaries] changes them later.
  /// [dictionary] is the library's personal words (issue #60); the shell
  /// attaches it when a library opens, via [setPersonalDictionary].
  new({
    List<String> dictionaries = const <String>[],
    SpellChecker Function(String? dictionary)? createChecker,
    PersonalDictionary? dictionary,
  }) : _dictionaries = _normalize(dictionaries),
       _override = createChecker,
       _dictionary = dictionary {
    dictionary?.addListener(_onDictionaryChanged);
  }

  final SpellChecker Function(String? dictionary)? _override;
  List<String> _dictionaries;
  PersonalDictionary? _dictionary;

  /// The active dictionary names, in selection order (empty = the
  /// machine's locale).
  List<String> get dictionaries => List.unmodifiable(_dictionaries);

  /// Changes the dictionaries: the current engines are dropped, their word
  /// verdicts and line ranges forgotten, and new ones build on the next
  /// request.
  void setDictionaries(List<String> dictionaries) {
    final normalized = _normalize(dictionaries);
    if (listEquals(_dictionaries, normalized)) return;
    _dictionaries = normalized;
    _checker?.dispose();
    _checker = null;
    _lines.clear();
    _words.clear();
    _suggestions.clear();
    notifyListeners();
  }

  /// Drops empty names and duplicates while keeping the selection order.
  static List<String> _normalize(List<String> dictionaries) {
    final names = <String>[];
    for (final dictionary in dictionaries) {
      final name = dictionary.trim();
      if (name.isEmpty || names.contains(name)) continue;
      names.add(name);
    }
    return names;
  }

  /// One engine per selected dictionary; the locale's when none is chosen.
  ///
  /// The personal dictionary, when attached, is checked before any engine
  /// (issue #60): its words are always correct.
  SpellChecker _newChecker() {
    final override = _override;
    final checkers = _dictionaries.isEmpty
        ? <SpellChecker>[override?.call(null) ?? createSpellChecker()]
        : <SpellChecker>[
            for (final name in _dictionaries)
              override?.call(name) ?? createSpellChecker(dictionary: name),
          ];
    final base = checkers.length == 1
        ? checkers.single
        : MultiSpellChecker(checkers);
    final dictionary = _dictionary;
    return dictionary == null
        ? base
        : PersonalDictionarySpellChecker(dictionary, base);
  }

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

  /// The library's personal dictionary (issue #60), or null while none is
  /// attached (before a library opens, or on a closed session).
  PersonalDictionary? get personalDictionary => _dictionary;

  /// Swaps the personal dictionary: the word and line caches are forgotten
  /// — a word's verdict can change either way — and listeners are told so
  /// the editor re-scans.
  void setPersonalDictionary(PersonalDictionary? dictionary) {
    if (identical(_dictionary, dictionary)) return;
    _dictionary?.removeListener(_onDictionaryChanged);
    _dictionary = dictionary;
    dictionary?.addListener(_onDictionaryChanged);
    _checker?.dispose();
    _checker = null;
    _lines.clear();
    _words.clear();
    notifyListeners();
  }

  /// A word was added to the personal dictionary: forget the verdicts it
  /// may have cached (the line ranges too — they hold the old underline)
  /// and tell the editor to re-scan.
  void _onDictionaryChanged() {
    _lines.clear();
    _words.clear();
    _suggestions.clear();
    notifyListeners();
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

  /// Whether the checker flags [word] as a misspelling — the underline's
  /// verdict, with the underline's gates: the checker on, an engine
  /// loaded, and a checkable word. The context menu's "Add to dictionary"
  /// entry offers itself only when this is true and a dictionary is
  /// attached.
  bool isMisspelled(String word) {
    if (!_enabled) return false;
    final checker = _checker ??= _newChecker();
    if (!checker.available) return false;
    if (!_checkable(word)) return false;
    return !(_words[word] ??= checker.isCorrect(word));
  }

  /// Adds [word] to the library's personal dictionary (issue #60); the
  /// word's verdict and the underlines follow the disk write.
  ///
  /// Completes immediately when no dictionary is attached (Android, or
  /// before a library opens).
  Future<void> addToDictionary(String word) async {
    final dictionary = _dictionary;
    if (dictionary == null) return;
    await dictionary.add(word);
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

  /// Starts the panel's whole-note pass over [lineCount] lines, read one
  /// at a time through [lineAt] as the pass reaches them (#61).
  ///
  /// The pass runs on this isolate — hunspell's handle cannot leave it —
  /// but a slice at a time, handing the frame back between slices, so the
  /// panel opens at once and fills as it goes. It shares the underline's
  /// word-verdict cache. Its issues carry no suggestions: those are
  /// hunspell's slow call, and [suggestionsFor] makes them one word at a
  /// time, for the words the panel shows.
  SpellScan startScan({
    required int lineCount,
    required SpellLine Function(int index) lineAt,
  }) => SpellScan._(this, lineCount, lineAt);

  /// Hunspell's suggestions for [word], best first; cached per word.
  List<String> suggestionsFor(String word) {
    if (!_enabled) return const <String>[];
    final checker = _checker ??= _newChecker();
    if (!checker.available) return const <String>[];
    return _suggestions[word] ??= checker.suggest(word);
  }

  final Map<String, List<String>> _suggestions = <String, List<String>>{};

  /// Whether [word] is flagged, through the verdict cache; the pass's
  /// single step.
  bool _misspelled(SpellChecker checker, String word) =>
      _checkable(word) && !(_words[word] ??= checker.isCorrect(word));

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

/// The word containing [position] in [text] — the word under a collapsed
/// caret — or null when the position sits in whitespace or outside the
/// text. A caret at a word's edge still names that word: that is where the
/// writer leaves it after clicking on the word.
String? spellWordAt(String text, int position) {
  if (position < 0 || position > text.length) return null;
  for (final match in EditorSpellCheck._word.allMatches(text)) {
    if (match.start > position) break;
    if (position <= match.end) return match.group(0);
  }
  return null;
}

/// The word a selection names for the menu (issue #60): the caret's word
/// when collapsed, else the word the selection sits in — a partial-word
/// selection names the whole word, a multi-word selection nothing (there
/// is no single word to add).
String? spellWordForSelection(String text, int start, int end) {
  if (start < 0 || end < start || end > text.length) return null;
  if (start == end) return spellWordAt(text, start);
  for (final match in EditorSpellCheck._word.allMatches(text)) {
    if (match.start > end) break;
    if (match.start <= start && end <= match.end) return match.group(0);
  }
  return null;
}

/// The context-menu entry that adds the word under the caret/selection to
/// the library's personal dictionary (issue #60).
///
/// Null when the menu has nothing to offer: no dictionary attached, the
/// checker off or unavailable, the position in whitespace, or the word
/// already correct. [start]/[end] select in [text]; [onDismiss] closes the
/// caller's menu once the word is added.
ContextMenuButtonItem? addToDictionaryItem({
  required EditorSpellCheck spell,
  required String text,
  required int start,
  required int end,
  required VoidCallback onDismiss,
}) {
  if (spell.personalDictionary == null) return null;
  final word = spellWordForSelection(text, start, end);
  if (word == null || !spell.isMisspelled(word)) return null;
  return ContextMenuButtonItem(
    label: AppStrings.addWordToDictionary,
    onPressed: () {
      unawaited(spell.addToDictionary(word));
      onDismiss();
    },
  );
}

/// One run of the panel's whole-note pass (#61): the issues found so far,
/// how far it got, and whether it stopped at [EditorSpellCheck.maxIssues].
final class SpellScan extends ChangeNotifier {
  new _(this._spell, this.lineCount, this._lineAt);

  final EditorSpellCheck _spell;
  final SpellLine Function(int index) _lineAt;

  /// How long one slice may keep the frame before handing it back.
  static const Duration slice = Duration(milliseconds: 8);

  /// The lines the pass covers.
  final int lineCount;

  final List<SpellIssue> _issues = <SpellIssue>[];
  int _linesDone = 0;
  bool _done = false;
  bool _capped = false;
  bool _cancelled = false;

  /// The misspellings found so far, in reading order, without
  /// suggestions (see [EditorSpellCheck.suggestionsFor]).
  List<SpellIssue> get issues => List.unmodifiable(_issues);

  /// The lines checked so far.
  int get linesDone => _linesDone;

  /// Whether the pass is over: every line checked, or the list full.
  bool get done => _done;

  /// Whether the pass stopped at [EditorSpellCheck.maxIssues] with lines
  /// left: the panel says it shows the first ones only.
  bool get capped => _capped;

  /// Runs the pass to its end, a slice at a time.
  Future<void> run() async {
    final spell = _spell;
    final checker = spell._enabled
        ? (spell._checker ??= spell._newChecker())
        : null;
    if (checker == null || !checker.available) {
      _finish();
      return;
    }
    final clock = Stopwatch()..start();
    while (_linesDone < lineCount && !_cancelled) {
      final index = _linesDone;
      final line = _lineAt(index);
      for (final match in EditorSpellCheck._word.allMatches(line.text)) {
        if (EditorSpellCheck._covered(match.start, match.end, line.skip)) {
          continue;
        }
        final word = match.group(0)!;
        if (!spell._misspelled(checker, word)) continue;
        _issues.add(
          SpellIssue(
            line: index,
            start: match.start,
            end: match.end,
            word: word,
            lineText: line.text,
            suggestions: const <String>[],
          ),
        );
        if (_issues.length >= EditorSpellCheck.maxIssues) break;
      }
      _linesDone++;
      if (_issues.length >= EditorSpellCheck.maxIssues) {
        _capped = _linesDone < lineCount;
        break;
      }
      if (clock.elapsed >= slice) {
        notifyListeners();
        // Hands the frame back: what was found shows, input goes through.
        await Future<void>.delayed(Duration.zero);
        clock.reset();
      }
    }
    _finish();
  }

  void _finish() {
    if (_cancelled) return;
    _done = true;
    notifyListeners();
  }

  /// Stops the pass (the panel closed).
  void cancel() => _cancelled = true;
}
