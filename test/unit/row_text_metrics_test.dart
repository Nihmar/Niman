import 'package:copist/src/editor/row_text_metrics.dart';
import 'package:copist/src/editor/virtualized_text_view.dart';
import 'package:flutter_test/flutter_test.dart';

RowTextMetrics get _metrics =>
    const RowTextMetrics(style: VirtualizedTextView.rowTextStyle);

void main() {
  test('caret x round-trips through column mapping (ascii)', () {
    const text = 'hello world';
    for (var col = 0; col <= text.length; col++) {
      final x = _metrics.caretX(text, col);
      expect(_metrics.columnForX(text, x, text.length), col);
    }
  });

  test('caret x round-trips over fallback glyphs', () {
    // A narrow no-break space (prose carries U+202F): the painter, not the
    // grid, decides its advance — the M2a round-4 R2 second-order suspect.
    const text = 'a b c';
    for (var col = 0; col <= text.length; col++) {
      final x = _metrics.caretX(text, col);
      expect(_metrics.columnForX(text, x, text.length), col);
    }
  });

  test('caret x starts at zero and grows monotonically', () {
    const text = 'abcd';
    expect(_metrics.caretX(text, 0), 0);
    var prev = 0.0;
    for (var col = 1; col <= text.length; col++) {
      final x = _metrics.caretX(text, col);
      expect(x, greaterThan(prev));
      prev = x;
    }
  });

  test('columns and carets clamp to the row', () {
    expect(_metrics.columnForX('', 100, 0), 0);
    expect(_metrics.columnForX('ab', -50, 2), 0);
    expect(_metrics.columnForX('ab', 1000, 2), 2);
    expect(
      _metrics.caretX('ab', 99),
      _metrics.caretX('ab', 2),
    );
  });

  test('taps just past a long row end land past its last char', () {
    // The on-device "cursor behind the last char of long rows": a tap past
    // the row's end must resolve to the caret after the last char, not the
    // last character itself.
    const text =
        'cjjdjddjdjdjjdjdjdjdjdjdjdjjdjdjdjd';
    final endX = _metrics.caretX(text, text.length);
    final charW = _metrics.caretX(text, 1) - _metrics.caretX(text, 0);
    expect(_metrics.columnForX(text, endX, text.length), text.length);
    expect(
      _metrics.columnForX(text, endX + charW * 0.25, text.length),
      text.length,
    );
    expect(
      _metrics.columnForX(text, endX + charW * 5, text.length),
      text.length,
    );
  });

  test('mid-glyph taps round to the nearest caret (ties up)', () {
    const text = 'abcd';
    final charW = _metrics.caretX(text, 1) - _metrics.caretX(text, 0);
    for (var col = 0; col < text.length; col++) {
      final left = _metrics.caretX(text, col);
      expect(
        _metrics.columnForX(text, left + charW * 0.25, text.length),
        col,
      );
      expect(
        _metrics.columnForX(text, left + charW * 0.75, text.length),
        col + 1,
      );
      // An exact middle rounds up, like (x / charWidth).round().
      expect(
        _metrics.columnForX(text, left + charW * 0.5, text.length),
        col + 1,
      );
    }
  });
}
