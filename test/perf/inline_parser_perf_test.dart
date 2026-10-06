// Our inline parser against package:markdown's on the same leaves
// (docs/dev/block-tree.md, "Speed"): it has to be at least as fast as what
// it replaces. Measured on this host 2026-10-06 (tool/inline_bench.dart):
// 5 ms against 52 on the 200 KB fixture, 50 against 608 on the worst note.
//
// Every run holds ours to no slower than the package's on the same machine,
// a bar the hardware cannot fail; NIMAN_PERF=1 adds the absolute ones.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/inline_syntaxes.dart';
import 'package:path/path.dart' as p;

import '../../tool/inline_bench.dart' show leafTexts;

/// The fastest of five runs of [run], in microseconds.
int _best(void Function() run) {
  var best = 1 << 62;
  for (var round = 0; round < 5; round++) {
    final watch = Stopwatch()..start();
    run();
    if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
  }
  return best;
}

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  for (final (name, path, bar) in [
    (
      'the 200 KB fixture',
      p.join('test', 'fixtures', 'markdown', 'fixture-200kb.md'),
      15000,
    ),
    (
      'the worst note',
      p.join('test', 'fixtures', 'spec', 'worst-note.md'),
      120000,
    ),
  ]) {
    test('our inline parser is no slower than the package on $name', () {
      final texts = leafTexts(File(path).readAsStringSync());
      final ours = _best(() {
        for (final text in texts) {
          InlineParser(text).parse();
        }
      });
      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        inlineSyntaxes: nimanInlineSyntaxes,
      );
      final package = _best(() {
        for (final text in texts) {
          md.InlineParser(text, document).parse();
        }
      });
      print(
        '$name, ${texts.length} leaves: ours ${ours ~/ 1000} ms, '
        'the package ${package ~/ 1000} ms',
      );
      expect(ours, lessThanOrEqualTo(package));
      if (measured) expect(ours, lessThan(bar));
    });
  }
}
