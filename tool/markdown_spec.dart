/// Measures the `markdown` package against the CommonMark and GFM suites.
///
/// This is the first task of the unified Markdown surface's Phase 1
/// (`docs/records/unified-surface.md`, decision D2): the parser is the `markdown`
/// package, so the question is not "write a parser" but "how far off is the
/// one already here". Until this prints a number, conformance is an
/// assumption.
///
/// Usage:
///
/// ```sh
/// dart run tool/markdown_spec.dart                  # the report
/// dart run tool/markdown_spec.dart --failures 30    # plus the first 30 failures
/// dart run tool/markdown_spec.dart --json           # machine-readable
/// dart run tool/markdown_spec.dart --write-allowlist
/// ```
///
/// `--write-allowlist` rewrites `test/fixtures/spec/nonconforming.txt` from the
/// current run. That file is the conformance gate: `flutter test` asserts that
/// every example outside it passes and that every example inside it still
/// fails, so the list cannot rot and a fix cannot go unnoticed.
///
/// The comparison is on *normalized* HTML — cmark's own normalizer, ported in
/// `tool/html_normalize.dart` — because the suites' expected HTML and a
/// parser's output differ in whitespace, attribute order, `<br />` and entity
/// form, none of which is a parsing difference. Exact matches are reported
/// alongside so the normalizer's effect is visible rather than assumed.
library;

// The report is this tool's output: it prints to stdout by design.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'html_normalize.dart';
import 'spec_suite.dart';

Future<void> main(List<String> args) async {
  final showFailures = _intOption(args, '--failures') ?? 0;
  final asJson = args.contains('--json');
  final writeAllowlist = args.contains('--write-allowlist');
  final only = _stringOption(args, '--suite');

  final suites = loadSpecSuites()
      .where((suite) => only == null || suite.name.contains(only))
      .toList();

  final results = <SpecSuite, List<SpecFailure>>{};
  for (final suite in suites) {
    results[suite] = _run(suite);
  }

  if (asJson) {
    _printJson(results);
  } else {
    _printReport(results, showFailures);
  }

  if (writeAllowlist) {
    _writeAllowlist(results);
  }
}

/// One example that does not match, with what it produced.
final class SpecFailure {
  const new({
    required this.example,
    required this.actual,
    required this.normalized,
    this.error,
  });

  final SpecExample example;
  final String actual;
  final bool normalized;
  final String? error;
}

List<SpecFailure> _run(SpecSuite suite) {
  final failures = <SpecFailure>[];
  for (final example in suite.examples) {
    String actual;
    try {
      actual = renderExample(suite, example);
    } on Object catch (error) {
      failures.add(
        SpecFailure(
          example: example,
          actual: '',
          normalized: false,
          error: '$error',
        ),
      );
      continue;
    }
    if (actual == example.html) continue;
    if (normalizeHtml(actual) == normalizeHtml(example.html)) {
      failures.add(
        SpecFailure(example: example, actual: actual, normalized: true),
      );
    } else {
      failures.add(
        SpecFailure(example: example, actual: actual, normalized: false),
      );
    }
  }
  return failures;
}

void _printReport(Map<SpecSuite, List<SpecFailure>> results, int showFailures) {
  print('# `markdown` conformance');
  print('');
  print('| suite | examples | exact | normalized | failing |');
  print('|---|---|---|---|---|');
  for (final entry in results.entries) {
    final suite = entry.key;
    final failures = entry.value;
    final formatting = failures.where((f) => f.normalized).length;
    final total = suite.examples.length;
    print(
      '| ${suite.name} | $total | ${total - failures.length} | '
      '${total - failures.length + formatting} | ${failures.length} |',
    );
  }
  print('');

  for (final entry in results.entries) {
    final suite = entry.key;
    final bySection = <String, List<SpecFailure>>{};
    for (final failure in entry.value) {
      bySection.putIfAbsent(failure.example.section, () => []).add(failure);
    }
    final totalBySection = <String, int>{};
    for (final example in suite.examples) {
      totalBySection[example.section] =
          (totalBySection[example.section] ?? 0) + 1;
    }
    print('## ${suite.name}');
    print('');
    print('| section | pass | total |');
    print('|---|---|---|');
    for (final section in totalBySection.keys) {
      final total = totalBySection[section]!;
      final failed = bySection[section]?.length ?? 0;
      print('| $section | ${total - failed} | $total |');
    }
    print('');
  }

  if (showFailures > 0) {
    print('## Failures');
    print('');
    var shown = 0;
    for (final entry in results.entries) {
      for (final failure in entry.value) {
        if (shown >= showFailures) break;
        shown++;
        final id = '${entry.key.name}/${failure.example.number}';
        print('### $id @${failure.example.section}');
        print('');
        if (failure.error != null) {
          print('threw: ${failure.error}');
          print('');
          continue;
        }
        print('```markdown');
        print(_clip(failure.example.markdown, 160));
        print('```');
        if (failure.normalized) {
          // The parser's HTML is right; only its formatting differs, which is
          // exactly what the normalizer exists to ignore.
          print('formatting only — normalized HTML matches');
          print(_describe(failure.example.html, failure.actual));
        } else {
          print(
            _describe(
              normalizeHtml(failure.example.html),
              normalizeHtml(failure.actual),
            ),
          );
        }
        print('');
      }
      if (shown >= showFailures) break;
    }
  }
}

