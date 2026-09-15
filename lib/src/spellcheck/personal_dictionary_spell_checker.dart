import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';

/// A [SpellChecker] that layers a library's personal dictionary in front
/// of its delegate (issue #60): a word in the dictionary is always correct,
/// whatever the engines say, and gets no suggestions.
///
/// [available] stays the delegate's: the dictionary alone never makes a
/// machine spell-checkable, so where no engine loads (Android) there is
/// still nothing to underline — and no "Add to dictionary" to offer.
final class PersonalDictionarySpellChecker implements SpellChecker {
  /// Creates the wrapper: the dictionary's words always pass, everything
  /// else is asked of the delegate engine.
  new(this._dictionary, this._delegate);

  final PersonalDictionary _dictionary;
  final SpellChecker _delegate;

  @override
  bool get available => _delegate.available;

  @override
  bool isCorrect(String word) =>
      _dictionary.contains(word) || _delegate.isCorrect(word);

  @override
  List<String> suggest(String word) =>
      _dictionary.contains(word) ? const <String>[] : _delegate.suggest(word);

  @override
  void dispose() => _delegate.dispose();
}
