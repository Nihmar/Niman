// What the pack keeps of a wiktextract entry, and how it is read from one.
//
// The English edition and the other editions name things alike but not
// identically (checked against wiktextract's JSON schemas, 2026-11-27):
//  * `raw_tags` is on every edition's senses and forms, not on the English
//    edition's documented schema, which keeps the printed label in `tags`;
//  * `alt_of` is absent from the Italian, Japanese and Dutch schemas, where
//    `form_of` carries both;
//  * a gender is in the top-level `tags` of the other editions, and only in
//    the English edition's `head_templates` expansion ("caminetto m (plural
//    caminetti)");
//  * the forms of the English edition carry bookkeeping tags
//    (`table-tags`, `inflection-template`, `class`) and placeholders.
// So each field is read defensively: a wrong type is "absent", never an error.
import 'dart:convert';

/// An inflected form, or another spelling, of an entry's headword.
final class SourceForm {
  /// The [form] with its [tags].
  const new(this.form, this.tags);

  /// The form as written.
  final String form;

  /// wiktextract's tags for it (`plural`, `Cyrillic`…).
  final List<String> tags;
}

/// One sense with a gloss.
final class SourceSense {
  /// A sense of [gloss].
  const new({
    required this.gloss,
    required this.qualifier,
    required this.examples,
    required this.formOf,
    required this.tags,
  });

  /// The gloss text.
  final String gloss;

  /// The qualifier the source printed (`figurative`, `biology`), or empty.
  final String qualifier;

  /// Example sentences, at most the few the pack keeps.
  final List<String> examples;

  /// The lemmas this sense is an inflected form or another spelling of.
  final List<String> formOf;

  /// The sense's tags, kept for [formOf] (`plural`).
  final List<String> tags;
}

/// An entry of a language: one headword in one part of speech.
final class SourceEntry {
  /// The [word] as [pos], with its [senses] and [forms].
  const new({
    required this.word,
    required this.pos,
    required this.tags,
    required this.senses,
    required this.forms,
  });

  /// The headword.
  final String word;

  /// wiktextract's part-of-speech code (`noun`, `verb`, `adj`…).
  final String pos;

  /// The entry's own tags: its gender.
  final List<String> tags;

  /// The senses that have a gloss; never empty.
  final List<SourceSense> senses;

  /// Its inflected forms and other spellings.
  final List<SourceForm> forms;
}

/// Tags that say what a sense *is* (a plural, a masculine) and not how it is
/// used, so they are not a qualifier.
const Set<String> _grammarTags = {
  'masculine',
  'feminine',
  'neuter',
  'common',
  'singular',
  'plural',
  'dual',
  'form-of',
  'alt-of',
  'no-gloss',
};

/// Tags of a form that are the extractor's bookkeeping, not a form.
const Set<String> _bookkeepingTags = {
  'table-tags',
  'inflection-template',
  'class',
  'gender',
};

/// What the head template's gender abbreviations stand for.
const Map<String, List<String>> _genders = {
  'm': ['masculine'],
  'f': ['feminine'],
  'n': ['neuter'],
  'c': ['common'],
  'mf': ['masculine', 'feminine'],
  'impf': ['imperfective'],
  'pf': ['perfective'],
};

/// The longest a headword may be: StarDict's limit, in bytes.
const int maxHeadwordBytes = 255;

/// Reads wiktextract entries into [SourceEntry]s.
final class EntryParser {
  /// A parser for the English edition when [englishEdition] is true: its
  /// qualifiers are `tags` and its genders are in the head template.
  /// [maxExamples] caps the examples a sense keeps; [keepRomanization] keeps
  /// the forms tagged `romanization`, which are the other script of
  /// Serbo-Croatian.
  new({
    required this.englishEdition,
    this.maxExamples = 2,
    this.keepRomanization = false,
  });

  /// Whether the entries come from the English edition.
  final bool englishEdition;

  /// The examples a sense keeps.
  final int maxExamples;

  /// Whether `romanization` forms are kept.
  final bool keepRomanization;

  /// Why entries were left out, counted by reason.
  final Map<String, int> skipped = {};

  /// The longest example worth keeping: longer ones are quotations.
  static const int _maxExampleLength = 240;

  /// The entry [json] holds, or null (and the reason counted) when there is
  /// nothing to keep.
  SourceEntry? parse(Map<String, Object?> json) {
    if (json['redirect'] != null) return _skip('redirect');
    final word = _text(json['word']);
    if (word == null) return _skip('no word');
    if (word.contains('\u0000') ||
        utf8.encode(word).length > maxHeadwordBytes) {
      return _skip('unusable headword');
    }
    final senses = <SourceSense>[];
    final rawSenses = json['senses'];
    if (rawSenses is List<Object?>) {
      for (final raw in rawSenses) {
        final sense = raw is Map<String, Object?> ? _sense(raw) : null;
        if (sense != null) senses.add(sense);
      }
    }
    if (senses.isEmpty) return _skip('no sense with a gloss');
    return SourceEntry(
      word: word,
      pos: _token(_text(json['pos']) ?? 'unknown'),
      tags: {..._tokens(json['tags']), ..._headGender(json)}.toList(),
      senses: senses,
      forms: _forms(json['forms'], word),
    );
  }

