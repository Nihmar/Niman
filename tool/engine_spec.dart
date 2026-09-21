/// Measures what the *engine* produces on the conformance suites, as opposed to
/// what the package produces on them.
///
/// The conformance gate in `test/unit/markdown_conformance_test.dart` measures
/// `markdownToHtml(example)` — the package, whole-document. That is the right
/// number for "is the parser conformant", and the wrong one for "what will the
/// app show", because the engine does three things the package does not: it
/// splits the document into blocks itself, it masks each block's own
/// constructs before parsing it, and it parses **per block** rather than whole.
///
/// This runs the same suites through the engine's recipe — block scan, mask,
/// parse each block, concatenate — and reports how many examples come out
/// byte-identical to the package's own answer, and where they differ, split by
/// whether the example contains a construct the engine masks. A difference in
/// the first group is a bug in the engine; a difference in the second is the
/// engine doing its job, and the count is the size of the engine's own suite.
///
/// ```sh
/// dart run tool/engine_spec.dart
/// dart run tool/engine_spec.dart --failures 20
/// ```
library;

// A tool's whole output is its report.
// ignore_for_file: avoid_print

import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/source_buffer.dart';

import 'html_normalize.dart';
import 'spec_suite.dart';

void main(List<String> args) {
  final showFailures = _intOption(args, '--failures') ?? 0;
  for (final suite in loadSpecSuites()) {
    var blocks = 0;
    var plainBlocks = 0;
    var plainSame = 0;
    var maskedBlocks = 0;
    var maskedSame = 0;
    final wildDifferences = <String>[];
    final documentSame = <String>[];

    for (final example in suite.examples) {
      final buffer = SourceBuffer.fromText(example.markdown);
      final scanner = BlockScanner(buffer);
      const masker = ExtensionMasker();
      final whole = StringBuffer();
      final wholeReference = StringBuffer();
      for (final block in scanner.index.blocks) {
        final text = BlockParser.blockText(block, buffer);
        final masked = masker.mask(text);
        // The reference is the package's own answer for the *same block*, so
        // the block granularity is held constant and only the masking varies.
        final reference = md.renderToHtml(
          md.Document(extensionSet: suite.extensions)
              .parseLines(text.split('\n')),
        );
        final engine = md.renderToHtml(
          md.Document(extensionSet: suite.extensions)
              .parseLines(masked.text.split('\n')),
        );
        whole.write(engine);
        wholeReference.write(reference);
        final same = normalizeHtml(engine) == normalizeHtml(reference);
        blocks++;
        if (masked.isMasked) {
          maskedBlocks++;
          if (same) maskedSame++;
        } else {
          plainBlocks++;
          if (same) {
            plainSame++;
          } else if (wildDifferences.length < showFailures) {
            wildDifferences.add(
              '${suite.name}/${example.number} @${example.section} '
              '${block.kind.name} ${block.startLine}..${block.endLine} '
              '"${text.length > 60 ? '${text.substring(0, 60)}…' : text}"',
            );
          }
        }
      }
      if (normalizeHtml(whole.toString()) ==
          normalizeHtml(wholeReference.toString())) {
        documentSame.add('${suite.name}/${example.number}');
      }
    }

    print('## ${suite.name}');
    print('');
    print('| | blocks | identical to the package on the same block | differ |');
    print('|---|---:|---:|---:|');
    print(
      '| block with nothing to mask | $plainBlocks | $plainSame | '
      '${plainBlocks - plainSame} |',
    );
    print(
      '| block with something masked | $maskedBlocks | $maskedSame | '
      '${maskedBlocks - maskedSame} |',
    );
    print(
      '| **total** | $blocks | ${plainSame + maskedSame} | '
      '${blocks - plainSame - maskedSame} |',
    );
    print('');
    print(
      'Whole documents identical after concatenation: '
      '${documentSame.length} of ${suite.examples.length}.',
    );
    print('');
    if (wildDifferences.isNotEmpty) {
      print('### blocks that differ without being masked');
      print('');
      for (final line in wildDifferences) {
        print('- $line');
      }
      print('');
    }
  }
}

int? _intOption(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) return null;
  return int.tryParse(args[index + 1]);
}
