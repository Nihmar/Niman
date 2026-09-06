// E9 keystroke benchmark (M2a): apply N single-character deltas to
// 1K / 10K / 100K-line buffers and record the per-keystroke cost of the
// *real* edit path since the M2a fix P2:
// - the delta's oldText is the platform's window copy (KB, not the full
//   buffer) — modeled by ImeWindow.around, which also bounds the honest
//   Dart-side cost of the platform holding the copy;
// - ComposingInput.apply with the window anchor (O(word) + O(1));
// - the client's per-keystroke re-center check (ImeWindow.around, O(window
//   lines));
// - RowModel.sync (O(lines), the fold).
// No 931 KB join is on the path anymore: onTextChanged passes the buffer
// revision (P1) and the IME push is KB-sized and only on re-center (P2).
// The whole point of this file is to print timings into the test log.
// ignore_for_file: avoid_print
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/ime_bridge.dart';
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
      // One keystroke at the buffer end, windowed (M2a fix P2): the
      // platform's copy is the caret's window (KB), the delta's offsets are
      // window-local, and the client re-checks the window after apply.
      void keystroke() {
        final window = ImeWindow.around(input);
        final local = window.windowText.length; // the caret is at the end
        input.apply(
          TextEditingDeltaInsertion(
            oldText: window.windowText,
            textInserted: 'x',
            insertionOffset: local,
            selection: TextSelection.collapsed(offset: local + 1),
            composing: TextRange(start: local, end: local + 1),
          ),
          anchor: window.windowStart,
        );
        ImeWindow.around(input); // the client's re-center check
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
        'max ${(maxUs / 1000).toStringAsFixed(3)} ms / keystroke '
        '(real path: windowed apply + re-center check + sync, M2a fix P2)',
      );
      summary.add(
        '$lines lines (~${mb.toStringAsFixed(1)} MB): '
        'avg ${(avg / 1000).toStringAsFixed(3)} ms, '
        'max ${(maxUs / 1000).toStringAsFixed(3)} ms',
      );

      // The per-keystroke budget at Geometria scale (the 931 KB / 100K-line
      // note): with the O(n) joins out of the path (M2a fix P1) a keystroke
      // has 8 ms (half a frame) — typing must never stall on a big note.
      expect(
        avg,
        lessThan(8 * 1000),
        reason: 'real-path keystroke on a $lines-line buffer averaged > 8 ms',
      );
    }
    print('E9 keystroke benchmark: ${summary.join(' | ')}');
  });
}
