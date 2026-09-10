/// Word-level spelling behind the editor's underline (T-PP-09, revised).
///
/// The engine is hunspell through FFI — the system library plus a dictionary
/// found on disk — so the machine's own dictionaries and locale are used.
/// Where neither exists (Android, a Windows box without hunspell)
/// `createSpellChecker` returns a [NoopSpellChecker], so every caller keeps
/// one code path and simply underlines nothing.
library;

/// A word-level spell checker.
abstract interface class SpellChecker {
  /// Whether the engine and its dictionary loaded.
  bool get available;

  /// Whether [word] is spelled correctly.
  bool isCorrect(String word);

  /// Suggestions for [word], best first (empty when unavailable).
  List<String> suggest(String word);

  /// Releases the native handle.
  void dispose();
}

/// The inert checker used where hunspell is absent.
final class NoopSpellChecker implements SpellChecker {
  /// Creates the no-op checker.
  const new();

  @override
  bool get available => false;

  @override
  bool isCorrect(String word) => true;

  @override
  List<String> suggest(String word) => const <String>[];

  @override
  void dispose() {}
}

/// A [SpellChecker] over several dictionaries at once.
///
/// Hunspell opens one dictionary per handle, so a note that mixes languages
/// — or a library whose writer does — is checked against one engine per
/// chosen language. A word is correct as soon as *any* of them knows it;
/// the suggestions are every engine's, in selection order and deduplicated
/// (T-PP-09, revised).
final class MultiSpellChecker implements SpellChecker {
  /// Creates a checker over the given engines, in priority order.
  new(this._checkers);

  final List<SpellChecker> _checkers;

  @override
  bool get available => _checkers.any((checker) => checker.available);

  @override
  bool isCorrect(String word) {
    final usable = _checkers.where((checker) => checker.available);
    if (usable.isEmpty) return true;
    return usable.any((checker) => checker.isCorrect(word));
  }

  @override
  List<String> suggest(String word) {
    final suggestions = <String>{};
    for (final checker in _checkers) {
      if (!checker.available) continue;
      suggestions.addAll(checker.suggest(word));
    }
    return suggestions.toList(growable: false);
  }

  @override
  void dispose() {
    for (final checker in _checkers) {
      checker.dispose();
    }
  }
}
