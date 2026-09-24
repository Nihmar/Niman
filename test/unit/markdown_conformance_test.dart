/// The conformance gate: the `markdown` package against both spec suites.
///
/// Decision D2 makes the package the parser, so this is where "how far off is
/// it" stops being an assumption. Measured 2026-09-21: **645/652 CommonMark
/// and 662/677 GFM** by cmark's own comparison, with 22 examples accepted and
/// triaged in `test/fixtures/spec/nonconforming.txt`. The eight examples that
/// differ only in formatting are not listed: by the reference's own comparison
/// they pass.
///
/// The gate works in both directions, which is what stops the allowlist from
/// rotting: every example outside it must pass, and every example inside it
/// must still fail. An allowlisted example that starts passing is a failure of
/// this test until the line is removed — so a fix cannot go unnoticed, and a
/// regression cannot hide behind an old exemption.
///
/// The comparison is on normalized HTML (`tool/html_normalize.dart`, itself
/// checked against cmark's own normalizer in `html_normalize_test.dart`). That
/// matters for reading the number honestly: the suites compare **HTML**, while
/// Niman will consume the package's **AST**, so several pinned divergences
/// (`data-metadata`, task-list `class` attributes) are serializer details that
/// never reach a user. The HTML number is therefore a lower bound.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/html_normalize.dart';
import '../../tool/spec_suite.dart';

void main() {
  final allowlist = _loadAllowlist(
    p.join(specFixtureDirectory, 'nonconforming.txt'),
  );
  final suites = loadSpecSuites();

  for (final suite in suites) {
    group(suite.name, () {
      for (final example in suite.examples) {
        final id = '${suite.name}/${example.number}';
        final allowed = allowlist.containsKey(id);
        test(
          '${suite.testNameFor(example)}${allowed ? ' [accepted]' : ''}',
          () {
            final actual = renderExample(suite, example);
            final matches =
                normalizeHtml(actual) == normalizeHtml(example.html);
            if (allowed) {
              expect(
                matches,
                isFalse,
                reason:
                    '$id passes now. Remove it from nonconforming.txt, and '
                    'say in the design document what changed: '
                    '${allowlist[id]}',
              );
            } else {
              expect(
                matches,
                isTrue,
                reason: '$id fails and is not in nonconforming.txt',
              );
            }
          },
        );
      }
    });
  }

  test('the allowlist names no example the suites do not have', () {
    final ids = <String>{
      for (final suite in suites)
        for (final example in suite.examples) '${suite.name}/${example.number}',
    };
    expect(allowlist.keys.where((id) => !ids.contains(id)), isEmpty);
  });

  test('every allowlist line carries a bucket and a reason', () {
    for (final entry in allowlist.entries) {
      expect(
        RegExp('^(fix|pin|mask): .+').hasMatch(entry.value),
        isTrue,
        reason: '${entry.key} needs a bucket: ${entry.value}',
      );
    }
  });
}

/// `<suite>/<example> <reason>` lines, comments and blanks ignored.
Map<String, String> _loadAllowlist(String path) {
  final entries = <String, String>{};
  for (final line in File(path).readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final split = trimmed.indexOf(' ');
    if (split < 0) continue;
    entries[trimmed.substring(0, split)] = trimmed.substring(split + 1);
  }
  return entries;
}
