/// The assumption the whole `live` mode rests on, measured.
///
/// `docs/records/unified-surface.md` §8.6 hides a Markdown marker by *styling* it
/// rather than by removing it: the rendered string stays the source text, and
/// the marker becomes a run at a zero font size so it takes no width. That
/// keeps every offset 1:1 — which is what removes the offset map, the IME
/// translation and the class of bug that writes the wrong bytes to disk — and
/// it is listed there as the first thing to spike, because **Flutter does not
/// document that a zero-size run has no advance**.
///
/// This is that spike, as a test that keeps running. What it can and cannot
/// settle:
///
/// * **It settles** whether a zero-size run contributes width, whether it
///   disturbs the kerning of the text around it, and whether it changes the
///   paragraph's height — the three ways the trick could fail.
/// * **It does not settle** behaviour with the platform fonts of Android,
///   Linux and Windows: `flutter test` lays out with the test font. A green
///   run here is a necessary condition, not a sufficient one, and the device
///   pass is described in the design document (§10.4, spike 2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A marker run styled the way `live` mode would hide it.
const TextStyle hiddenStyle = TextStyle(fontSize: 0, color: Color(0x00000000));

const TextStyle bodyStyle = TextStyle(fontSize: 16);

/// Lays [span] out unbounded and returns the paragraph's width.
double _widthOf(TextSpan span) {
  final painter = TextPainter(
    text: span,
    textDirection: TextDirection.ltr,
    strutStyle: const StrutStyle(fontSize: 16, height: 1.2),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// The block's text, with the given markers hidden.
///
/// The paragraph's own text is never changed — only which runs are styled
/// hidden — which is the invariant the design depends on.
TextSpan _paragraph({
  required String text,
  required List<String> markers,
  double hiddenSize = 0,
}) {
  final buffer = StringBuffer();
  final runs = <TextSpan>[];
  var position = 0;
  for (final marker in markers) {
    final at = text.indexOf(marker, position);
    if (at < 0) continue;
    if (at > position) {
      buffer.write(text.substring(position, at));
      runs.add(TextSpan(text: text.substring(position, at)));
    }
    buffer.write(marker);
    runs.add(
      TextSpan(
        text: marker,
        style: hiddenStyle.copyWith(fontSize: hiddenSize),
      ),
    );
    position = at + marker.length;
  }
  buffer.write(text.substring(position));
  runs.add(TextSpan(text: text.substring(position)));
  // The paragraph's text is the concatenation of its runs, and those runs are
  // slices of the source: nothing is removed, only styled.
  return TextSpan(children: runs, style: bodyStyle);
}

void main() {
  test('a hidden run contributes no width', () {
    final hidden = _paragraph(
      text: 'some **bold** text',
      markers: const ['**', '**'],
    );
    final shown = _paragraph(text: 'some bold text', markers: const []);
    expect(_widthOf(hidden), _widthOf(shown));
  });

  test('only exactly zero is zero: a negligible size still has width', () {
    // Measured here, and it is the reason the design says *zero* rather than
    // "zero or negligible": at 0.01 the two 16 px markers add 0.04 px, which
    // is enough to move the caret and break the 1:1 offset claim.
    final negligible = _paragraph(
      text: 'AVAVAV **AVAVAV** AVAVAV',
      markers: const ['**', '**'],
      hiddenSize: 0.01,
    );
    final plain = _paragraph(text: 'AVAVAV AVAVAV AVAVAV', markers: const []);
    expect(_widthOf(negligible), isNot(_widthOf(plain)));

    // And this is the same check at exactly zero, which is what `live` mode
    // will use: no width, and no disturbance to the kerning either side.
    for (final size in <double>[0]) {
      final hidden = _paragraph(
        text: 'AVAVAV **AVAVAV** AVAVAV',
        markers: const ['**', '**'],
        hiddenSize: size,
      );
      final plain = _paragraph(text: 'AVAVAV AVAVAV AVAVAV', markers: const []);
      expect(
        _widthOf(hidden),
        _widthOf(plain),
        reason: 'hidden run at font size $size changed the width',
      );
    }
  });

  test('the paragraph keeps the visible text height with hidden runs', () {
    double heightOf(TextSpan span) {
      final painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        strutStyle: const StrutStyle(fontSize: 16, height: 1.2),
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final hidden = _paragraph(
      text: 'some **bold** text',
      markers: const ['**', '**'],
    );
    final plain = _paragraph(text: 'some bold text', markers: const []);
    expect(heightOf(hidden), heightOf(plain));
  });

  test('the rendered text is still the source text', () {
    // The offset guarantee, stated as a test: hiding changes styles only.
    const source = 'some **bold** and `code` text';
    final span = _paragraph(
      text: source,
      markers: const ['**', '**', '`', '`'],
    );
    expect(span.toPlainText(), source);
  });

  test('the positions inside a hidden run collapse to one place', () {
    // `a**b**c`: the three offsets inside the first `**` (1, 2, 3) are all the
    // same place on screen, because the run has no width. That is not a bug to
    // fix — it is *why* the design needs both the reveal policy (so a marker
    // the caret is inside becomes visible and editable) and atomic ranges (so
    // arrow keys step over a hidden marker instead of sticking in it).
    const source = 'a**b**c';
    final painter = TextPainter(
      text: _paragraph(text: source, markers: const ['**', '**']),
      textDirection: TextDirection.ltr,
    )..layout();
    double xAt(int offset) =>
        painter.getOffsetForCaret(TextPosition(offset: offset), Rect.zero).dx;

    expect(xAt(1), xAt(2));
    expect(xAt(2), xAt(3));
    expect(xAt(4), xAt(5));
    // And the visible text still advances either side of them.
    expect(xAt(3), lessThan(xAt(4)));
    expect(xAt(0), lessThan(xAt(1)));
    painter.dispose();
  });
}
