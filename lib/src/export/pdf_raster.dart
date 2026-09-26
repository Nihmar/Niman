/// Drawing a note as rastered PDF pages (#63): the fallback for a machine
/// with no browser engine to print the HTML with.
///
/// The note is laid out offscreen — the export seam's own view, at the
/// page's content width — and every page is a slice of that one layout,
/// captured at 2× and written into a PDF by [writePdf]. Everything here
/// paints, so it runs on the UI isolate: there is no second engine to hand
/// the picture to, and a note-sized job is the price of a machine without a
/// browser.
///
/// A page is a slice of the one layout, and where the slices end is not
/// the page's nominal edge: the break is moved up to the last offset that
/// falls between two lines of text ([rasterBreaks]), so a page never cuts
/// one in half. A picture taller than a page has nowhere to break and is
/// cut. A machine with an engine prints the page's HTML instead, where the
/// print CSS keeps blocks whole.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niman/src/export/pdf_breaks.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_writer.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// One logical pixel in PDF points: the layout runs at 96 per inch, the
/// writer's unit is 1/72 inch, so the same sheet is smaller on the page.
const double pointsPerPixel = 72 / 96;

/// A4's width in the logical pixels a page is laid out in (96 per inch).
const double a4WidthPx = a4Width / pointsPerPixel;

/// A4's height in logical pixels.
const double a4HeightPx = a4Height / pointsPerPixel;

/// The page margin the print CSS uses, in logical pixels (18 mm).
const double pdfPageMarginPx = 18 * 96 / 25.4;

/// Lays [text] out and draws its pages, answering the PDF's bytes.
///
/// [images] are the note's pictures, by the target as written, decoded here
/// and drawn in place: the fallback has no browser to print an HTML page
/// with, so a picture it is not handed is a picture the note loses (#63,
/// H3).
///
/// [onProgress] reports how many of the note's pages have been drawn, and
/// [isCancelled] is asked between pages: a cancel stops before the next
/// page and throws [PdfExportCancelled].
Future<Uint8List> rasterPdf({
  required String text,
  required MarkdownTheme theme,
  required MathCache mathCache,
  Map<String, Uint8List>? images,
  void Function(int done, int total)? onProgress,
  bool Function()? isCancelled,
  double pageWidth = a4WidthPx,
  double pageHeight = a4HeightPx,
  double margin = pdfPageMarginPx,
  double pixelRatio = 2,
}) async {
  final contentWidth = pageWidth - 2 * margin;
  final contentHeight = pageHeight - 2 * margin;
  // Decoded before the tree is built: the offscreen layout has no frame
  // loop, so an [EmbedView] that resolved and decoded on its own could not
  // be waited for.
  final decoded = <String, ui.Image>{};
  final maxPicture = math.max(1, (contentWidth * pixelRatio).round());
  for (final entry in (images ?? const <String, Uint8List>{}).entries) {
    try {
      decoded[entry.key] = await _decode(entry.value, maxPicture);
    } on Object {
      // A picture the engine cannot decode is left as the note's own
      // words, not made the export's failure.
    }
  }
  final key = GlobalKey();
  final layout = _OffscreenLayout(
    width: contentWidth,
    height: pageHeight,
    child: KeyedSubtree(
      key: key,
      child: MarkdownExportView(
        buffer: SourceBuffer.fromText(text),
        parser: BlockParser(),
        theme: theme,
        mathCache: mathCache,
        width: contentWidth,
        padding: EdgeInsets.zero,
        embedImages: decoded.isEmpty ? null : decoded,
      ),
    ),
  );
  try {
    final box = layout.layOut();
    // Where each page ends: the page's own edge pulled up to a gap between
    // two lines of text, so a slice never cuts one in half (#63).
    final breaks = rasterBreaks(
      total: box.size.height,
      spans: rasterInkSpans(box),
      contentHeight: contentHeight,
    );
    final count = breaks.length - 1;
    onProgress?.call(0, count);
    // The note is recorded once and sliced per page: a capture per page
    // would re-record the whole note for every page, which is quadratic in
    // the note's length (M6).
    final recording = MarkdownExport.record(box);
    final writer = PdfWriter(
      pageWidth: pageWidth * pointsPerPixel,
      pageHeight: pageHeight * pointsPerPixel,
      margin: margin * pointsPerPixel,
    );
    try {
      for (var page = 0; page < count; page++) {
        if (isCancelled?.call() ?? false) throw const PdfExportCancelled();
        final top = breaks[page];
        final height = breaks[page + 1] - top;
        final image = await recording.capture(
          Rect.fromLTWH(0, top, contentWidth, height),
          pixelRatio: pixelRatio,
        );
        try {
          // Compressed into the file here: the fallback holds one page's
          // pixels at a time, not every page of the note (M6).
          writer.addPage(await _pageImage(image));
        } finally {
          image.dispose();
        }
        onProgress?.call(page + 1, count);
      }
    } finally {
      recording.dispose();
    }
    return writer.finish();
  } finally {
    layout.dispose();
    for (final image in decoded.values) {
      image.dispose();
    }
  }
}

/// [bytes] as a picture the export can draw: never wider than the page
/// needs, so a phone photo does not decode to a screenful of pixels per
/// pixel of the note.
Future<ui.Image> _decode(Uint8List bytes, int maxWidth) async {
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
Future<PdfPageImage> _pageImage(ui.Image image) async {
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
final class _OffscreenLayout {
  new({required this.child, required this.width, required this.height});

  final Widget child;
  final double width;
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

/// The raster printer: a [PdfPrinter] that draws the note itself, for a
/// machine with no engine to print the page's HTML with.
///
/// The HTML path is ignored: what is drawn is [text] with this theme, not
/// the page file. It exists so a caller that found no engine has something
/// to fall back to with the same interface.
final class RasterPdfPrinter implements PdfPrinter {
  /// Prints [text].
  const new({
    required this.text,
    required this.theme,
    required this.mathCache,
    this.pixelRatio = 2,
  });

  /// The note, as written.
  final String text;

  /// The typography the pages are set in.
  final MarkdownTheme theme;

  /// The formulas the pages may typeset.
  final MathCache mathCache;

  /// Device pixels per logical pixel.
  final double pixelRatio;

  @override
  Future<bool> get canPrint async => true;

  @override
  Future<PdfOutcome> print(String htmlPath, String pdfPath) async {
    try {
      final bytes = await rasterPdf(
        text: text,
        theme: theme,
        mathCache: mathCache,
        pixelRatio: pixelRatio,
      );
      await File(pdfPath).writeAsBytes(bytes);
      return const PdfPrinted();
    } on Object catch (error) {
      return PdfFailed('$error');
    }
  }
}
