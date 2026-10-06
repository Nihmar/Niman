/// Documents where our reading once parted from `cmark-gfm`'s, held to the
/// HTML `cmark-gfm` writes for them (`docs/dev/block-tree.md`).
///
/// The specs' examples cannot reach every shape containers make;
/// `tool/cmark_harness.dart` finds the ones they miss on documents made at
/// random, against `cmark-gfm` itself. Each divergence fixed is kept here
/// with `cmark-gfm`'s answer, written by `tool/cmark_cases.py`, so the gate
/// needs no Python.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:path/path.dart' as p;

import '../../tool/html_normalize.dart';
import '../../tool/spec_suite.dart';

void main() {
  final cases = (jsonDecode(
    File(p.join(specFixtureDirectory, 'cmark-cases.json')).readAsStringSync(),
  ) as List<Object?>).cast<Map<String, Object?>>();

  for (final entry in cases) {
    final markdown = entry['markdown']! as String;
    test('${entry['about']}: ${jsonEncode(markdown)}', () {
      final ours = TreeHtml(markdown, appSyntax: false).render();
      expect(normalizeHtml(ours), normalizeHtml(entry['html']! as String));
    });
  }
}
