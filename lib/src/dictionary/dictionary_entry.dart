import 'package:niman/src/dictionary/dictionary_credit.dart';
import 'package:niman/src/dictionary/dictionary_form.dart';
import 'package:niman/src/dictionary/dictionary_section.dart';

/// What the panel draws for one headword: the lemma, the form that led to
/// it, its parts of speech with their senses, its forms and where it comes
/// from.
///
/// Parsed from the pack's HTML by `DictionaryEntryParser`; a value, so it
/// crosses from the worker isolate to the UI as it is.
final class DictionaryEntry {
  /// An entry for [headword] in [language], from the pack [credit] names.
  const new({
    required this.headword,
    required this.language,
    required this.credit,
    this.sections = const [],
    this.forms = const [],
    this.foundForm,
  });

  /// The headword, the lemma: *caminetto* for a look-up of *caminetti*.
  final String headword;

  /// The language the look-up was for (a Croatian book finds an entry of the
  /// Serbo-Croatian pack and reads `hr`).
  final String language;

  /// The parts of speech, in the order the pack lists them.
  final List<DictionarySection> sections;

  /// The headword's inflected forms, with their tags.
  final List<DictionaryForm> forms;

  /// The form that was looked up, when it is not the headword: *caminetti*,
  /// plural. Null when the headword itself was.
  final DictionaryForm? foundForm;

  /// The pack's licence and sources.
  final DictionaryCredit credit;

  /// The lemmas the entry says it is a form of, across its sections, each
  /// once: what the panel offers as a look-up of its own.
  List<DictionaryForm> get lemmas {
    final seen = <String>{};
    return [
      for (final section in sections)
        for (final lemma in section.formOf)
          if (seen.add(lemma.text)) lemma,
    ];
  }
}
