/// Spike 2's second question, measured: **is the caret rectangle right?**
///
/// `docs/dev/unified-surface.md` §8.7.2 says the caret's geometry comes from the
/// block's own laid-out `TextPainter` — `getOffsetForCaret` where it starts,
/// `getFullHeightForCaret` for how tall it is — and never from metrics the
/// surface computes for itself. That distinction is not academic here: the
/// hand-built editor this repo replaced (`12d9f4a`) had its own
/// `caret_geometry.dart`, `caret_painter.dart` and `row_text_metrics.dart`, and
/// the caret's *rendered* position is what it went away over. Phase 3's exit
/// criteria now carry it, and so does spike 2.
///
/// `zero_size_run_test.dart` already settles the caret's **horizontal**
/// position around a hidden run — the positions inside `**` collapse to one
/// place. This file is the rest of the rectangle, and it settles these, on the
/// test font:
///
/// * the caret's **height** over a hidden run is the line's: 19.2 px for a
///   16 px strut at height 1.2, at every offset, the end of the text included.
///   The design's rule that the height comes from the block's `StrutStyle`
///   holds for the caret;
/// * a **prototype's height is inert**: `getFullHeightForCaret` answers 19.2
///   px for a zero-height prototype, a 20 px one and a 100 px one, and the
///   offset does not move either. Its **width** is not inert — it is subtracted
///   from the offset for a right-to-left run (48, 46.5, 45, 38 for widths 0,
///   1.5, 3, 10) and does nothing at all for a left-to-right one. A surface
///   painting a caret *must* know which side of the returned offset to draw
///   on, and that is not in the returned `Offset`;
/// * an **empty block has no line metrics at all** — `computeLineMetrics()` is
///   empty — and still has a caret of the full 19.2 px. Anything that indexes
///   the first line metric crashes on the empty paragraph every note ends with;
/// * an **inline placeholder costs one code unit and its own width**. A `see
///   $x^2$ here` sentence is 14 source units and 10 in the paragraph, and the
///   caret steps exactly the placeholder's 40 px across it. So §8.6.0's
///   correction table is **arithmetic** — this text offset is that source
///   range — and not a geometric fudge, *provided* the surface supplies the
///   placeholder's real dimensions, which is the one thing it must measure;
/// * the caret **steps by the strut's advance, not by the line metric's
///   height**: a wrapped line moves it 19.2 px while `LineMetrics.height` reads
///   16. Accumulating line heights puts the caret 3 px high per line.
///
/// What it cannot settle, and says so rather than implying otherwise: the
/// platform fonts of Android, Linux and Windows, the IME, the real bidi
/// paragraph, and the device round-trip. Those are spike 2's remaining half
/// (§10.4); a green run here is a necessary condition, not a sufficient one.
library;

// The point of this file is to print its measurements into the test log.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A marker run styled the way `live` mode hides it: no size, no colour.
const TextStyle _hidden = TextStyle(fontSize: 0, color: Color(0x00000000));

const TextStyle _body = TextStyle(fontSize: 16);

/// The line metrics come from the block's strut, never from the hidden runs.
const StrutStyle _strut = StrutStyle(fontSize: 16, height: 1.2);

/// `some **bold** text`, with the two `**` runs hidden and the source text
/// intact — the invariant approach B depends on.
const TextSpan _bold = TextSpan(
  style: _body,
  children: [
    TextSpan(text: 'some '),
    TextSpan(text: '**', style: _hidden),
    TextSpan(text: 'bold', style: TextStyle(fontSize: 16)),
    TextSpan(text: '**', style: _hidden),
    TextSpan(text: ' text'),
  ],
);

/// A laid-out painter for [span].
TextPainter _painter(
  TextSpan span, {
  double maxWidth = double.infinity,
  TextDirection direction = TextDirection.ltr,
  List<PlaceholderDimensions>? placeholders,
}) {
  final painter = TextPainter(
    text: span,
    textDirection: direction,
    strutStyle: _strut,
  );
  if (placeholders != null) {
    painter.setPlaceholderDimensions(placeholders);
  }
  painter.layout(maxWidth: maxWidth);
  return painter;
}

