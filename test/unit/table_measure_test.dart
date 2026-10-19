// The measure a table's cell is fitted by (#1108): one layout gives its width
// and its floor, the floor is the engine's own (styles included, breaking
// where the engine breaks), and a widget is left out and reported.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/table_measure.dart';

// The test font draws every glyph a square of its size.
const TextStyle _ten = TextStyle(fontFamily: 'Ahem', fontSize: 10);

TableCellWidths _measure(InlineSpan text) =>
    measureTableCell(text, TextScaler.noScaling);

/// A width the engine laid out, as [px] logical pixels. The engine answers
/// widths in fixed point: Linux's reads 99.99985 for Ahem's ten 10 px
/// squares, Windows' 100 exactly. A thousandth of a pixel is far under
/// anything a layout can show and far over that rounding.
Matcher _px(num px) => closeTo(px, 1e-3);

void main() {
  testWidgets('a cell is as wide as its text, its floor its widest word', (
    tester,
  ) async {
    final widths = _measure(const TextSpan(text: 'ab cdef gh', style: _ten));
    expect(widths.natural, _px(100));
    expect(widths.least, _px(40));
    expect(widths.widget, isFalse);
  });

  testWidgets('a styled word is measured in its style', (tester) async {
    // "ab" is set at twice the size: a floor measured from the plain text in
    // the base style read 20, and the word broke in the middle.
    final widths = _measure(
      const TextSpan(
        style: _ten,
        children: [
          TextSpan(
            text: 'ab',
            style: TextStyle(fontFamily: 'Ahem', fontSize: 20),
          ),
          TextSpan(text: ' cd'),
        ],
      ),
    );
    expect(widths.least, _px(40));
    expect(widths.natural, _px(40 + 10 + 20));
  });

  testWidgets('a run of styles with no space is one word', (tester) async {
    final widths = _measure(
      const TextSpan(
        style: _ten,
        children: [
          TextSpan(
            text: 'abc',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: 'def'),
          TextSpan(text: ' gh'),
        ],
      ),
    );
    expect(widths.least, _px(60));
  });

  testWidgets('a no-break space does not end a word', (tester) async {
    // Flutter does not break at it, so the floor has to keep it whole.
    final widths = _measure(const TextSpan(text: 'ab cd ef', style: _ten));
    expect(widths.least, _px(50));
    expect(widths.natural, _px(80));
  });

  testWidgets('a text with no place to break is its own floor', (tester) async {
    final widths = _measure(const TextSpan(text: 'abcdefghij', style: _ten));
    expect(widths.least, widths.natural);
  });

  testWidgets('an empty cell asks for nothing', (tester) async {
    final widths = _measure(const TextSpan(text: '', style: _ten));
    expect(widths.natural, _px(0));
    expect(widths.least, _px(0));
  });

  testWidgets('a widget is left out of the text and reported', (tester) async {
    final widths = _measure(
      const TextSpan(
        style: _ten,
        children: [
          TextSpan(text: 'ab '),
          WidgetSpan(child: SizedBox(width: 99, height: 10)),
          TextSpan(text: ' cd'),
        ],
      ),
    );
    expect(widths.widget, isTrue);
    expect(widths.natural, _px(60));
    expect(widths.least, _px(20));
  });
}
