/// The painter of a typeset formula's box.
library;

import 'package:flutter/rendering.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/preview/math_raster.dart';

/// Paints [box] as `KatexBoxPainter` does, through [paintMath]: smooth where
/// the renderer would draw a path jagged.
final class MathBoxPainter extends CustomPainter {
  /// Creates the painter.
  const new(
    this.box, {
    required this.fontSize,
    required this.color,
    required this.devicePixelRatio,
    this.inkPadEm = 0,
  });

  /// The formula's box.
  final BoxNode box;

  /// Its size: logical pixels per em.
  final double fontSize;

  /// Its colour.
  final Color color;

  /// The screen's pixels per logical pixel.
  final double devicePixelRatio;

  /// The room kept round the box, in em, for ink past its metrics.
  final double inkPadEm;

  @override
  void paint(Canvas canvas, Size size) => paintMath(
    canvas,
    size,
    box,
    fontSize: fontSize,
    color: color,
    devicePixelRatio: devicePixelRatio,
    inkPadEm: inkPadEm,
  );

  @override
  bool shouldRepaint(MathBoxPainter oldDelegate) =>
      !identical(oldDelegate.box, box) ||
      oldDelegate.fontSize != fontSize ||
      oldDelegate.color != color ||
      oldDelegate.devicePixelRatio != devicePixelRatio ||
      oldDelegate.inkPadEm != inkPadEm;
}
