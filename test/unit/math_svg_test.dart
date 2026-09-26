// A formula in an exported page (#24): an inline SVG from the app's own
// typesetter, without the half megabyte of fonts every drawing carries.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/math_svg.dart';

void main() {
  test('an inline formula is a sized SVG with no fonts of its own', () {
    final math = MathSvg();
    final svg = math.render(r'\sqrt{x^2+1}', display: false)!;
    expect(svg, startsWith('<svg '));
    expect(svg, isNot(contains('@font-face')));
    expect(svg, contains('class="math"'));
    expect(svg, matches(RegExp(r'style="width:[\d.]+em;height:[\d.]+em;')));
    expect(svg, contains('vertical-align:-'));
    expect(svg, contains(r'aria-label="\sqrt{x^2+1}"'));
    // Its glyphs are paths, so the page needs no fonts for it.
    expect(svg, isNot(contains('<text')));
    expect(math.fontFaces, isNull);
  });

  test('a display formula is marked as one', () {
    final svg = MathSvg().render(r'\sum_{i=0}^n i', display: true)!;
    expect(svg, contains('class="math math-display"'));
  });

  test('TeX that does not parse comes back null, for the source to show', () {
    expect(MathSvg().render(r'\frac{a}{', display: false), isNull);
  });

  test('the label escapes what an attribute cannot hold', () {
    final svg = MathSvg().render(r'a<b \& "c"', display: false);
    expect(svg, isNotNull);
    expect(svg, contains(r'aria-label="a&lt;b \&amp; &quot;c&quot;"'));
  });
}
