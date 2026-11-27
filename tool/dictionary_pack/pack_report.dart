// What a build measured of a pack: the numbers the sizes in the settings and
// the bar for an own edition (docs/records/dictionary.md, "The packs") are set
// from. The pipeline reports them; it does not decide the bar.

/// An own edition's pack set against what the English edition has for the same
/// language.
final class EnglishComparison {
  /// The numbers of one comparison.
  const new({
    required this.englishHeadwords,
    required this.englishSenses,
    required this.sharedHeadwords,
    required this.sharedOwnSenses,
    required this.sharedEnglishSenses,
    required this.formsFromEnglish,
  });

  /// The headwords the English edition has for the language.
  final int englishHeadwords;

  /// The senses it has for them.
  final int englishSenses;

  /// The headwords both editions have.
  final int sharedHeadwords;

  /// On those, the senses of the own edition...
  final int sharedOwnSenses;

  /// ... and of the English one.
  final int sharedEnglishSenses;

  /// The forms the own edition's pack gained from the English one.
  final int formsFromEnglish;

  /// The share of the English edition's headwords the own edition has.
  double get coverage =>
      englishHeadwords == 0 ? 0 : sharedHeadwords / englishHeadwords;

  /// The own edition's senses for each of the shared headwords, against the
  /// English edition's.
  double get senseRatio =>
      sharedEnglishSenses == 0 ? 0 : sharedOwnSenses / sharedEnglishSenses;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'englishHeadwords': englishHeadwords,
    'englishSenses': englishSenses,
    'sharedHeadwords': sharedHeadwords,
    'coverage': _round(coverage),
    'sharedOwnSenses': sharedOwnSenses,
    'sharedEnglishSenses': sharedEnglishSenses,
    'senseRatio': _round(senseRatio),
    'formsFromEnglish': formsFromEnglish,
  };
}

/// What one pack holds and weighs.
final class PackReport {
  /// The report of the pack [id].
  new({
    required this.id,
    required this.languages,
    required this.definitions,
    required this.source,
    required this.headwords,
    required this.inflectionHeadwords,
    required this.sourceEntries,
    required this.senses,
    required this.forms,
    required this.synRecords,
    required this.skipped,
    required this.fileSizes,
    this.comparison,
  });

  /// `niman-it`.
  final String id;

  /// The app languages it serves.
  final List<String> languages;

  /// The language of its glosses.
  final String definitions;

  /// The Wiktionary editions it was built from.
  final String source;

  /// The `.idx` entries.
  final int headwords;

  /// Of them, those with a section that is a form or spelling of another.
  final int inflectionHeadwords;

  /// The wiktextract entries kept (a headword has one per part of speech).
  final int sourceEntries;

  /// The senses in the pack.
  final int senses;

  /// The distinct forms listed on the headwords.
  final int forms;

  /// The `.syn` records.
  final int synRecords;

  /// The source entries left out, by reason.
  final Map<String, int> skipped;

  /// The size in bytes of each file, by extension (`ifo`, `idx`, `syn`,
  /// `dict`, `dict.dz`), and of the `tar` once it is made.
  final Map<String, int> fileSizes;

  /// Against the English edition, for an own edition.
  final EnglishComparison? comparison;

  /// The senses a headword has on average.
  double get sensesPerHeadword => headwords == 0 ? 0 : senses / headwords;

  /// The JSON form.
  Map<String, Object?> toJson() => {
    'id': id,
    'languages': languages,
    'definitions': definitions,
    'source': source,
    'headwords': headwords,
    'inflectionHeadwords': inflectionHeadwords,
    'sourceEntries': sourceEntries,
    'senses': senses,
    'sensesPerHeadword': _round(sensesPerHeadword),
    'forms': forms,
    'synRecords': synRecords,
    'skipped': skipped,
    'fileSizes': fileSizes,
    if (comparison != null) 'english': comparison!.toJson(),
  };

  /// The readable lines of the report.
  String summary() {
    final out = StringBuffer()
      ..writeln('$id  (${languages.join(', ')}; definitions: $definitions)')
      ..writeln('  source           $source')
      ..writeln(
        '  headwords        $headwords '
        '($inflectionHeadwords are an inflected form or spelling)',
      )
      ..writeln(
        '  senses           $senses '
        '(${sensesPerHeadword.toStringAsFixed(2)} per headword)',
      )
      ..writeln('  forms            $forms')
      ..writeln('  .syn records     $synRecords');
    fileSizes.forEach(
      (name, size) => out.writeln('  ${'.$name'.padRight(15)}  $size bytes'),
    );
    if (skipped.isNotEmpty) {
      final left = skipped.entries.map((e) => '${e.key}: ${e.value}');
      out.writeln('  left out         ${left.join(', ')}');
    }
    final c = comparison;
    if (c != null) {
      out
        ..writeln('  against the English edition:')
        ..writeln(
          '    english headwords  ${c.englishHeadwords} '
          '(${c.englishSenses} senses)',
        )
        ..writeln(
          '    shared headwords   ${c.sharedHeadwords} '
          '(coverage ${(c.coverage * 100).toStringAsFixed(1)}%)',
        )
        ..writeln(
          '    senses on shared   own ${c.sharedOwnSenses} vs '
          'english ${c.sharedEnglishSenses} '
          '(ratio ${c.senseRatio.toStringAsFixed(2)})',
        )
        ..writeln('    forms from english ${c.formsFromEnglish}');
    }
    return out.toString();
  }
}

double _round(double value) => (value * 10000).round() / 10000;
