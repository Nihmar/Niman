// CommonMark conformance (T-M2-04): the preview parses with the `markdown`
// package (gitHubFlavored extension set, exactly what MarkdownPreview
// uses). spec.json is the official 652-example CommonMark corpus; each
// example's Markdown is rendered to HTML and compared with the expected
// HTML under the upstream test-harness normalization (trim trailing
// whitespace per line, ignore trailing blank lines).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

String _normalize(String html) {
  final lines = html.split('\n').map((l) => l.trimRight()).toList();
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}

void main() {
  test('spec.json passes at or above the CommonMark floor (GFM mode)', () {
    final examples = (jsonDecode(
      File('test/spec.json').readAsStringSync(),
    ) as List<dynamic>).cast<Map<String, dynamic>>();
    expect(examples.length, 652);

    final failures = <String>[];
    for (final example in examples) {
      final markdown = example['markdown'] as String;
      final expected = example['html'] as String;
      final actual = md.markdownToHtml(
        markdown,
        extensionSet: md.ExtensionSet.gitHubFlavored,
      );
      if (_normalize(actual) != _normalize(expected)) {
        failures.add(
          '#${example['example']} (${example['section']})',
        );
      }
    }

    final passed = examples.length - failures.length;
    // Measured: 639/652 with the GFM set (98.0%); pure commonMark mode is
    // 642 (GFM intentionally loses the 3 bare-URL/email autolink examples
    // to CommonMark — those are GFM extensions the preview wants). The
    // remaining ~10 misses are the markdown package's known edge gaps
    // (tabs in indented code, a few named entities, setext after leading
    // spaces, fence-info edge cases, €-emphasis boundaries, multiline HTML
    // comments). Below the floor something regressed (a parser option or a
    // package upgrade).
    expect(
      passed,
      greaterThanOrEqualTo(639),
      reason: 'CommonMark: $passed/${examples.length} '
          '(${failures.take(10).join(', ')}'
          '${failures.length > 10 ? ', ...' : ''})',
    );
    // The measured number is logged (read from the test log).
    // ignore: avoid_print
    print('CommonMark (GFM): $passed/${examples.length} '
        '(${(passed * 100 / examples.length).toStringAsFixed(1)}%)');
  });
}
