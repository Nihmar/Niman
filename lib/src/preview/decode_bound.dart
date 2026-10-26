// The pixel bounds a picture is decoded within (#1194).
//
// A picture decoded at its file's size is a bitmap of width × height × 4
// bytes whatever it is drawn at: a 12 MP photo is 48 MB where, drawn 800 px
// wide at a pixel ratio of 2, it needs 7.7 MB. Wrapping the provider in a
// `ResizeImage` bounded by [decodeBound] decodes it at the size it is
// drawn at (never above its own pixels), and keeps every pixel it can show.

import 'dart:math' as math;

/// How coarse a decode bound is, in physical pixels.
///
/// A bound that followed the drawn size to the pixel would be a new
/// `ResizeImage`, a new image-cache key and a new decode on every frame of
/// a window drag-resize. Rounding it up to the next multiple of this step
/// keeps the key still across a whole step of resizing, and bounds what a
/// picture is over-decoded by to one step.
const int decodeStep = 256;

/// The decode bound, in physical pixels, for [logical] logical pixels drawn
/// at [devicePixelRatio]: the drawn size rounded up to the next multiple of
/// [decodeStep], and never less than one step (a zero or negative size,
/// before layout, still asks for a valid bound).
int decodeBound(double logical, double devicePixelRatio) {
  final physical = logical * devicePixelRatio;
  if (!physical.isFinite || physical <= 0) return decodeStep;
  return math.max(1, (physical / decodeStep).ceil()) * decodeStep;
}
