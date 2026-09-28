/// The editor's spelling state: which line ranges to underline (T-PP-09).
///
/// Line-oriented and lazy on purpose. The editor asks about a line only when
/// it lays it out, so the cost is O(visible lines), never O(file) — the same
/// budget the incremental highlighter keeps (`editor/highlight_sync.dart`).
/// A line's answer is cached by its text *and* the ranges it was told to
/// skip, and each word's verdict is cached once, so re-scrolling and a
/// repeated word cost nothing.
///
/// The engine is the one cost here that is not a line's: a dictionary is
/// megabytes of text and libhunspell parses it inside `Hunspell_create`, so
/// the load runs off the isolate that owns the frame and lands when it lands
/// (#453). Until it does, [EditorSpellCheck.available] is false and nothing
/// is underlined — no frame waits for it — and the notification it sends is
/// what makes the editor ask its visible lines again.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';
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
  TokenKind.templateCommand,
  TokenKind.codeInline,
  TokenKind.codeFence,
  TokenKind.codeBlock,
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

/// One checked line: the text it was checked for, the ranges the checker was
/// told to skip, and the ranges found.
///
/// The skip is part of the answer rather than a detail of the question: a
/// line asked about with nothing to skip — its tokens not known yet — is a
/// different question from the same line asked about with its code, maths
/// and links skipped, and the first answer must not stand for the second
/// (#373).
final class _CheckedLine {
  const new(this.text, this.skip, this.ranges);

  final String text;
  final List<TextRange> skip;
  final List<TextRange> ranges;

