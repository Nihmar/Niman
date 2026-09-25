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
/// A page is a slice of the one layout, not a break the layout chose: a
/// line or a picture that crosses a slice's edge is cut in two. A machine
/// with an engine prints the page's HTML instead, where the print CSS
/// keeps blocks whole.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_writer.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A4's width in the logical pixels a page is laid out in (96 per inch).
const double a4WidthPx = 793.7;

/// A4's height in logical pixels.
const double a4HeightPx = 1122.5;

/// The page margin the print CSS uses, in logical pixels (18 mm).
const double pdfPageMarginPx = 68.03;

/// Lays [text] out and draws its pages, answering the PDF's bytes.
Future<Uint8List> rasterPdf({
  required String text,
  required MarkdownTheme theme,
  required MathCache mathCache,
  double pageWidth = a4WidthPx,
  double pageHeight = a4HeightPx,
  double margin = pdfPageMarginPx,
  double pixelRatio = 2,
}) async {
  final contentWidth = pageWidth - 2 * margin;
  final contentHeight = pageHeight - 2 * margin;
  final key = GlobalKey();
  final layout = _OffscreenLayout(
    width: contentWidth,
    child: KeyedSubtree(
      key: key,
      child: MarkdownExportView(
        buffer: SourceBuffer.fromText(text),
        parser: BlockParser(),
        theme: theme,
        mathCache: mathCache,
        width: contentWidth,
        padding: EdgeInsets.zero,
      ),
    ),
  );
  try {
    final box = layout.layOut();
    final total = box.size.height;
    final count = math.max(1, (total / contentHeight).ceil());
    final pages = <PdfPageImage>[];
    for (var page = 0; page < count; page++) {
      final top = page * contentHeight;
      final height = math.min(contentHeight, total - top);
      final image = await MarkdownExport.capture(
        box,
        offset: Offset(0, -top),
        size: Size(contentWidth, height),
        pixelRatio: pixelRatio,
      );
      try {
        pages.add(await _pageImage(image));
      } finally {
        image.dispose();
      }
    }
    return writePdf(
      pages,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      margin: margin,
    );
  } finally {
    layout.dispose();
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
  new({required this.child, required this.width});

  final Widget child;
  final double width;

  final PipelineOwner _pipeline = PipelineOwner();
  final FocusManager _focus = FocusManager();
  late final BuildOwner _build = BuildOwner(focusManager: _focus);
  late final RenderView _view = RenderView(
    view: ui.PlatformDispatcher.instance.implicitView!,
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
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
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
