import 'package:niman/src/dictionary/dictionary_entry.dart';

/// How a look-up ended.
enum DictionaryOutcome {
  /// One or more entries were found.
  found,

  /// The pack has nothing under the selection: [DictionaryResult.suggestions]
  /// are the nearest keys ("did you mean").
  notFound,

  /// No pack serves the language: the panel offers to download it.
  noPack,

  /// A pack serves the language but cannot be used (a format this app does
  /// not know, a damaged file, an index that would not build);
  /// [DictionaryResult.reason] says why.
  unavailable,
}

/// The answer to a look-up: what the panel draws.
final class DictionaryResult {
  /// A result of [outcome] for [selection] in [language].
  const new({
    required this.outcome,
    required this.selection,
    required this.language,
    this.packId,
    this.matched,
    this.entries = const [],
    this.suggestions = const [],
    this.reason,
  });

  /// How it ended.
  final DictionaryOutcome outcome;

  /// The text that was selected.
  final String selection;

  /// The language it was looked up in, as it was asked (`pt-BR`).
  final String language;

  /// The pack that was asked (`niman-it`), null when there is none.
  final String? packId;

  /// The candidate that was found, which is what the look-up read: *caminetti*
  /// for a selection of *Caminetti,*. Null when nothing was.
  final String? matched;

  /// The entries found, a lemma each: a form shared by two lemmas gives
  /// both. Each says, in `foundForm`, the form it was read through.
  final List<DictionaryEntry> entries;

  /// The nearest keys when nothing was found, a handful, to offer as *did
  /// you mean*.
  final List<String> suggestions;

  /// Why a pack is unavailable, for [DictionaryOutcome.unavailable].
  final String? reason;

  /// Whether any entry was found.
  bool get isFound => outcome == DictionaryOutcome.found;
}
