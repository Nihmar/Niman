/// The conformance gate of the block tree and our inline parser
/// (`docs/dev/block-tree.md`): every example of the GFM spec, of CommonMark
/// 0.31.2 and of `cmark-gfm`'s extension tests, written by `TreeHtml` and
/// compared with the expected HTML under cmark's normalization.
///
/// Both ways, as the package's gate was before it: an
/// example outside `tree_nonconforming.txt` must pass, and one inside it
/// must still fail — a fix cannot go unnoticed, nor a regression hide
/// behind an old entry.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:path/path.dart' as p;

import '../../tool/html_normalize.dart';
import '../../tool/spec_suite.dart';

void main() {
  final allowlist = _loadAllowlist(
    p.join(specFixtureDirectory, 'tree_nonconforming.txt'),
  );
  final suites = <(String, List<SpecExample>)>[
    for (final suite in loadSpecSuites()) (suite.name, suite.examples),
    (cmarkGfmExtensionsName, loadExtensionExamples()),
  ];

  for (final (name, examples) in suites) {
    group(name, () {
      for (final example in examples) {
        final id = '$name/${example.number}';
        final allowed = allowlist.containsKey(id);
        test('$id @${example.section}${allowed ? ' [accepted]' : ''}', () {
          final actual = TreeHtml(
            example.markdown,
            extensions: extensionsFor(name, example),
            appSyntax: false,
          ).render();
          // `<IGNORE>`: the example only asks that the parse not fail.
          final matches =
              example.html == '<IGNORE>\n' ||
              normalizeHtml(actual) == normalizeHtml(example.html);
          if (allowed) {
            expect(
              matches,
              isFalse,
              reason:
                  '$id passes now: take it out of tree_nonconforming.txt '
                  '(${allowlist[id]})',
            );
          } else {
            expect(
              matches,
              isTrue,
              reason: '$id fails and is not in tree_nonconforming.txt',
            );
          }
        });
      }
    });
  }

  test('the allowlist names no example the suites do not have', () {
    final ids = <String>{
      for (final (name, examples) in suites)
        for (final example in examples) '$name/${example.number}',
    };
    expect(allowlist.keys.where((id) => !ids.contains(id)), isEmpty);
  });

  test('every allowlist line carries a bucket and a reason', () {
    for (final entry in allowlist.entries) {
      expect(
        RegExp('^(blocks|version): .+').hasMatch(entry.value),
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
