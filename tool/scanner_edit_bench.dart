/// Measures what one edit costs the block scanner, and why.
///
/// The claim it checks is the one `docs/dev/huge-notes.md` records (item 3):
/// a keystroke's cost is the *block* it landed in, not the note — unless the
/// block is the note, which a `$$…$$` block at the head or a run of prose
/// without a blank line can be. It prints the lines re-scanned and the block
/// the edit landed in, which is what says whether a number is the block or
/// the document.
///
/// It prints rather than asserts, as the repo's benchmarks do, and JIT
/// inflates the absolutes — the shape carries.
///
/// ```sh
/// dart run tool/scanner_edit_bench.dart
/// dart run tool/scanner_edit_bench.dart "Quicknote.md"
/// ```
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    await _real(args.first);
    return;
  }
  _synthetic();
}

/// The shapes a note's blocks have, and what an edit costs in each.
void _synthetic() {
  _shape('prose, one paragraph', 300000, (i) => 'prose line $i');
  _shape(
    'prose with blank lines between',
    400000,
    (i) => i.isEven ? 'prose line $i' : '',
  );
  _shape('one 200 000-line math block', 200000, (i) {
    if (i == 0) return r'$$';
    if (i == 199999) return r'$$';
    return 'x_$i = $i';
  });
}

void _shape(String label, int lines, String Function(int) line) {
  final buffer = SourceBuffer.fromText(
    List<String>.generate(lines, line).join('\n'),
  );
  final scanner = BlockScanner(buffer);
  final blocks = scanner.index.blocks;
  var longest = blocks.first;
  for (final block in blocks) {
    if (block.lineCount > longest.lineCount) longest = block;
  }
  print(
    '$label: ${buffer.lineCount} lines, ${blocks.length} blocks, '
    'longest ${longest.kind.name} ${longest.lineCount} lines',
  );
  for (final at in [0.1, 0.5, 0.9]) {
    final line = (buffer.lineCount * at).toInt();
    final offset = buffer.offsetOfLine(line);
    final holder = blocks.firstWhere(
      (block) => block.startLine <= line && line < block.endLine,
    );
    final before = scanner.scannedLineTotal;
    final edit = buffer.replaceRange(offset, offset + 1, 'X');
    final clock = Stopwatch()..start();
    scanner.edited(edit);
    print(
      '  edit at ${(at * 100).toInt()}%: ${clock.elapsedMilliseconds}ms, '
      '${scanner.scannedLineTotal - before} lines re-scanned '
      '(the edit is in ${holder.kind.name} ${holder.startLine}..'
      '${holder.endLine}, ${holder.lineCount} lines)',
    );
  }
}

/// The same, on a real note: the blocks are the note's own.
Future<void> _real(String path) async {
  final raw = await File(path).readAsString();
  final buffer = SourceBuffer.fromText(
    raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
  );
  final scan = Stopwatch()..start();
  final blocks = BlockScanner(buffer).index.blocks;
  final kinds = <String, int>{};
  var longest = blocks.isEmpty ? null : blocks.first;
  for (final block in blocks) {
    kinds[block.kind.name] = (kinds[block.kind.name] ?? 0) + 1;
    if (longest != null && block.lineCount > longest.lineCount) {
      longest = block;
    }
  }
  print(
    '$path: ${buffer.lineCount} lines, ${blocks.length} blocks '
    'in ${scan.elapsedMilliseconds}ms',
  );
  print('  kinds: $kinds');
  if (longest != null) {
    print(
      '  longest block: ${longest.kind.name} '
      '${longest.startLine}..${longest.endLine} (${longest.lineCount} lines)',
    );
  }
  for (final at in [0.1, 0.25, 0.5, 0.75, 0.9]) {
    final line = (buffer.lineCount * at).toInt();
    final offset = buffer.offsetOfLine(line);
    final holder = blocks.firstWhere(
      (block) => block.startLine <= line && line < block.endLine,
    );
    final scanner = BlockScanner(buffer)..index;
    final before = scanner.scannedLineTotal;
    final edit = buffer.replaceRange(offset, offset + 1, 'X');
    final clock = Stopwatch()..start();
    scanner.edited(edit);
    print(
      '  edit at ${(at * 100).toInt()}%: ${clock.elapsedMilliseconds}ms, '
      '${scanner.scannedLineTotal - before} lines re-scanned '
      '(${holder.kind.name} ${holder.startLine}..${holder.endLine})',
    );
  }
}
