/// Measures the block tree and our inline parser against the conformance
/// suites (`docs/dev/block-tree.md`): each example written by `TreeHtml`
/// and compared with the expected HTML under cmark's normalization.
///
/// Usage:
///
/// ```sh
/// dart run tool/tree_spec.dart                   # counts by section
/// dart run tool/tree_spec.dart --failures 20     # and the first failures
/// dart run tool/tree_spec.dart --section Emphasis --failures 50
/// ```
library;

// A command-line report: printing is its output.
// ignore_for_file: avoid_print

import 'package:niman/src/markdown/html/tree_html.dart';

import 'html_normalize.dart';
import 'spec_suite.dart';

void main(List<String> args) {
  final failures = _intOption(args, '--failures') ?? 0;
  final only = _option(args, '--section');
  final suites = <(String, List<SpecExample>)>[
    for (final suite in loadSpecSuites()) (suite.name, suite.examples),
    (cmarkGfmExtensionsName, loadExtensionExamples()),
  ];
  for (final (name, examples) in suites) {
    final passed = <String, int>{};
    final total = <String, int>{};
    final shown = <String>[];
    var pass = 0;
    for (final example in examples) {
      if (only != null && example.section != only) continue;
      total[example.section] = (total[example.section] ?? 0) + 1;
      String got;
      try {
        got = TreeHtml(example.markdown).render();
      } on Object catch (error) {
        got = 'THROWS $error';
      }
      // `<IGNORE>`: the example only asks that the parse not fail.
      if (example.html == '<IGNORE>\n' && !got.startsWith('THROWS') ||
          normalizeHtml(got) == normalizeHtml(example.html)) {
        passed[example.section] = (passed[example.section] ?? 0) + 1;
        pass++;
      } else if (args.contains('--ids')) {
        shown.add('$name/${example.number} @${example.section}');
      } else if (shown.length < failures) {
        shown.add(
          '--- $name/${example.number} @${example.section}\n'
          'markdown: ${_show(example.markdown)}\n'
          'expected: ${_show(example.html)}\n'
          'got:      ${_show(got)}',
        );
      }
    }
    final count = total.values.fold(0, (a, b) => a + b);
    print('## $name: $pass / $count');
    for (final section in total.keys) {
      final ok = passed[section] ?? 0;
      final all = total[section]!;
      print('  ${ok == all ? ' ' : '!'} $section: $ok / $all');
    }
    shown.forEach(print);
    print('');
  }
}

String _show(String text) =>
    text.replaceAll('\n', r'\n').replaceAll('\t', r'\t');

String? _option(List<String> args, String name) {
  final at = args.indexOf(name);
  return at >= 0 && at + 1 < args.length ? args[at + 1] : null;
}

int? _intOption(List<String> args, String name) {
  final value = _option(args, name);
  return value == null ? null : int.tryParse(value);
}
