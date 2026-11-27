// Generates lib/src/dictionary/dictionary_catalog.dart: every dictionary pack
// built by tool/dictionary_pack.dart, with the URL it is published at on the
// `dictionary-pack-N` prerelease and the size and SHA-256 of its archive
// (#1381).
//
//   dart run tool/dictionary_catalog.dart <dir of niman-xx.tar> <tag>
//   dart run tool/dictionary_catalog.dart build/dictionary dictionary-pack-1
//
// The archives are read where they were built, not downloaded: the digests
// the app checks its download against are those of the files that are
// uploaded. `.github/workflows/dictionary-pack.yml` runs it and attaches the
// result to the build; a release commits it.
// ignore_for_file: avoid_print

import 'dart:io';

import 'dictionary_pack/catalog_writer.dart';

const _out = 'lib/src/dictionary/dictionary_catalog.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('Usage: dart run tool/dictionary_catalog.dart <dir> <tag>');
    exit(64);
  }
  try {
    final source = await generateCatalog(Directory(args[0]), args[1]);
    File(_out).writeAsStringSync(source);
    // The file is committed, and CI gates its formatting.
    final formatted = await Process.run('dart', ['format', _out]);
    if (formatted.exitCode != 0) stderr.write(formatted.stderr);
    print('wrote $_out');
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(64);
  }
}
