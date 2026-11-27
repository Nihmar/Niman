import 'package:niman/src/ui/strings.dart';

/// A pack's grammar words, said in the app's language.
///
/// A pack holds no words of the interface (docs/records/dictionary.md, "The
/// pack format"): its parts of speech and tags are wiktextract's codes
/// (`noun`, `plural`), and the panel names them from the strings. A code the
/// strings do not know is shown as it is, which a reader of the language
/// can usually still read.
final class GrammarNames {
  const new _();

  /// The name of the part of speech [code].
  static String partOfSpeech(String code) => _word(code);

  /// The names of [tags], joined as a list is read.
  static String tags(Iterable<String> tags) => tags.map(_word).join(', ');

  /// A part of speech with its tags: `noun, masculine`.
  static String describe(String pos, Iterable<String> tags) =>
      [if (pos.isNotEmpty) partOfSpeech(pos), ...tags.map(_word)].join(', ');

  static String _word(String code) => AppStrings.lookUpGrammar[code] ?? code;
}