/// The caret's offset at [offset], with a prototype of the line's own height.
Offset _caret(TextPainter painter, int offset) => painter.getOffsetForCaret(
  TextPosition(offset: offset),
  Rect.fromLTWH(0, 0, 1.5, painter.computeLineMetrics().first.height),
);

void main() {
  test('the caret is as tall over a hidden run as over a letter', () {
    final painter = _painter(_bold);
    final line = painter.computeLineMetrics().single.height;
    final prototype = Rect.fromLTWH(0, 0, 1.5, line);
    double heightAt(int offset) =>
        painter.getFullHeightForCaret(TextPosition(offset: offset), prototype);

    // Offsets into `some **bold** text`: 0-4 are visible, 5 and 6 are the first
    // `**`, 7-10 are `bold`, 11 and 12 the closing marker.
    print(
      'hidden run: line $line | caret height at 3 (a letter) ${heightAt(3)}, '
      'at 5 (inside **) ${heightAt(5)}, at 11 (inside the closing **) '
      '${heightAt(11)}, at 16 (the end) ${heightAt(16)}',
    );

    expect(heightAt(5), heightAt(3));
    expect(heightAt(11), heightAt(3));
    expect(heightAt(16), heightAt(3));
    expect(heightAt(5), greaterThan(0));
    painter.dispose();
  });

  test('the prototype sizes nothing and moves nothing left to right', () {
    final painter = _painter(_bold);
    final line = painter.computeLineMetrics().single.height;
    final proper = Rect.fromLTWH(0, 0, 1.5, line);
    for (final offset in <int>[0, 3, 5, 7, 11, 16]) {
      final zero = painter.getOffsetForCaret(
        TextPosition(offset: offset),
        Rect.zero,
      );
      final real = painter.getOffsetForCaret(
        TextPosition(offset: offset),
        proper,
      );
      print('prototype at $offset: Rect.zero -> $zero, line-high -> $real');
    }
    // The offset is the same, so a wrong prototype cannot move the caret...
    expect(
      painter.getOffsetForCaret(const TextPosition(offset: 7), Rect.zero),
      painter.getOffsetForCaret(const TextPosition(offset: 7), proper),
    );
    // ...and the height is not the prototype's business either: a zero-height
    // one and a 100 px one both answer with the line's own full height. The
    // parameter is documented as supplying the caret's height; on this engine
    // it does not, which is why a surface must not derive the caret's height
    // from its own box.
    expect(
      painter.getFullHeightForCaret(const TextPosition(offset: 7), Rect.zero),
      painter.getFullHeightForCaret(
        const TextPosition(offset: 7),
        const Rect.fromLTWH(0, 0, 1.5, 100),
      ),
    );
    expect(
      painter.getFullHeightForCaret(const TextPosition(offset: 7), Rect.zero),
      greaterThan(line),
    );
    painter.dispose();
  });

  test('the caret on an empty line', () {
    final painter = _painter(const TextSpan(text: '', style: _body));
    final lines = painter.computeLineMetrics();
    final line = lines.isEmpty ? 0.0 : lines.first.height;
    const at0 = TextPosition(offset: 0);
    final zeroOffset = painter.getOffsetForCaret(at0, Rect.zero);
    final properOffset = painter.getOffsetForCaret(
      at0,
      Rect.fromLTWH(0, 0, 1.5, line),
    );
    final zeroHeight = painter.getFullHeightForCaret(at0, Rect.zero);
    final properHeight = painter.getFullHeightForCaret(
      at0,
      Rect.fromLTWH(0, 0, 1.5, line),
    );
    print(
      'empty line: lines ${lines.length}, height $line | Rect.zero -> '
      '$zeroOffset, line-high -> $properOffset | full height zero '
      '$zeroHeight, line-high $properHeight',
    );

    // The trap: an empty block has no line metrics to index, and a caret all
    // the same. Every note ends with an empty paragraph.
    expect(lines, isEmpty);
    expect(zeroHeight, greaterThan(0));
    painter.dispose();
  });

  test('a placeholder costs one code unit and its own width', () {
    // `see $x^2$ here` as the surface shows it: the source characters of the
    // formula are gone and one placeholder stands for them. It has to be a
    // `WidgetSpan` — that is what the painter counts as a placeholder, and what
    // contributes exactly one code unit to the paragraph's text.
    const visual = 'see \uFFFC here';
    const span = TextSpan(
      style: _body,
      children: [
        TextSpan(text: 'see '),
        WidgetSpan(
          child: SizedBox(width: 40, height: 16),
          alignment: PlaceholderAlignment.middle,
        ),
        TextSpan(text: ' here'),
      ],
    );
    final painter = _painter(
      span,
      placeholders: const [
        PlaceholderDimensions(
          size: Size(40, 16),
          alignment: PlaceholderAlignment.middle,
        ),
      ],
    );
    final line = painter.computeLineMetrics().single.height;
    final prototype = Rect.fromLTWH(0, 0, 1.5, line);
    Offset caret(int offset) =>
        painter.getOffsetForCaret(TextPosition(offset: offset), prototype);
    // What the same sentence costs with the formula written out as text.
    final textOnly = _painter(
      const TextSpan(text: r'see $x^2$ here', style: _body),
    );
    print(
      'placeholder: text "${span.toPlainText()}" '
      '(${span.toPlainText().length} code units, source 13) | width '
      '${painter.width} | caret before the box ${caret(4)}, after ${caret(5)} '
      '(delta ${caret(5).dx - caret(4).dx}) | the same sentence as text: width '
      '${textOnly.width}',
    );

    // One code unit stands for five source ones, and the box the painter leaves
    // for it is the placeholder's own width.
    expect(span.toPlainText(), visual);
    expect(visual.length, r'see $x^2$ here'.length - 4);
    expect(caret(5).dx - caret(4).dx, 40);
    painter.dispose();
    textOnly.dispose();
  });

  test('the caret follows a wrap', () {
    // Eight 16 px characters, laid out 64 px wide.
    final painter = _painter(
      const TextSpan(text: 'aaaaaaaa', style: _body),
      maxWidth: 64,
    );
    final lines = painter.computeLineMetrics();
    final heights = lines.map((l) => l.height).toList();
    final at3 = _caret(painter, 3);
    final at4 = _caret(painter, 4);
    final at8 = _caret(painter, 8);
    print(
      'wrap: lines ${lines.length}, heights $heights | caret at 3 $at3, '
      'at 4 $at4, at 8 $at8',
    );

    expect(lines.length, greaterThan(1));
    final last = at3;
    final first = at4;
    expect(first.dx, lessThan(last.dx));
    expect(first.dy, greaterThan(last.dy));
    // The step is the strut's advance, not the line metric's height: a surface
    // that accumulates `LineMetrics.height` puts the caret 3 px high per line.
    expect(first.dy, greaterThan(lines.first.height));
    painter.dispose();
  });

  test('the prototype moves the caret on the right-to-left side only', () {
    // A left-to-right run and a right-to-left one, asked for the caret's
    // top-left with four prototype widths.
    final hebrew = _painter(const TextSpan(text: 'אבג', style: _body));
    final latin = _painter(const TextSpan(text: 'abc', style: _body));
    double dxAt(TextPainter painter, double width) => painter
        .getOffsetForCaret(
          const TextPosition(offset: 0),
          Rect.fromLTWH(0, 0, width, 20),
        )
        .dx;
    final hebrewXs = [
      for (final w in <double>[0, 1.5, 3, 10]) dxAt(hebrew, w),
    ];
    final latinXs = [
      for (final w in <double>[0, 1.5, 3, 10]) dxAt(latin, w),
    ];
    print(
      'prototype width: rtl dx at 0 for 0/1.5/3/10 = $hebrewXs | ltr = $latinXs '
      '| widths ${hebrew.width} / ${latin.width}',
    );

    // Right-to-left: the caret before the logical first character is drawn on
    // that character's *right*, so the returned top-left is the edge minus the
    // caret's own width — which is the prototype's, and only here.
    expect(hebrewXs, <double>[48, 46.5, 45, 38]);
    // Left-to-right: the prototype changes nothing about where the caret is.
    expect(latinXs, <double>[0, 0, 0, 0]);
    hebrew.dispose();
    latin.dispose();
  });
}