  SourceEntry? _skip(String reason) {
    skipped[reason] = (skipped[reason] ?? 0) + 1;
    return null;
  }

  SourceSense? _sense(Map<String, Object?> json) {
    final glosses = json['glosses'];
    String? gloss;
    // A sub-sense lists its parents' glosses first; the sense is the last.
    if (glosses is List<Object?>) {
      for (final g in glosses.reversed) {
        gloss = _text(g);
        if (gloss != null) break;
      }
    }
    if (gloss == null) return null;
    final tags = _tokens(json['tags']);
    final formOf = {
      ..._lemmas(json['form_of']),
      ..._lemmas(json['alt_of']),
    }.toList();
    return SourceSense(
      gloss: gloss,
      qualifier: _qualifier(json, tags, isForm: formOf.isNotEmpty),
      examples: _examples(json['examples']),
      formOf: formOf,
      // `form-of` is what the paragraph's class already says.
      tags: tags.where((t) => t != 'form-of').toList(),
    );
  }

  /// The label a sense is printed with: what the source wrote (`raw_tags`)
  /// in another edition, its `tags` in the English one, and the topics.
  String _qualifier(
    Map<String, Object?> json,
    List<String> tags, {
    required bool isForm,
  }) {
    final raw = _texts(json['raw_tags']);
    final parts = <String>{
      if (englishEdition && !isForm)
        ...tags.where((t) => !_grammarTags.contains(t)),
      ...raw,
      ..._texts(json['topics']),
    };
    return parts.join(', ');
  }

  List<String> _examples(Object? raw) {
    final examples = <String>[];
    if (raw is! List<Object?>) return examples;
    for (final example in raw) {
      if (examples.length >= maxExamples) break;
      if (example is! Map<String, Object?>) continue;
      final type = _text(example['type']);
      if (type == 'quotation' || type == 'quote') continue;
      final text = _text(example['text']);
      if (text == null || text.length > _maxExampleLength) continue;
      examples.add(text);
    }
    return examples;
  }

  Iterable<String> _lemmas(Object? raw) sync* {
    if (raw is! List<Object?>) return;
    for (final item in raw) {
      final word = item is Map<String, Object?>
          ? _text(item['word'])
          : _text(item);
      if (word != null) yield word;
    }
  }

  List<SourceForm> _forms(Object? raw, String word) {
    final forms = <SourceForm>[];
    if (raw is! List<Object?>) return forms;
    for (final item in raw) {
      if (item is! Map<String, Object?>) continue;
      final form = _text(item['form']);
      if (form == null || form == word) continue;
      if (form.length > 120 || form.contains('\t')) continue;
      if (_isPlaceholder(form)) continue;
      final tags = [..._tokens(item['tags']), ..._tokens(item['raw_tags'])];
      // `error-unknown-tag` and its kin mark a form the extractor could not
      // read.
      if (tags.any(
        (t) => _bookkeepingTags.contains(t) || t.startsWith('error-'),
      )) {
        continue;
      }
      if (tags.contains('romanization') && !keepRomanization) continue;
      forms.add(SourceForm(form, tags));
    }
    return forms;
  }

  /// The gender the English edition's head template spells after the
  /// headword: `caminetto m (plural caminetti)`, `libro m or f`.
  Iterable<String> _headGender(Map<String, Object?> json) sync* {
    final templates = json['head_templates'];
    if (templates is! List<Object?> || templates.isEmpty) return;
    final first = templates.first;
    final expansion = first is Map<String, Object?>
        ? _text(first['expansion'])
        : null;
    if (expansion == null) return;
    final head = expansion.split('(').first.trim().split(' ');
    var i = head.length - 1;
    final found = <String>[];
    // From the end: the abbreviations, joined by `or`, but never the whole
    // expansion, which is then the headword itself.
    while (i > 0 && (head[i] == 'or' || _genders.containsKey(head[i]))) {
      found.addAll(_genders[head[i]] ?? const []);
      i--;
    }
    yield* found.reversed;
  }

  bool _isPlaceholder(String form) =>
      form == '-' ||
      form == '—' ||
      form == '–' ||
      form.startsWith('no-table-tags') ||
      form.startsWith('multiword-');
}

/// [raw] as one line of trimmed text, or null when it is not text or empty.
String? _text(Object? raw) {
  if (raw is! String) return null;
  final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.isEmpty ? null : text;
}

List<String> _texts(Object? raw) => [
  if (raw is List<Object?>)
    for (final item in raw)
      if (_text(item) case final String text) text,
];

List<String> _tokens(Object? raw) => [
  for (final text in _texts(raw)) _token(text),
];

/// A tag as one token of a space-separated list.
String _token(String text) => text.replaceAll(' ', '-');
