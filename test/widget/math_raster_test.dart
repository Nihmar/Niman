// The formulas whose shapes are paths, drawn through an image on the
// desktops (`MathRaster`): which formulas, and one image each.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex/katex.dart' show boxSizePx;
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/preview/math_raster.dart';

BoxNode _box(String tex) =>
    renderToBox(tex, options: const KatexOptions(displayMode: true));

void main() {
  tearDown(() {
    MathRaster.enabledOverride = null;
    MathRaster.clear();
  });

  test('a stretched delimiter, a root or an enclosure has shapes', () {
    expect(
      MathRaster.hasShapes(_box(r'\begin{pmatrix}1\\2\\3\end{pmatrix}')),
      isTrue,
    );
    expect(MathRaster.hasShapes(_box(r'\sqrt{x+1}')), isTrue);
    expect(MathRaster.hasShapes(_box(r'\cancel{x}')), isTrue);
    expect(MathRaster.hasShapes(_box(r'x + y = \frac{1}{2}')), isFalse);
  });

  test('the desktops draw through images, and only them', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(MathRaster.enabled, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(MathRaster.enabled, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(MathRaster.enabled, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a formula with shapes is drawn from one image, kept', (
    tester,
  ) async {
    MathRaster.enabledOverride = true;
    void draw(String tex) {
      final box = _box(tex);
      final recorder = ui.PictureRecorder();
      paintMath(
        Canvas(recorder),
        boxSizePx(box, 17),
        box,
        fontSize: 17,
        color: const Color(0xFF000000),
        devicePixelRatio: 1,
      );
      recorder.endRecording().dispose();
    }

    final matrix = _box(r'\begin{pmatrix}1\\2\\3\end{pmatrix}');
    for (var time = 0; time < 3; time++) {
      final recorder = ui.PictureRecorder();
      paintMath(
        Canvas(recorder),
        boxSizePx(matrix, 17),
        matrix,
        fontSize: 17,
        color: const Color(0xFF000000),
        devicePixelRatio: 1,
      );
      recorder.endRecording().dispose();
    }
    expect(MathRaster.cached, 1, reason: 'drawn three times, made once');
    draw('x + y');
    expect(MathRaster.cached, 1, reason: 'a formula of glyphs is drawn as is');
  });
}
