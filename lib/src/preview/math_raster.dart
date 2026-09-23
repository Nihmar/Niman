/// Formulas whose shapes are paths, painted smooth where the renderer
/// would not smooth them.
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:katex/katex.dart' show KatexBoxPainter;
import 'package:katex_dart/katex_dart.dart';

/// Paints [box] at [fontSize] into [size] at the canvas's origin, as
/// [KatexBoxPainter] does — through [MathRaster] when the formula holds a
/// shape the renderer would draw jagged.
void paintMath(
  Canvas canvas,
  Size size,
  BoxNode box, {
  required double fontSize,
  required Color color,
  required double devicePixelRatio,
  double inkPadEm = 0,
}) {
  if (MathRaster.enabled && MathRaster.hasShapes(box)) {
    MathRaster.paint(
      canvas,
      size,
      box,
      fontSize: fontSize,
      color: color,
      devicePixelRatio: devicePixelRatio,
      inkPadEm: inkPadEm,
    );
    return;
  }
  KatexBoxPainter(
    box,
    fontSize: fontSize,
    color: color,
    inkPadEm: inkPadEm,
  ).paint(canvas, size);
}

/// A formula drawn through an image four times as fine as the screen and
/// brought down to it, for the renderers that fill a path without
/// smoothing its edges.
///
/// KaTeX draws a stretched delimiter, a root sign or a brace as an SVG
/// path. Impeller on the Linux desktop fills a path with no antialiasing
/// when its surface has no multisampling: the glyphs, which come from the
/// font's atlas, are smooth, and a matrix's parentheses beside them are a
/// staircase (0.0.9 test round, measured on the engine: their edges were
/// black or white, nothing between). Drawing the whole formula at four
/// times the resolution and halving it twice is a box filter over sixteen
/// samples a pixel — the paths come out smooth, the glyphs as they were.
///
/// Only a formula that holds such a shape pays for it, and each one once:
/// the image is kept for as long as the formula is drawn at that size, in
/// that colour, on that screen.
abstract final class MathRaster {
  /// Whether formulas are drawn this way here: on the desktops, where the
  /// renderer's surface has no multisampling. Android's Vulkan surface is
  /// multisampled and smooths the paths itself.
  static bool get enabled =>
      enabledOverride ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.windows));

  /// For a test: forces [enabled] either way.
  @visibleForTesting
  static bool? enabledOverride;

  /// How much finer the image is drawn than the screen: halved twice.
  static const int _supersample = 4;

  /// How many images are kept, the least recently drawn let go first.
  static const int _capacity = 128;

  static final Expando<bool> _shapes = Expando<bool>('math shapes');

  static final LinkedHashMap<_Key, ui.Image> _images =
      LinkedHashMap<_Key, ui.Image>();

  /// Whether [box] holds a path (a stretched delimiter, a root, a brace)
  /// or an enclosure's strokes: the shapes a renderer may draw jagged.
  static bool hasShapes(BoxNode box) {
    final known = _shapes[box];
    if (known != null) return known;
    final found = switch (box) {
      SvgPathNode() || EncloseNode() => true,
      HBox(:final children) ||
      SpanNode(:final children) => children.any(hasShapes),
      VList(:final children) => children.any(
        (child) => child.elem != null && hasShapes(child.elem!),
      ),
      _ => false,
    };
    _shapes[box] = found;
    return found;
  }

  /// Paints [box] into [size] from its image, made the first time.
  static void paint(
    Canvas canvas,
    Size size,
    BoxNode box, {
    required double fontSize,
    required Color color,
    required double devicePixelRatio,
    double inkPadEm = 0,
  }) {
    if (size.isEmpty) return;
    final key = _Key(box, fontSize, color, devicePixelRatio, inkPadEm, size);
    var image = _images.remove(key);
    image ??= _draw(key);
    _images[key] = image;
    while (_images.length > _capacity) {
      _images.remove(_images.keys.first)?.dispose();
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero &
          Size(image.width / devicePixelRatio, image.height / devicePixelRatio),
      // One of the image's pixels to each of the screen's, as it was made:
      // sampled between them, a formula on a fraction of a pixel came out
      // soft. Taken whole, it lands at most half a pixel off, and sharp.
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  /// How many images are kept.
  @visibleForTesting
  static int get cached => _images.length;

  /// Lets every image go: a test's, or a theme's change of colours.
  @visibleForTesting
  static void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }

  static ui.Image _draw(_Key key) {
    final scale = key.devicePixelRatio * _supersample;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    KatexBoxPainter(
      key.box,
      fontSize: key.fontSize,
      color: key.color,
      inkPadEm: key.inkPadEm,
    ).paint(canvas, key.size);
    final picture = recorder.endRecording();
    var image = picture.toImageSync(
      (key.size.width * scale).ceil(),
      (key.size.height * scale).ceil(),
    );
    picture.dispose();
    for (var halving = _supersample; halving > 1; halving ~/= 2) {
      final half = _halve(image);
      image.dispose();
      image = half;
    }
    return image;
  }

  /// [image] at half its size, each pixel the mean of the four it covers.
  static ui.Image _halve(ui.Image image) {
    final width = (image.width / 2).ceil();
    final height = (image.height / 2).ceil();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, image.width / 2, image.height / 2),
      Paint()..filterQuality = FilterQuality.low,
    );
    final picture = recorder.endRecording();
    final half = picture.toImageSync(width, height);
    picture.dispose();
    return half;
  }
}

/// What an image was drawn from: the same formula at another size, in
/// another colour or on another screen is another image.
@immutable
final class _Key {
  const new(
    this.box,
    this.fontSize,
    this.color,
    this.devicePixelRatio,
    this.inkPadEm,
    this.size,
  );

  final BoxNode box;
  final double fontSize;
  final Color color;
  final double devicePixelRatio;
  final double inkPadEm;
  final Size size;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      identical(other.box, box) &&
      other.fontSize == fontSize &&
      other.color == color &&
      other.devicePixelRatio == devicePixelRatio &&
      other.inkPadEm == inkPadEm &&
      other.size == size;

  @override
  int get hashCode => Object.hash(
    identityHashCode(box),
    fontSize,
    color,
    devicePixelRatio,
    inkPadEm,
    size,
  );
}