/// The first place the two strings differ, with context and escapes.
///
/// A bare "expected X, actual Y" is not enough to triage a failure: several of
/// them differ only by a tab that a terminal renders as nothing, so the report
/// has to say *where* and *what* rather than leave the reader squinting at two
/// apparently identical lines.
String _describe(String expected, String actual) {
  if (expected == actual) return 'identical after normalization — impossible';
  var index = 0;
  final shortest = expected.length < actual.length
      ? expected.length
      : actual.length;
  while (index < shortest && expected[index] == actual[index]) {
    index++;
  }
  const window = 48;
  final from = index > window ? index - window : 0;
  String slice(String text) {
    final end = index + window < text.length ? index + window : text.length;
    final head = from < text.length ? text.substring(from, end) : '';
    return _escape(from > 0 ? '…$head' : head);
  }

  final buffer = StringBuffer()
    ..writeln(
      'first difference at ${index + 1} '
      '(expected ${expected.length} chars, actual ${actual.length})',
    )
    ..writeln('expected: ${slice(expected)}')
    ..writeln('actual:   ${slice(actual)}');
  return buffer.toString().trimRight();
}

/// Whitespace and non-ASCII made visible, so a tab is not an invisible bug.
String _escape(String text) => text
    .replaceAll('\t', r'\t')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r');

String _clip(String text, [int limit = 200]) {
  final flat = text.replaceAll('\n', '\u23ce');
  return flat.length <= limit ? flat : '${flat.substring(0, limit)}…';
}

void _printJson(Map<SpecSuite, List<SpecFailure>> results) {
  final payload = <String, Object?>{};
  for (final entry in results.entries) {
    final suite = entry.key;
    final failures = entry.value;
    payload[suite.name] = <String, Object?>{
      'examples': suite.examples.length,
      'exact': suite.examples.length - failures.length,
      'normalized':
          suite.examples.length - failures.where((f) => !f.normalized).length,
      'failing': failures.length,
      'failures': [
        for (final failure in failures)
          <String, Object?>{
            'example': failure.example.number,
            'section': failure.example.section,
            'formattingOnly': failure.normalized,
            if (failure.error != null) 'error': failure.error,
          },
      ],
    };
  }
  print(const JsonEncoder.withIndent(' ').convert(payload));
}

void _writeAllowlist(Map<SpecSuite, List<SpecFailure>> results) {
  final path = p.join(specFixtureDirectory, 'nonconforming.txt');
  final buffer = StringBuffer()
    ..writeln('# Examples the `markdown` package does not yet match.')
    ..writeln('#')
    ..writeln(
      '# One line per example: `<suite>/<example> <reason>`. The reason',
    )
    ..writeln('# is a placeholder until the failure is triaged into one of the')
    ..writeln('# three buckets the design document names (D2, Phase 1):')
    ..writeln('#')
    ..writeln('#   fix   the app needs this example to pass')
    ..writeln('#   pin   the package diverges on purpose or irrelevantly, and')
    ..writeln('#         the divergence is recorded rather than chased')
    ..writeln(
      '#   mask  the extension zone (wikilinks, math, frontmatter) that',
    )
    ..writeln(
      '#         the package never sees, because it is masked before it',
    )
    ..writeln('#')
    ..writeln(
      '# `flutter test` fails if an example outside this file fails, and',
    )
    ..writeln(
      '# fails again if an example inside it starts passing, so the list',
    )
    ..writeln('# cannot rot.');
  for (final entry in results.entries) {
    for (final failure in entry.value) {
      final id = '${entry.key.name}/${failure.example.number}';
      final reason = failure.error != null
          ? 'threw: ${failure.error}'
          : failure.normalized
          ? 'formatting only'
          : failure.example.section;
      buffer.writeln('$id $reason');
    }
  }
  File(path).writeAsStringSync(buffer.toString());
  print('wrote $path');
}

int? _intOption(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return int.tryParse(args[index + 1]);
}

String? _stringOption(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}
