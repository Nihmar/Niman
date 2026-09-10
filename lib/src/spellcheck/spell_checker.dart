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
