import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

/// One page's pixels on their way to the OCR worker: 4 bytes a pixel,
/// `bgra` (pdfrx) or RGBA (`dart:ui`), `ppi` the resolution they stand
/// for. Transferable, so the worker takes the bytes without a copy.
typedef OcrPixels = ({
  TransferableTypedData data,
  int width,
  int height,
  bool bgra,
  int ppi,
});

/// The resolution pages are rendered at: what Tesseract reads best.
const int ocrPpi = 300;

/// The longest side a page is handed over at: a poster at 300 DPI would
/// be hundreds of megabytes of pixels for no better text.
const int ocrMaxSide = 4200;

/// A PDF's pages, rendered one at a time for recognition.
final class OcrPdfPages {
  new _(this._document);

  /// Opens the PDF at [path] (absolute).
  static Future<OcrPdfPages> open(String path) async {
    await pdfrxFlutterInitialize();
    return OcrPdfPages._(await PdfDocument.openFile(path));
  }

  final PdfDocument _document;

  /// How many pages it has.
  int get count => _document.pages.length;

  /// Whether page [number] (1-based) already carries text: a PDF made
  /// from text rather than scanned needs no recognition.
  Future<bool> hasText(int number) async {
    final text = await _document.pages[number - 1].loadText();
    return (text?.fullText.trim().length ?? 0) > 20;
  }

  /// Page [number] (1-based) at [ocrPpi], white under it, its longest side
  /// at most [ocrMaxSide].
  Future<OcrPixels> render(int number) async {
    final page = _document.pages[number - 1];
    var scale = ocrPpi / 72;
    final longest = (page.width > page.height ? page.width : page.height);
    if (longest * scale > ocrMaxSide) scale = ocrMaxSide / longest;
    final width = (page.width * scale).round();
    final height = (page.height * scale).round();
    final image = await page.render(
      fullWidth: width.toDouble(),
      fullHeight: height.toDouble(),
      backgroundColor: 0xFFFFFFFF,
    );
    if (image == null) throw StateError('page $number did not render');
    try {
      return (
        data: TransferableTypedData.fromList([image.pixels]),
        width: image.width,
        height: image.height,
        bgra: true,
        ppi: (72 * scale).round(),
      );
    } finally {
      image.dispose();
    }
  }

  /// Closes the document.
  Future<void> close() => _document.dispose();
}

/// The picture at [path] (absolute), decoded by the engine's codecs off
/// the UI thread, its longest side at most [ocrMaxSide].
Future<OcrPixels> decodeOcrImage(String path) async {
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final longest = descriptor.width > descriptor.height
      ? descriptor.width
      : descriptor.height;
  final shrink = longest > ocrMaxSide ? ocrMaxSide / longest : 1.0;
  final codec = await descriptor.instantiateCodec(
    targetWidth: (descriptor.width * shrink).round(),
    targetHeight: (descriptor.height * shrink).round(),
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final bytes = await image.toByteData();
    if (bytes == null) throw StateError('$path did not decode');
    return (
      data: TransferableTypedData.fromList([bytes]),
      width: image.width,
      height: image.height,
      bgra: false,
      ppi: ocrPpi,
    );
  } finally {
    image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
}
