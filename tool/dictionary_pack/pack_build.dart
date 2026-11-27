// The build: which passes over which dumps, in what order.
//
//  1. One pass over the English edition. Every language built from it (the
//     English-glossed packs, and `en`) collects its entries; every language
//     built from its own edition collects only what the English edition says
//     of it, for later.
//  2. Each English-glossed pack is written, and freed.
//  3. For each own edition, a pass over its dump, then its pack, with the
//     English facts merged in.
//
// Memory is one budget for everything in flight (`SpillBudget`): when the
// records buffered by all the sorters outgrow it, the fullest spills to disk,
// so the English pass holds `memoryBytes` however many languages it feeds.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'external_sorter.dart';
import 'pack_archive.dart';
import 'pack_collectors.dart';
import 'pack_languages.dart';
import 'pack_report.dart';
import 'pack_writer.dart';
import 'record_io.dart';
import 'source_entry.dart';
import 'wiktextract_reader.dart';

/// What a run is asked to build.
final class BuildOptions {
  /// A build into [outDir], spilling to [workDir].
  const new({
    required this.outDir,
    required this.workDir,
    required this.languages,
    required this.date,
    this.englishEdition,
    this.ownEditions = const {},
    this.memoryBytes = 1 << 30,
    this.dictzip = true,
    this.maxExamples = 2,
    this.keepFolders = true,
  });

  /// Where the packs, archives and reports go.
  final Directory outDir;

  /// Where the sorts spill; emptied as it goes.
  final Directory workDir;

  /// The packs to build.
  final List<PackLanguage> languages;

  /// The `date` the `.ifo` carries.
  final String date;

  /// The English edition's dump, when any pack is built from it.
  final File? englishEdition;

  /// The own editions' dumps, by pack code. A language with one is built
  /// from it; any other is glossed in English.
  final Map<String, File> ownEditions;

  /// The memory the sorts may hold at once.
  final int memoryBytes;

  /// Whether `.dict` is compressed (it always is, but in a test).
  final bool dictzip;

  /// The examples a sense keeps.
  final int maxExamples;

  /// Whether each pack's folder stays beside its archive: a runner short of
  /// disk keeps the archives, which are what is published, and no more.
  final bool keepFolders;
}

/// Builds every pack of [options]; [log] hears of the progress.
Future<List<PackReport>> buildPacks(
  BuildOptions options,
  void Function(String message) log,
) async {
  options.outDir.createSync(recursive: true);
  options.workDir.createSync(recursive: true);
  final budget = SpillBudget(options.memoryBytes);
  final own = [
    for (final l in options.languages)
      if (options.ownEditions.containsKey(l.code)) l,
  ];
  final english = [
    for (final l in options.languages)
      if (!options.ownEditions.containsKey(l.code)) l,
  ];
  final englishFile = options.englishEdition;
  if (english.isNotEmpty && englishFile == null) {
    throw FormatException(
      'Built from the English edition, and none given: '
      '${english.map((l) => l.code).join(', ')}.',
    );
  }

  final collectors = <String, EntryCollector>{};
  final parsers = <String, List<EntryParser>>{};
  final facts = <String, ExternalSorter>{};
  if (englishFile != null) {
    final routes = <String, LanguageRoute>{};
    for (final language in english) {
      final collector = EntryCollector(
        language,
        ExternalSorter(options.workDir, 'entries-${language.code}', budget),
      );
      collectors[language.code] = collector;
      _route(routes, parsers, language, collector, true, options);
    }
    for (final language in own) {
      final sorter = ExternalSorter(
        options.workDir,
        'facts-${language.code}',
        budget,
      );
      facts[language.code] = sorter;
      _route(
        routes,
        parsers,
        language,
        EnglishFactCollector(sorter),
        true,
        options,
      );
    }
    log('English edition: ${englishFile.path}');
    final result = await streamEntries(englishFile, routes, log);
    log(
      '  ${result.lines} lines, ${result.kept} entries kept, '
      '${result.malformed} malformed',
    );
  }

  final reports = <PackReport>[];
  for (final language in english) {
    reports.add(
      _write(
        options,
        budget,
        language,
        collectors[language.code]!,
        parsers[language.code]!,
        definitions: 'en',
        source: 'en.wiktionary',
      ),
    );
    log(reports.last.summary());
  }
  for (final language in own) {
    final file = options.ownEditions[language.code]!;
    log('${language.code} edition: ${file.path}');
    final collector = EntryCollector(
      language,
      ExternalSorter(options.workDir, 'own-${language.code}', budget),
    );
    final routes = <String, LanguageRoute>{};
    final ownParsers = <String, List<EntryParser>>{};
    _route(routes, ownParsers, language, collector, false, options);
    final result = await streamEntries(file, routes, log);
    log('  ${result.lines} lines, ${result.kept} entries kept');
    final sorter = facts[language.code];
    reports.add(
      _write(
        options,
        budget,
        language,
        collector,
        ownParsers[language.code]!,
        definitions: language.code,
        source: sorter == null
            ? '${language.code}.wiktionary'
            : '${language.code}.wiktionary+en.wiktionary',
        facts: sorter?.drain(),
      ),
    );
    log(reports.last.summary());
  }
  final summary = StringBuffer();
  for (final report in reports) {
    summary.writeln(report.summary());
  }
  File(p.join(options.outDir.path, 'report.txt'))
      .writeAsStringSync(summary.toString());
  return reports;
}

void _route(
  Map<String, LanguageRoute> routes,
  Map<String, List<EntryParser>> parsers,
  PackLanguage language,
  EntrySink sink,
  bool fromEnglish,
  BuildOptions options,
) {
  for (final code in language.sourceCodes) {
    final parser = EntryParser(
      englishEdition: fromEnglish,
      maxExamples: options.maxExamples,
      keepRomanization: language.code == 'sh',
    );
    routes[code] = LanguageRoute(parser, sink);
    parsers.putIfAbsent(language.code, () => []).add(parser);
  }
}

PackReport _write(
  BuildOptions options,
  SpillBudget budget,
  PackLanguage language,
  EntryCollector collector,
  List<EntryParser> parsers, {
  required String definitions,
  required String source,
  Iterable<SortRecord>? facts,
}) {
  final packDir = Directory(p.join(options.outDir.path, language.id));
  final report = writePack(
    (
      language: language,
      definitions: definitions,
      source: source,
      outDir: packDir,
      workDir: options.workDir,
      budget: budget,
      date: options.date,
      dictzip: options.dictzip,
    ),
    collector,
    facts: facts,
    skipped: _skipped(parsers),
  );
  final archive = File(p.join(options.outDir.path, '${language.id}.tar'));
  writePackTar(packDir, language.id, archive);
  report.fileSizes['tar'] = archive.lengthSync();
  if (!options.keepFolders) packDir.deleteSync(recursive: true);
  File(p.join(options.outDir.path, '${language.id}.report.json'))
      .writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(report.toJson())}\n',
      );
  return report;
}

Map<String, int> _skipped(List<EntryParser> parsers) {
  final total = <String, int>{};
  for (final parser in parsers) {
    parser.skipped.forEach((reason, count) {
      total[reason] = (total[reason] ?? 0) + count;
    });
  }
  return total;
}
