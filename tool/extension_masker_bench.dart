/// Measures the extension masker, and checks the number the design document
/// claims for it.
///
/// The claim (`docs/dev/unified-surface.md` §8.5.0): `Geometria 1.md` has
/// thousands of `_` delimiter runs of which only a handful are real emphasis,
/// once its math is masked — which is why masking is a correctness requirement
/// and not an optimisation. This prints both counts.
///
/// ```sh
/// dart run tool/extension_masker_bench.dart
/// dart run tool/extension_masker_bench.dart "Geometria 1.md"
/// ```
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:path/path.dart' as p;

/// The fixtures to measure, when no paths are given.
const List<String> _defaults = <String>[
  'test/fixtures/markdown/fixture-200kb.md',
  'test/fixtures/markdown/fixture-1mb.md',
];

/// The real worst case, measured when it is present.
const String _worstCase = 'Geometria 1.md';

const ExtensionMasker _masker = ExtensionMasker();

void main(List<String> args) {
  final paths = args.isNotEmpty
      ? args
      : <String>[..._defaults, if (File(_worstCase).existsSync()) _worstCase];

  print('# extension masking, debug mode');
  print('');
  print(
    '| fixture | blocks | spans | math | wikilink | embed | tag | code | '
    '`_` runs before | after |',
  );
  print('|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      print('| ${p.basename(path)} | — | — | missing | | | | | | |');
      continue;
    }
    final buffer = SourceBuffer.fromText(file.readAsStringSync());
    final scanner = BlockScanner(buffer);
    final counts = <ExtensionKind, int>{};
    var before = 0;
    var after = 0;
    var spans = 0;
    final watch = Stopwatch()..start();
    for (final block in scanner.index.blocks) {
      // A block that *is* code, math or frontmatter has no inline content to
      // mask: the block layer never hands those to the inline phase.
      if (_isWholeBlock(block.kind)) continue;
      final text = _blockText(buffer, block);
      before += _underscoreRuns(text);
      final masked = _masker.mask(text);
      after += _underscoreRuns(masked.text);
      spans += masked.spans.length;
      for (final span in masked.spans) {
        counts[span.kind] = (counts[span.kind] ?? 0) + 1;
      }
    }
    watch.stop();

    print(
      '| ${p.basename(path)} | ${scanner.index.blocks.length} | $spans | '
      '${counts[ExtensionKind.inlineMath] ?? 0} | '
      '${counts[ExtensionKind.wikilink] ?? 0} | '
      '${counts[ExtensionKind.embed] ?? 0} | '
      '${counts[ExtensionKind.tag] ?? 0} | '
      '${counts[ExtensionKind.codeSpan] ?? 0} | '
      '$before | **$after** |',
    );
    print('');
    print(
      '  ${p.basename(path)}: masked in '
      '${(watch.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms',
    );
  }

  print('');
  print('`_` runs before and after: the emphasis algorithm the package runs');
  print('sees the first number; masking leaves it the second.');
}

/// Whether a block is one the inline phase never sees.
bool _isWholeBlock(BlockKind kind) =>
    kind == BlockKind.fencedCode ||
    kind == BlockKind.indentedCode ||
    kind == BlockKind.math ||
    kind == BlockKind.frontmatter ||
    kind == BlockKind.blank;

/// The block's text, lines joined with `\n`.
String _blockText(SourceBuffer buffer, Block block) {
  final parts = <String>[];
  for (var line = block.startLine; line < block.endLine; line++) {
    parts.add(buffer.lineAt(line));
  }
  return parts.join('\n');
}

/// How many runs of one or more `_` the text has.
int _underscoreRuns(String text) {
  var runs = 0;
  var inRun = false;
  for (var at = 0; at < text.length; at++) {
    final underscore = text.codeUnitAt(at) == 0x5F;
    if (underscore && !inRun) runs++;
    inRun = underscore;
  }
  return runs;
}