  /// Whether this answer is [line]'s, checked with [skip] — the cache hit.
  bool answers(String line, List<TextRange> skip) =>
      text == line && listEquals(this.skip, skip);
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
    _startEngines();
  }

  final SpellChecker Function(String? dictionary)? _override;
  List<String> _dictionaries;
  PersonalDictionary? _dictionary;

  /// The engines the load answered, and what the editor reads: the personal
  /// dictionary, when one is attached, in front of them (issue #60).
  SpellChecker? _engines;
  SpellChecker? _checker;

  /// How many loads have been started: a load that lands after a newer
  /// choice was made is dropped when it does, handles and all.
  int _loads = 0;

  Future<void> _engineReady = Future<void>.value();
  bool _disposed = false;

  /// Completes when the engines' load has landed, or has failed.
  ///
  /// Nothing on a frame waits for it (#453): until it lands [available] is
  /// false, nothing is underlined, and the notification that follows is what
  /// has the editor ask again. The spelling panel awaits it, because a pass
  /// read before the dictionary was there would call the note clean.
  Future<void> get engineReady => _engineReady;

  /// The active dictionary names, in selection order (empty = the
  /// machine's locale).
  List<String> get dictionaries => List.unmodifiable(_dictionaries);

  /// Changes the dictionaries: the current engines are dropped, their word
  /// verdicts and line ranges forgotten, and the new ones load in the
  /// background.
  void setDictionaries(List<String> dictionaries) {
    final normalized = _normalize(dictionaries);
    if (listEquals(_dictionaries, normalized)) return;
    _dictionaries = normalized;
    _checker?.dispose();
    _lines.clear();
    _words.clear();
    _suggestions.clear();
    _startEngines();
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

  /// Starts the engines' load, off this isolate wherever the load is a
  /// dictionary's (#453).
  ///
  /// The state is built where a library opens, so the load it starts is
  /// spent while the app is still finding its feet rather than on the frame
  /// that first draws a note. The constructor's `createChecker` is the seam:
  /// a fake has no dictionary to parse, so it is built here and is there at
  /// once.
  void _startEngines() {
    final loads = ++_loads;
    _engines = null;
    _checker = null;
    final override = _override;
    if (override != null) {
      _engines = _multi(<SpellChecker>[
        if (_dictionaries.isEmpty)
          override(null)
        else
          for (final name in _dictionaries) override(name),
      ]);
      _checker = _wrapped(_engines!);
      _engineReady = Future<void>.value();
      return;
    }
    _engineReady = _load(loads, _dictionaries);
  }

  Future<void> _load(int loads, List<String> names) async {
    List<SpellChecker> engines;
    try {
      engines = await loadSpellCheckers(names);
    } on Object catch (error) {
      const AppLogger(name: 'spellcheck')
          .warning('the dictionary load failed: $error');
      engines = <SpellChecker>[const NoopSpellChecker()];
    }
    if (loads != _loads) {
      // A newer choice won while this one loaded: its engines are nobody's
      // now, and the handles behind them are released here.
      for (final engine in engines) {
        engine.dispose();
      }
      return;
    }
    _engines = _multi(engines);
    _checker = _wrapped(_engines!);
    if (!_disposed) notifyListeners();
  }

  /// One engine, or several asked in turn: hunspell opens one dictionary per
  /// handle, so a note that mixes languages is checked against one engine per
  /// chosen language.
  static SpellChecker _multi(List<SpellChecker> engines) =>
      engines.length == 1 ? engines.single : MultiSpellChecker(engines);

  /// [base] with the personal dictionary in front of it, when one is
  /// attached (issue #60): its words are always correct.
  SpellChecker _wrapped(SpellChecker base) {
    final dictionary = _dictionary;
    return dictionary == null
        ? base
        : PersonalDictionarySpellChecker(dictionary, base);
  }

  /// Prose words: a letter run, apostrophes and inner hyphens allowed.
  static final RegExp _word = RegExp(r"[\p{L}][\p{L}'’-]*", unicode: true);

  bool _enabled = true;
  final Map<int, _CheckedLine> _lines = <int, _CheckedLine>{};
  final Map<String, bool> _words = <String, bool>{};

  /// Whether underlining is on.
  bool get enabled => _enabled;

  /// Whether an engine and dictionary loaded (false = nothing to underline).
  ///
  /// False while the background load is in flight, which is not a frame's
  /// business: nothing blocks on it, and the notification that follows the
  /// load is what has the editor and the settings ask again.
  bool get available {
    if (!_enabled) return false;
    return _checker?.available ?? false;
  }

  /// The library's personal dictionary (issue #60), or null while none is
  /// attached (before a library opens, or on a closed session).
  PersonalDictionary? get personalDictionary => _dictionary;

  /// Swaps the personal dictionary: the word and line caches are forgotten
  /// — a word's verdict can change either way — and listeners are told so
  /// the editor re-scans.
  ///
  /// The words are Dart's and the engine stands: the wrapper in front of it
  /// is all that changes, so nothing is loaded again (#453).
  void setPersonalDictionary(PersonalDictionary? dictionary) {
    if (identical(_dictionary, dictionary)) return;
    _dictionary?.removeListener(_onDictionaryChanged);
    _dictionary = dictionary;
    dictionary?.addListener(_onDictionaryChanged);
    final engines = _engines;
    _checker = engines == null ? null : _wrapped(engines);
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
    final checker = _checker;
    if (checker == null || !checker.available) return false;
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
  /// [skip] comes from [spellSkipRanges] and is part of the key: a note long
  /// enough to be styled in the background is asked about its lines before
  /// their tokens are read, and the answer of that ask — with nothing to
  /// skip — must not stand once the tokens arrive (#373). Later calls for
  /// the same text *and* the same skip are a compare. Nothing is computed
  /// while [enabled] is false or the engine is unavailable — the latter
  /// includes the background load still being in flight (#453), which is
  /// why an ask is never what waits for a dictionary.
  List<TextRange> rangesFor(
    int index,
    String line, {
    required List<TextRange> skip,
  }) {
    if (!_enabled) return const <TextRange>[];
    final cached = _lines[index];
    if (cached != null && cached.answers(line, skip)) return cached.ranges;
    final checker = _checker;
    if (checker == null || !checker.available) return const <TextRange>[];
    final ranges = _checkLine(checker, line, skip);
    _lines[index] = _CheckedLine(line, skip, ranges);
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
    final checker = _checker;
    if (checker == null || !checker.available) return const <String>[];
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
    // A load in flight is nobody's once this is disposed: the counter it
    // checks when it lands is what releases its handles (#453).
    _loads++;
    _disposed = true;
    _checker?.dispose();
    _checker = null;
    _engines = null;
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
  ///
  /// Waits for the engine's load first (#453): the pass is the one caller
  /// that cannot leave the question to a later frame — read before the
  /// dictionary was there, it would report the note clean. Only a load in
  /// flight is waited on: when the engine is already there — the constructor
  /// seam, or a load that landed first — nothing is awaited and the pass
  /// runs in the turn it was opened on, as it always did.
  Future<void> run() async {
    final spell = _spell;
    if (spell._checker == null) await spell.engineReady;
    final checker = spell._enabled ? spell._checker : null;
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
