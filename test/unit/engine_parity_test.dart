// The engine's own gate, next to the package's conformance one.
//
// `markdown_conformance_test.dart` measures `markdownToHtml(example)` — the
// package, whole-document. That is the right number for "is the parser
// conformant" and the wrong one for "what will the app show", because the
// engine splits the document into blocks itself, masks each block before
// parsing it, and parses per block.
//
// This file measures the property that makes the package's conformance
// *inherited*: on every block the engine does not mask, the engine's parse of
// that block is byte-identical to the package's parse of the same block. If
// that holds everywhere, the engine's block decomposition and its per-block
// parse add nothing and lose nothing — the number the conformance gate reports
// is the app's, wherever the app does not intervene.
//
// Where the engine *does* mask, its answer differs by design: those constructs
// are the app's own, and the renderer draws them from the spans rather than
// from the parser's text.
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/parsed_block.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';

import '../../tool/html_normalize.dart';
import '../../tool/spec_suite.dart';

/// The engine's answer for one block: mask it, parse it, render it.
String _engineHtml(String text, md.ExtensionSet extensions) {
  const masker = ExtensionMasker();
  final masked = masker.mask(text);
  return md.renderToHtml(
    md.Document(extensionSet: extensions).parseLines(masked.text.split('\n')),
  );
}

/// The package's answer for the same block, unmasked.
String _packageHtml(String text, md.ExtensionSet extensions) => md.renderToHtml(
  md.Document(extensionSet: extensions).parseLines(text.split('\n')),
);

void main() {
  for (final suite in loadSpecSuites()) {
    test("${suite.name}: an unmasked block is the package's own answer", () {
      var checked = 0;
      final wild = <String>[];
      for (final example in suite.examples) {
        final buffer = SourceBuffer.fromText(example.markdown);
        final scanner = BlockScanner(buffer);
        const masker = ExtensionMasker();
        for (final block in scanner.index.blocks) {
          final text = BlockParser.blockText(block, buffer);
          if (masker.mask(text).isMasked) continue;
          checked++;
          if (normalizeHtml(_engineHtml(text, suite.extensions)) !=
              normalizeHtml(_packageHtml(text, suite.extensions))) {
            wild.add(
              '${suite.name}/${example.number} ${block.kind.name} "$text"',
            );
          }
        }
      }
      expect(checked, greaterThan(1500), reason: 'the suites have blocks');
      expect(wild, isEmpty, reason: 'the engine altered $wild');
    });
  }

  group('a link reference definition leaves the engine nothing to show', () {
    // CM 207 / GFM 176 / GFM 188 are pinned because the package's *HTML* for a
    // lone definition is whitespace while the spec asks for nothing. The app
    // draws runs, not that HTML, and the engine's runs for the block are empty
    // — so the app is right where the HTML comparison is not.
    test('the runs are empty', () {
      for (final source in <String>[
        '[foo]: /url',
        '[foo]: /url\n',
        '  [foo]: /url',
      ]) {
        final buffer = SourceBuffer.fromText(source);
        final scanner = BlockScanner(buffer);
        final parser = BlockParser();
        for (final block in scanner.index.blocks) {
          final parsed = parser.parse(block, buffer);
          expect(parsed.runs, isEmpty, reason: source);
        }
      }
    });
  });

  group('a scheme the parser left behind is joined back', () {
    test('mailto:', () {
      final parsed = _parse('mailto:foo@bar.baz');
      expect(parsed.runs, hasLength(1));
      final run = parsed.runs.single;
      expect(run.kind, StyleKind.link);
      expect(parsed.text.substring(run.start, run.end), 'mailto:foo@bar.baz');
      expect(run.href, 'mailto:foo@bar.baz');
    });

    test('a scheme in prose is not a link', () {
      final parsed = _parse('see note:something here');
      expect(parsed.runs.every((run) => run.kind == StyleKind.plain), isTrue);
    });
  });
}

/// Parses the first block of [document].
ParsedBlock _parse(String document) {
  final buffer = SourceBuffer.fromText(document);
  final scanner = BlockScanner(buffer);
  return BlockParser().parse(scanner.index.blocks.first, buffer);
}
