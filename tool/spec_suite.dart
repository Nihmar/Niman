/// The Markdown conformance suites, loaded from their committed fixtures.
///
/// Two suites, and they are not the same artefact:
///
/// * **CommonMark 0.31.2**, from <https://spec.commonmark.org/0.31.2/spec.json>
///   — 652 examples in 26 sections, the canonical JSON.
/// * **GFM 0.29-gfm**, from the published <https://github.github.com/gfm/>
///   HTML — 677 examples in 31 sections. GitHub serves no `spec.json` (the URL
///   404s), so the examples are extracted from the page by
///   `tool/extract_gfm_spec.py` and committed. Note that cmark-gfm's
///   `test/spec.txt` is a *different* suite of 672 examples; the published HTML
///   is what "0.29-gfm" means to a reader, so it is the one pinned here.
///
/// The GFM suite is a superset of the CommonMark one in intent, and its
/// examples are the same shape on purpose, so one runner covers both.
library;

import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

/// One spec example: a Markdown input and the HTML it must produce.
final class SpecExample {
  /// Creates an example.
  const new({
    required this.number,
    required this.section,
    required this.markdown,
    required this.html,
  });

  /// The example's number, contiguous within its suite.
  final int number;

  /// The section it belongs to, as the spec names it ("4.6 HTML blocks").
  final String section;

  /// The Markdown source.
  final String markdown;

  /// The expected HTML.
  final String html;
}

/// A named suite of examples, with the `markdown` extension set it is run with.
final class SpecSuite {
  /// Creates a suite.
  const new({
    required this.name,
    required this.examples,
    required this.extensions,
  });

  /// The suite's identifier, `spec/version` ("gfm/0.29-gfm").
  final String name;

  /// Its examples.
  final List<SpecExample> examples;

  /// The extension set the `markdown` package is run with.
  final md.ExtensionSet extensions;

  /// The test name for an example: `spec/version/007 @2.2 Tabs`, so a failure
  /// names the suite, the example and its section at once.
  String testNameFor(SpecExample example) =>
      '$name/${example.number.toString().padLeft(3, '0')} '
      '@${example.section}';
}

/// The CommonMark suite's identifier.
const String commonMarkSuiteName = 'commonmark/0.31.2';

/// The GFM suite's identifier.
const String gfmSuiteName = 'gfm/0.29-gfm';

/// Where the fixtures live, relative to the package root.
final String specFixtureDirectory = p.join('test', 'fixtures', 'spec');

/// Loads both suites from their committed fixtures.
List<SpecSuite> loadSpecSuites() => <SpecSuite>[
  _load(
    name: commonMarkSuiteName,
    file: 'commonmark-0.31.2.json',
    extensions: md.ExtensionSet.commonMark,
  ),
  _load(
    name: gfmSuiteName,
    file: 'gfm-0.29-gfm.json',
    extensions: md.ExtensionSet.gitHubFlavored,
  ),
];

SpecSuite _load({
  required String name,
  required String file,
  required md.ExtensionSet extensions,
}) {
  final path = p.join(specFixtureDirectory, file);
  final raw = File(path).readAsStringSync();
  final decoded = jsonDecode(raw) as List<dynamic>;
  final examples = <SpecExample>[];
  for (final entry in decoded) {
    final map = entry as Map<String, dynamic>;
    examples.add(
      SpecExample(
        number: map['example'] as int,
        section: map['section'] as String? ?? 'unknown',
        markdown: map['markdown'] as String,
        html: map['html'] as String,
      ),
    );
  }
  return SpecSuite(name: name, examples: examples, extensions: extensions);
}

/// The `markdown` package's HTML for [example], against its suite's extensions.
String renderExample(SpecSuite suite, SpecExample example) =>
    md.markdownToHtml(example.markdown, extensionSet: suite.extensions);
