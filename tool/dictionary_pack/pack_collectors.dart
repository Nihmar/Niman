// The two things a pass over a dump feeds: the entries of a pack, and what the
// English edition knows about a language that is built from its own edition.
import 'dart:convert';
import 'dart:typed_data';

import 'entry_html.dart';
import 'entry_records.dart';
import 'external_sorter.dart';
import 'pack_languages.dart';
import 'serbo_croatian.dart';
import 'source_entry.dart';

/// Where the parsed entries of one language go.
abstract interface class EntrySink {
  /// Takes one entry.
  void add(SourceEntry entry);
}

/// Renders entries into the sorter the pack is written from.
final class EntryCollector implements EntrySink {
  /// Collects the entries of [language] into [sorter].
  new(this.language, this.sorter);

  /// The pack being built.
  final PackLanguage language;

  /// The rendered entries, by headword.
  final ExternalSorter sorter;

  /// The entries kept (one per headword and part of speech).
  int entries = 0;

  /// The senses in them.
  int senses = 0;

  /// The entries that are an inflected form or spelling of another.
  int formOfEntries = 0;

  int _seq = 0;

  @override
  void add(SourceEntry entry) {
    entries++;
    senses += entry.senses.length;
    if (entry.senses.any((s) => s.formOf.isNotEmpty)) formOfEntries++;
    final forms = [
      for (final form in entry.forms) '${form.tags.join(' ')}\t${form.form}',
      if (language.code == 'sh') ..._latinSpelling(entry),
    ];
    sorter.add(
      Uint8List.fromList(utf8.encode(entry.word)),
      EntryPart(
        _seq++,
        entry.senses.length,
        renderSection(entry),
        forms,
      ).encode(),
    );
  }

  /// The Latin spelling of a Cyrillic headword, unless the entry lists it.
  Iterable<String> _latinSpelling(SourceEntry entry) sync* {
    final latin = latinSpelling(entry.word);
    if (latin == null || entry.forms.any((f) => f.form == latin)) return;
    yield 'Latin	$latin';
  }
}

/// Keeps, by lemma, what the English edition says of a language: that the
/// lemma has an entry, and every form it lists for it, whether in the
/// lemma's own entry or as the entry of the inflected form.
final class EnglishFactCollector implements EntrySink {
  /// Collects the facts of one language into [sorter].
  new(this.sorter);

  /// The facts, by lemma.
  final ExternalSorter sorter;

  @override
  void add(SourceEntry entry) {
    final word = Uint8List.fromList(utf8.encode(entry.word));
    sorter.add(word, EnglishHeadword(entry.senses.length).encode());
    for (final form in entry.forms) {
      sorter.add(word, EnglishForm(form.form, form.tags.join(' ')).encode());
    }
    final seen = <String>{};
    for (final sense in entry.senses) {
      for (final lemma in sense.formOf) {
        if (lemma == entry.word || !seen.add(lemma)) continue;
        sorter.add(
          Uint8List.fromList(utf8.encode(lemma)),
          EnglishForm(entry.word, sense.tags.join(' ')).encode(),
        );
      }
    }
  }
}
