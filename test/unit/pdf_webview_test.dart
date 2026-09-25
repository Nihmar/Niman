// The Android side of a note's PDF (#63): the WebView channel's print, its
// failures, and the bridge that is not there.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String htmlPath;
  late String pdfPath;

  setUp(() async {
    dir = await Directory.current.createTemp('niman_webview_pdf_');
    htmlPath = p.join(dir.path, 'page.html');
    pdfPath = p.join(dir.path, 'page.pdf');
    await File(htmlPath).writeAsString('<p>x</p>');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Answers the channel with [handler] for this test.
  void answer(Future<Object?> Function(MethodCall call) handler) {
    const channel = MethodChannel(webViewPdfChannel);
    messenger().setMockMethodCallHandler(channel, handler);
    addTearDown(() => messenger().setMockMethodCallHandler(channel, null));
  }

  test('the WebView writes the file the channel names', () async {
    MethodCall? seen;
    answer((call) async {
      seen = call;
      final arguments = (call.arguments as Map).cast<String, String>();
      await File(arguments['pdfPath']!).writeAsBytes(<int>[1, 2, 3]);
      return null;
    });
    expect(
      await const WebViewPdfPrinter().print(htmlPath, pdfPath),
      isA<PdfPrinted>(),
    );
    expect(seen?.method, 'print');
    expect((seen?.arguments as Map)['htmlPath'], htmlPath);
  });

  test('a failed WebView reports why', () async {
    answer(
      (call) => throw PlatformException(
        code: 'print-failed',
        message: 'the write failed',
      ),
    );
    final outcome = await const WebViewPdfPrinter().print(htmlPath, pdfPath);
    expect(outcome, isA<PdfFailed>());
    expect((outcome as PdfFailed).message, 'the write failed');
  });

  test('no bridge at all is no engine', () async {
    expect(
      await const WebViewPdfPrinter().print(htmlPath, pdfPath),
      isA<PdfNoEngine>(),
    );
  });

  test('a channel that writes nothing is a failure', () async {
    answer((call) async => null);
    expect(
      await const WebViewPdfPrinter().print(htmlPath, pdfPath),
      isA<PdfFailed>(),
    );
  });

  test('an empty file is a failure', () async {
    answer((call) async {
      await File(pdfPath).writeAsBytes(const <int>[]);
      return null;
    });
    expect(
      await const WebViewPdfPrinter().print(htmlPath, pdfPath),
      isA<PdfFailed>(),
    );
  });
}
