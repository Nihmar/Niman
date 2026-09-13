/// Known-libraries mirror for the native widget config activity
/// (round 2, R1).
///
/// The config activity runs with no Dart engine, so it cannot read the
/// registry itself. Dart mirrors `{path, name, index}` per known library
/// (index = absolute path of that library's index file, so native code
/// never re-derives paths) into the widget storage on every open and
/// forget. The database stays the source of truth; this is a cache the
/// activity treats as best-effort.
///
/// Pure Dart, no I/O: callers load the registry and encode it in.
library;

import 'dart:convert';

import 'package:niman/src/db/app_database.dart';

/// The mirror key in the widget storage.
const String widgetLibrariesKey = 'known_libraries';

/// Encodes [libraries] with their index paths for the mirror.
///
/// [indexByPath] maps absolute library roots to absolute index files;
/// libraries missing from it are skipped (their index is not ready to
/// be read yet).
String encodeLibraryMirror(
  List<KnownLibrary> libraries,
  Map<String, String> indexByPath,
) {
  final entries = [
    for (final lib in libraries)
      if (indexByPath[lib.path] case final String index)
        {'path': lib.path, 'name': lib.name, 'index': index},
  ];
  return jsonEncode({'libraries': entries});
}
