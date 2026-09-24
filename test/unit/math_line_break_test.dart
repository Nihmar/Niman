// Breaking a display formula across lines when the pane is too narrow for it
// (#257). The property that matters is not "it broke" but "it broke without
// losing or duplicating a single glyph, and every line fits".
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/preview/math_line_break.dart';

/// Every glyph of [box], in reading order, as text.
///
/// The whole point of a break is that this reads the same before and after it.
String _glyphs(BoxNode box) {
  final out = StringBuffer();
  void walk(BoxNode node) {
    switch (node) {
      case GlyphNode():
        out.writeCharCode(node.codepoint);
      case HBox(:final children):
        children.forEach(walk);
      case SpanNode(:final children):
        children.forEach(walk);
      case VList(:final children):
        for (final child in children) {
          final elem = child.elem;
          if (elem != null) walk(elem);
        }
      case _:
        break;
    }
  }

  walk(box);
  return out.toString();
}

BoxNode _box(String tex) =>
    renderToBox(tex, options: const KatexOptions(displayMode: true));

/// The text of a formula that fits a phone pane's 368 pixels at 15 px.
const double _phoneEm = (368 - 2 * 0.08 * 15) / 15;

void main() {
  test('a formula that fits is left alone', () {
    final box = _box('x^2 + y^2 = z^2');
    final lines = breakDisplayMath(box, maxEm: _phoneEm);
    expect(lines, hasLength(1));
    expect(identical(lines.single, box), isTrue, reason: 'not rebuilt');
  });

  test('a wide formula breaks, and no glyph is lost or repeated', () {
    const tex =
        '2(x_1 + x_2) - 3(y_1 + y_2) + (z_1 + z_2) = (2x_1 - 3y_1 + z_1) + '
        '(2x_2 - 3y_2 + z_2) = 0;';
    final box = _box(tex);
    expect(box.width, greaterThan(_phoneEm), reason: 'the fixture is wide');
    final lines = breakDisplayMath(box, maxEm: _phoneEm);
    expect(lines.length, greaterThan(1));
    for (final line in lines) {
      expect(
        line.width,
        lessThanOrEqualTo(_phoneEm),
        reason: 'a line is ${line.width} em where $_phoneEm fits',
      );
    }
    expect(
      lines.map(_glyphs).join(),
      _glyphs(box),
      reason: 'the same formula, in the same order',
    );
  });

  test('a break never lands inside a script', () {
    // No top-level operator: everything that looks like one is inside a
    // superscript, and a `VList` is not something a line may be cut at.
    final box = _box(
      'a^{-1}b^{-2}c^{-3}d^{-4}e^{-5}f^{-6}g^{-7}h^{-8}i^{-9}j^{-10}k^{-11}'
      'l^{-12}m^{-13}n^{-14}o^{-15}p^{-16}q^{-17}r^{-18}s^{-19}t^{-20}',
    );
    expect(box.width, greaterThan(_phoneEm));
    expect(breakDisplayMath(box, maxEm: _phoneEm), hasLength(1));
  });

  test('a formula with nothing to break at stays whole', () {
    // A matrix is one atom: no line break can help, and cutting it would be a
    // worse lie than a formula that overflows.
    final box = _box(
      r'\begin{pmatrix} a_{11} & a_{12} & a_{13} & a_{14} & a_{15} & a_{16} '
      r'& a_{17} & a_{18} \\ b_{21} & b_{22} & b_{23} & b_{24} & b_{25} '
      r'& b_{26} & b_{27} & b_{28} \\ c_{31} & c_{32} & c_{33} & c_{34} '
      r'& c_{35} & c_{36} & c_{37} & c_{38} \end{pmatrix}',
    );
    // A pane narrower than the matrix, whatever the matrix is: the point is
    // that there is nothing to break at, not how big the fixture grew.
    expect(breakDisplayMath(box, maxEm: 8), hasLength(1));
  });

  test('the text between operators stays with them', () {
    // `a =` then `b + c`: the break goes after the operator, as TeX does.
    final box = _box('aaaaaaaaaa = bbbbbbbbbb + cccccccccc');
    final lines = breakDisplayMath(box, maxEm: 8);
    expect(lines.length, greaterThan(1));
    expect(_glyphs(lines.first).trimRight(), endsWith('='));
    expect(_glyphs(lines[1]).trimLeft(), startsWith('b'));
  });

  test('a colour survives the split', () {
    // `\color{red}` colours every atom rather than wrapping the formula, so the
    // assertion is about what each line *draws*: a split must not drop the
    // spans the painter reads its colour from.
    final box = _box(r'\color{red} aaaaaaaaaa = bbbbbbbbbb + cccccccccc');
    final lines = breakDisplayMath(box, maxEm: 8);
    expect(lines.length, greaterThan(1));
    final colours = <String?>{};
    void walk(BoxNode node) {
      switch (node) {
        case SpanNode(:final color, :final children):
          if (children.any((child) => child is GlyphNode)) colours.add(color);
          children.forEach(walk);
        case HBox(:final children):
          children.forEach(walk);
        case _:
          break;
      }
    }

    lines.forEach(walk);
    expect(colours, <String?>{'red'}, reason: 'every glyph is still red');
  });
}
