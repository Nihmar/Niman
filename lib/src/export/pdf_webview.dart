/// Printing an exported page with the system WebView (#63).
///
/// Android has no browser to run from `PATH`: the platform side lays the
/// page out in an offscreen WebView and writes its pages into the file
/// through the `niman/pdf` channel (`PdfBridge.kt`). The text is real, so
/// the PDF selects and searches like the desktop engine's.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:niman/src/export/pdf_printer.dart';

/// The channel the Android WebView printer answers on.
const String webViewPdfChannel = 'niman/pdf';

/// Prints through the system WebView, on Android.
///
/// The channel is the engine: where it is missing (this is not Android,
/// or the bridge was never attached) the outcome is [PdfNoEngine], and
/// the caller draws the note instead.
final class WebViewPdfPrinter implements PdfPrinter {
  /// Creates the printer.
  const new({this.timeout = const Duration(minutes: 2)});

  /// The channel, by name: the tests answer for it.
  static const MethodChannel _channel = MethodChannel(webViewPdfChannel);

  /// How long the WebView may take before its print is called failed: a
  /// page whose callbacks never arrive must not hold the export open.
  final Duration timeout;

  @override
  Future<PdfOutcome> print(String htmlPath, String pdfPath) async {
    try {
      await _channel
          .invokeMethod<void>('print', <String, String>{
            'htmlPath': htmlPath,
            'pdfPath': pdfPath,
          })
          .timeout(timeout);
    } on TimeoutException {
      return const PdfFailed('the WebView did not finish');
    } on MissingPluginException {
      return const PdfNoEngine();
    } on PlatformException catch (error) {
      return PdfFailed(error.message ?? error.code);
    } on Object catch (error) {
      return PdfFailed('$error');
    }
    final written = await fileSize(pdfPath);
    if (written == null) return const PdfFailed('no PDF was written');
    if (written == 0) return const PdfFailed('the PDF is empty');
    return const PdfPrinted();
  }
}
