/// The one entry point for the engine's benchmarks.
///
/// Each measurement lives in its own tool, so it can be read and changed on its
/// own; this runs them in order and prints one report, which is what a
/// regression check wants:
///
/// ```sh
/// dart run tool/bench.dart                       # the fixtures
/// dart run tool/bench.dart "Geometria 1.md"      # the real worst case
/// ```
///
/// Debug mode, as the repo's benchmarks are: the absolute numbers are inflated
/// and the ratios are the part that carries. The results are recorded in
/// `docs/dev/unified-surface.md` — §8.2 for the buffer, §8.5 for the block scan
/// and §8.5.5 for the inline phase.
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

/// The measurements, in the order the parse happens.
const List<String> _tools = <String>[
  'tool/source_buffer_bench.dart',
  'tool/block_scanner_bench.dart',
  'tool/extension_masker_bench.dart',
  'tool/block_parser_bench.dart',
];

Future<void> main(List<String> args) async {
  for (final tool in _tools) {
    final result = await Process.run(Platform.resolvedExecutable, <String>[
      'run',
      tool,
      ...args,
    ], workingDirectory: Directory.current.path);
    stdout
      ..write(result.stdout)
      ..write(result.stderr);
    if (result.exitCode != 0) {
      stderr.writeln('$tool exited ${result.exitCode}');
      exit(result.exitCode);
    }
  }
  print('all four benches ran over:');
  for (final path in args) {
    print('  $path');
  }
}
