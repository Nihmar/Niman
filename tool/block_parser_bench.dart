/// Measures the inline phase: what it costs to parse blocks, and what the
/// cache saves.
///
/// The parse is split where the measurements say
/// (`docs/records/unified-surface.md` §8.5): the block scan is 14 ms on the
/// geometry note and the inline phase is 378 ms for the same document, so the
/// inline half is done **per visible block** and kept while it is still true.
/// This prints both numbers, and the third one that matters — what a document
/// costs when only a viewport's worth of blocks is parsed.
///
/// ```sh
/// dart run tool/block_parser_bench.dart
/// dart run tool/block_parser_bench.dart "Geometria 1.md"
/// ```
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:path/path.dart' as p;

/// The fixtures to measure, when no paths are given.
const List<String> _defaults = <String>[
  'test/fixtures/spec/worst-note.md',
  'test/fixtures/markdown/fixture-200kb.md',
];

/// The real worst case, measured when it is present.
const String _worstCase = 'Geometria 1.md';

/// Roughly what a viewport shows, and one viewport of cache either side.
const int _viewportBlocks = 40;
const int _cachedBlocks = 120;

void main(List<String> args) {
  final paths = args.isNotEmpty
      ? args
      : <String>[..._defaults, if (File(_worstCase).existsSync()) _worstCase];

  print('# inline phase, debug mode: ratios carry, absolutes do not');
  print('');
  print(
    '| fixture | blocks | inline blocks | all | cache misses | '
    'viewport ($_viewportBlocks) | cache ($_cachedBlocks) |',
  );
  print('|---|---:|---:|---:|---:|---:|---:|');

  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) {
      print('| ${p.basename(path)} | — | — | missing | | | |');
      continue;
    }
    final buffer = SourceBuffer.fromText(file.readAsStringSync());
    final scanner = BlockScanner(buffer);
    final blocks = scanner.index.blocks;

    // Which blocks have inline content at all: a fence or a math block is
    // drawn from the block, not parsed.
    final inlineBlocks = <int>[];
    for (var at = 0; at < blocks.length; at++) {
      final probe = BlockParser().parse(blocks[at], buffer);
      if (probe.runs.isNotEmpty || probe.masked.isMasked) inlineBlocks.add(at);
    }

    final parser = BlockParser();
    final all = _time(() {
      for (final at in inlineBlocks) {
        parser.of(blocks[at], buffer);
      }
    });
    final misses = parser.parseCount;

    final viewport = _time(() {
      for (var at = 0; at < _viewportBlocks && at < inlineBlocks.length; at++) {
        BlockParser().parse(blocks[inlineBlocks[at]], buffer);
      }
    });
    final cached = _time(() {
      for (var at = 0; at < _cachedBlocks && at < inlineBlocks.length; at++) {
        BlockParser().parse(blocks[inlineBlocks[at]], buffer);
      }
    });

    print(
      '| ${p.basename(path)} | ${blocks.length} | ${inlineBlocks.length} | '
      '${_millis(all)} | $misses | ${_millis(viewport)} | ${_millis(cached)} |',
    );
  }

  print('');
  print('`all` parses every block with inline content, once, through the');
  print('cache. `viewport` and `cache` parse the first $_viewportBlocks and');
  print('$_cachedBlocks of them with a fresh parser, which is what scrolling');
  print('a note costs in a cache miss. The two are the difference between a');
  print('document-shaped cost and a screen-shaped one.');
}

/// The time one run takes, in microseconds.
double _time(void Function() body) {
  final watch = Stopwatch()..start();
  body();
  watch.stop();
  return watch.elapsedMicroseconds.toDouble();
}

String _millis(double micros) => '${(micros / 1000).toStringAsFixed(2)} ms';
