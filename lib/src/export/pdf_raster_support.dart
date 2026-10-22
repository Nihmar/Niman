/// What the raster fallback's passes share (#63): the offscreen layout, the
/// decoding of a note's pictures and the read-back of a page into RGB.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niman/src/export/pdf_writer.dart';

/// One logical pixel in PDF points: the layout runs at 96 per inch, the
/// writer's unit is 1/72 inch, so the same sheet is smaller on the page.
const double pointsPerPixel = 72 / 96;

/// [bytes] as a picture the export can draw: never wider than the page
/// needs, so a phone photo does not decode to a screenful of pixels per
/// pixel of the note.
Future<ui.Image> decodePicture(Uint8List bytes, int maxWidth) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: maxWidth,
    allowUpscaling: false,
  );
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

/// [image] as RGB over white: a page has no transparency to keep.
Future<PdfPageImage> pageImage(ui.Image image) async {
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  if (data == null) {
    throw StateError('the page could not be read back');
  }
  final rgba = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final rgb = Uint8List(image.width * image.height * 3);
  for (var at = 0, out = 0; at + 3 < rgba.length; at += 4, out += 3) {
    final alpha = rgba[at + 3];
    final white = 255 - alpha;
    rgb[out] = _clamp(rgba[at] * alpha ~/ 255 + white);
    rgb[out + 1] = _clamp(rgba[at + 1] * alpha ~/ 255 + white);
    rgb[out + 2] = _clamp(rgba[at + 2] * alpha ~/ 255 + white);
  }
  return PdfPageImage(width: image.width, height: image.height, rgb: rgb);
}

int _clamp(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

/// The offscreen pipeline `markdown_export.dart` leaves to its caller: a
/// windowless `RenderView` whose child gets the width and all the height it
/// asks for.
final class OffscreenLayout {
  /// A layout of [child], [width] wide, on a surface [height] tall.
  new({required this.child, required this.width, required this.height});

  /// What is laid out.
  final Widget child;

  /// The width the child is given, tight.
  final double width;

  /// The height of the surface the child's size is measured against.
  final double height;

  final PipelineOwner _pipeline = PipelineOwner();
  final FocusManager _focus = FocusManager();
  late final BuildOwner _build = BuildOwner(focusManager: _focus);
  late final RenderView _view = RenderView(
    view: _platformView(ui.PlatformDispatcher.instance),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints(minWidth: width, maxWidth: width),
    ),
  );

  /// Lays [child] out and answers its render box.
  RenderBox layOut() {
    _pipeline.rootNode = _view;
    _view.prepareInitialFrame();
    RenderObjectToWidgetAdapter<RenderBox>(
      container: _view,
      // The tree is offscreen, so the inherited widgets a window would
      // bring — the text direction, the text scaling — are placed here.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          // The page in the reader's terms: the height cap a picture takes
          // its half of needs a surface to measure against, and the tree
          // has none of its own.
          data: MediaQueryData(
            size: Size(width, height),
            textScaler: TextScaler.noScaling,
          ),
          child: child,
        ),
      ),
    ).attachToRenderTree(_build);
    _pipeline
      ..flushLayout()
      ..flushCompositingBits();
    final box = _view.child;
    if (box == null) {
      throw StateError('the note did not lay out');
    }
    return box;
  }

  /// Lets the tree and its owners go.
  void dispose() {
    _pipeline.rootNode = null;
    _build.finalizeTree();
    _focus.dispose();
  }
}

/// The platform view the offscreen tree runs on, or a failure that says
/// what is missing: `implicitView!` died with a null-check error that
/// names neither the view nor the export (P5).
ui.FlutterView _platformView(ui.PlatformDispatcher dispatcher) {
  final view = dispatcher.implicitView;
  if (view == null) {
    throw StateError('the note cannot be laid out without a platform view');
  }
  return view;
}
