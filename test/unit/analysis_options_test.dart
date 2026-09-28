// The analyzer gate is `flutter analyze --fatal-infos`
// (`.github/workflows/check.yml`), so anything `analysis_options.yaml` leaves
// off is unremarked: an implicit cast stays an info and an un-typed raw
// generic is not reported at all. This pins the three strict language modes on
// (issue #394).
//
// The `android/`, `linux/` and `windows/` exclusions are not the project's to
// drop. `flutter analyze`, `flutter test` and `flutter build` all run
// `flutter_tools`' `AnalysisOptionsMigration` before anything else, and it
// rewrites `analysis_options.yaml` to put those three patterns back, so a
// version of this file without them does not survive the next command. What
// can be pinned is that they keep the analyzer out of a tree with no
// first-party Dart: the platform sources hold no `.dart` of their own, and
// their `flutter/ephemeral/.plugin_symlinks` entries point at the pub cache
// (third-party plugin code that must not be analyzed as part of this app).
//
// Run from the package root, like `flutter test` does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The `analyzer:` section of the package root's `analysis_options.yaml`.
Map<String, dynamic> analyzerSection() {
  final file = File('analysis_options.yaml');
  expect(file.existsSync(), isTrue, reason: 'run from the package root');
  final root = Map<String, dynamic>.from(
    loadYaml(file.readAsStringSync()) as Map<dynamic, dynamic>,
  );
  return Map<String, dynamic>.from(root['analyzer'] as Map);
}

/// The patterns under `analyzer: exclude:`.
List<String> excludedPatterns() => <String>[
  for (final pattern in analyzerSection()['exclude'] as List) pattern as String,
];

void main() {
  test('the three strict language modes are on', () {
    final language = Map<String, dynamic>.from(
      analyzerSection()['language'] as Map,
    );
    expect(language['strict-casts'], isTrue);
    expect(language['strict-raw-types'], isTrue);
    expect(language['strict-inference'], isTrue);
  });

  test('the generated build tree is still kept out of analysis', () {
    expect(excludedPatterns(), contains('build/**'));
  });

  test('no excluded tree holds first-party Dart', () {
    for (final pattern in excludedPatterns()) {
      // Every pattern is a `<dir>/**` tree exclusion.
      expect(pattern, endsWith('/**'));
      final directory = Directory(
        pattern.substring(0, pattern.length - '/**'.length),
      );
      if (!directory.existsSync()) {
        // Nothing generated yet, so nothing to hide either.
        continue;
      }
      // `followLinks: false`: the platform trees reach the pub cache through
      // `ephemeral/.plugin_symlinks`, whose Dart is not this package's.
      final dart = directory
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .map((file) => file.path)
          .where((path) => p.extension(path) == '.dart')
          .toList();
      expect(
        dart,
        isEmpty,
        reason: '$pattern is excluded but holds first-party Dart: $dart',
      );
    }
  });
}
