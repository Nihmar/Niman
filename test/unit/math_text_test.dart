// The TeX of a display block, and the size a formula is set at.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/math_text.dart';

void main() {
  test('a display block gives its TeX, fences out', () {
    expect(displayTexOf('\$\$\na = b\n\$\$'), 'a = b');
    expect(displayTexOf(r'$$x^2$$'), 'x^2');
  });

  test("a formula is set at KaTeX's size, in the text's colour", () {
    // Computer Modern at the text's own size is hairlines on a 1× screen: the
    // web sets it at 1.21em, and so does the app.
    const text = TextStyle(fontSize: 16, color: Color(0xFF123456));
    final style = mathStyleFor(text);
    expect(style.fontSize, closeTo(16 * 1.21, 1e-9));
    expect(style.color, const Color(0xFF123456));
  });
}
