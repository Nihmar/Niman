// T-M2-03: verify the pinned pure-Dart KaTeX (katex_dart ^0.1.1) renders
// the spec coverage before the math pipeline (T-M2-05) builds on it.
//
// Coverage required by the spec: matrices, aligned/cases, \text,
// \newcommand. A few core constructs are sanity-checked alongside so a
// partial break (e.g. only \newcommand failing) is visible per case.
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';

String _renderToSvg(String tex) =>
    renderToSvg(tex, options: const KatexOptions(displayMode: true));

Map<String, String> _coverage() => {
  'matrix': r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}',
  'aligned': r'\begin{aligned} x &= 1 \\ y &= 2 \end{aligned}',
  'cases': r'f(x) = \begin{cases} x & \text{if } x>0 \\ -x & \text{otherwise} \end{cases}',
  'text': r'\text{area} = \frac{1}{2} b h',
  'newcommand': r'\newcommand{\RR}{\mathbb{R}} \RR^n',
  'sanity-frac': r'\frac{a}{b}',
  'sanity-sqrt': r'\sqrt{x^2+y^2}',
  'sanity-sum': r'\sum_{i=0}^n i',
};

void main() {
  group('T-M2-03 katex_dart coverage', () {
    for (final entry in _coverage().entries) {
      test('${entry.key} renders to SVG without throwing', () {
        final svg = _renderToSvg(entry.value);
        expect(svg, contains('<svg'));
        expect(svg, isNotEmpty);
      });
    }

    test('matrix actually lays out with a real box', () {
      final box = renderToBox(
        r'\begin{pmatrix} a & b \\ c & d \end{pmatrix}',
        options: const KatexOptions(displayMode: true),
      );
      // Non-zero geometry: the matrix produced real glyph boxes, not a stub.
      expect(box.height + box.depth, greaterThan(0));
    });
  });
}
