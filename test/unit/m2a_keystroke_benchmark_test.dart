// E9 keystroke benchmark (M2a): apply N single-character deltas to
// 1K / 10K / 100K-line buffers and record the per-keystroke cost of the
// edit path (ComposingInput.apply + RowModel.sync — what the editor's
// _onChange runs before a frame).
// The whole point of this file is to print timings into the test log.
// ignore_for_file: avoid_print
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const int _columns = 80;

void main() {
  test('E9 keystroke benchmark: single-char insert at end of buffer', () {
    final summary = <String>[];
    for (final lines in const [1000, 10000, 100000]) {
      final text = List.generate(lines, (i) => 'line $i').join('\n');
      final input = ComposingInput(text);
      final rows = RowModel(input.buffer, columns: _columns);
      var offset = input.textLength;

      // One keystroke: a single-character insertion at [offset] plus the
      // row sync the editor runs on every change.
      void keystroke() {
        input.apply(TextEditingDeltaInsertion(
          oldText: input.text,
          textInserted: 'x',
          insertionOffset: offset,
          selection: TextSelection.collapsed(offset: offset + 1),
          composing: TextRange(start: offset, end: offset + 1),
        ));
        offset += 1;
        rows.sync();
      }

      // Warmup (JIT + allocation churn), not measured.
      for (var i = 0; i < 10; i++) {
        keystroke();
      }

      const n = 50;
      var maxUs = 0;
      final clock = Stopwatch()..start();
      for (var i = 0; i < n; i++) {
        final k = Stopwatch()..start();
        keystroke();
        if (k.elapsedMicroseconds > maxUs) maxUs = k.elapsedMicroseconds;
      }
      final totalUs = clock.elapsedMicroseconds;
      final avg = totalUs / n;
      final mb = text.length / 1e6;

      print(
        '${lines.toString().padRight(6)} lines (~${mb.toStringAsFixed(1)} MB): '
        'avg ${(avg / 1000).toStringAsFixed(3)} ms, '
        'max ${(maxUs / 1000).toStringAsFixed(3)} ms / keystroke',
      );
      summary.add(
        '$lines lines (~${mb.toStringAsFixed(1)} MB): '
        'avg ${(avg / 1000).toStringAsFixed(3)} ms, '
        'max ${(maxUs / 1000).toStringAsFixed(3)} ms',
      );

      // Sanity gate only (not a perf target): a single keystroke must
      // never take a full second.
      expect(
        maxUs,
        lessThan(1000 * 1000),
        reason: 'keystroke on a $lines-line buffer took > 1 s',
      );
    }
    print('E9 keystroke benchmark: ${summary.join(' | ')}');
  });
}
