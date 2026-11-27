// Builds the dictionary packs the app downloads (#1381) from wiktextract's
// extraction of Wiktionary, the way docs/records/dictionary.md ("The pipeline")
// describes. A dump is read as a stream, plain or gzipped, and never decoded
// to disk or held in memory: the English edition is 24.8 GB.
//
//   dart run tool/dictionary_pack.dart --out build/dictionary \
//     --english raw-wiktextract-data.jsonl.gz \
//     --edition it=it-extract.jsonl.gz --edition fr=fr-extract.jsonl.gz \
//     --languages en,it,fr,sv
//
// A language given an `--edition` is built from its own Wiktionary, with its
// inflected forms completed from the English edition; every other language is
// built from the English edition and glossed in English. One pass over the
// English edition builds all of the latter at once. Without `--languages`
// every pack of the record's table is built.
//
// Per pack it writes `<out>/niman-xx/` (the StarDict files), `niman-xx.tar`
// (what is published) and `niman-xx.report.json`, and `report.txt` for all.
//
// Other flags: `--work <dir>` for the spill files (default `<out>/work`),
// `--memory <MB>` for what the sorts may hold (default 1024), `--date
// YYYY-MM-DD` for the `.ifo` (default today), `--examples <n>` per sense
// (default 2), `--no-dictzip` to leave `.dict` plain, `--archives-only` to
// delete each pack's folder once it is archived.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;

import 'dictionary_pack/pack_build.dart';
import 'dictionary_pack/pack_languages.dart';

Future<void> main(List<String> args) async {
  final Map<String, List<String>> flags;
  try {
    flags = _parse(args);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(64);
  }
  if (flags.containsKey('help') || flags.isEmpty) {
    print(_usage);
    return;
  }
  try {
    final options = _options(flags);
    final reports = await buildPacks(options, (m) => stderr.writeln(m));
    print('Built ${reports.length} packs into ${options.outDir.path}.');
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(64);
  }
}

const String _usage = '''
dart run tool/dictionary_pack.dart --out <dir> [--english <jsonl[.gz]>]
    [--edition <code>=<jsonl[.gz]> ...] [--languages <code,code,...>]
    [--work <dir>] [--memory <MB>] [--date <YYYY-MM-DD>] [--examples <n>]
    [--no-dictzip] [--archives-only]''';

const Set<String> _valueFlags = {
  'out',
  'english',
  'edition',
  'languages',
  'work',
  'memory',
  'date',
  'examples',
};

Map<String, List<String>> _parse(List<String> args) {
  final flags = <String, List<String>>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) throw FormatException('Unexpected "$arg".');
    final equals = arg.indexOf('=');
    final name = equals < 0 ? arg.substring(2) : arg.substring(2, equals);
    if (name == 'help' || name == 'no-dictzip' || name == 'archives-only') {
      flags[name] = [];
    } else if (_valueFlags.contains(name)) {
      final String value;
      if (equals >= 0) {
        value = arg.substring(equals + 1);
      } else if (i + 1 < args.length) {
        value = args[++i];
      } else {
        throw FormatException('--$name needs a value.');
      }
      flags.putIfAbsent(name, () => []).add(value);
    } else {
      throw FormatException('Unknown flag --$name.');
    }
  }
  return flags;
}

BuildOptions _options(Map<String, List<String>> flags) {
  String? one(String name) => flags[name]?.last;
  final out = one('out');
  if (out == null) throw const FormatException('--out is required.');
  final ownEditions = <String, File>{};
  for (final spec in flags['edition'] ?? const <String>[]) {
    final equals = spec.indexOf('=');
    if (equals < 0) {
      throw const FormatException('--edition wants <code>=<file>.');
    }
    final code = spec.substring(0, equals);
    final language = packLanguageFor(code);
    if (language == null || language.code != code) {
      throw FormatException('No pack "$code".');
    }
    if (code == 'en') {
      throw const FormatException('English is built from the English edition.');
    }
    ownEditions[code] = File(spec.substring(equals + 1));
  }
  final languages = one('languages') == null
      ? packLanguages
      : [
          for (final code in one('languages')!.split(','))
            packLanguageFor(code.trim()) ??
                (throw FormatException('No pack "$code".')),
        ];
  final english = one('english');
  final memory = int.tryParse(one('memory') ?? '1024');
  final examples = int.tryParse(one('examples') ?? '2');
  if (memory == null || memory < 16 || examples == null || examples < 0) {
    throw const FormatException('--memory and --examples want numbers.');
  }
  final now = DateTime.now().toUtc();
  return BuildOptions(
    outDir: Directory(out),
    workDir: Directory(one('work') ?? p.join(out, 'work')),
    languages: languages.toSet().toList(),
    date:
        one('date') ??
        '${now.year}-${'${now.month}'.padLeft(2, '0')}'
            '-${'${now.day}'.padLeft(2, '0')}',
    englishEdition: english == null ? null : File(english),
    ownEditions: ownEditions,
    memoryBytes: memory << 20,
    dictzip: !flags.containsKey('no-dictzip'),
    maxExamples: examples,
    keepFolders: !flags.containsKey('archives-only'),
  );
}
