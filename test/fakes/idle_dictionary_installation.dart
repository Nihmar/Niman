import 'dart:io';

import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:path/path.dart' as p;

/// A dictionary installation that has nothing and offers nothing, for a
/// screen test that only needs the Dictionaries area to open: no folder, no
/// catalog, and no service, which nothing in such a test asks for.
DictionaryInstallation idleDictionaryInstallation() => DictionaryInstallation(
  directory: () async => p.join(Directory.systemTemp.path, 'niman_no_dicts'),
  service: () async => throw StateError('no dictionary service in this test'),
);
