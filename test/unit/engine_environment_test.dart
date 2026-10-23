// The browser engine runs without Windows' compatibility layer (#1176):
// under one, Edge starts itself again and exits, so the export saw no PDF
// and the capture an empty page.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/core/process_run.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:path/path.dart' as p;

/// The layer Windows handed down where the fault was found.
const Map<String, String> _layer = {'__COMPAT_LAYER': 'DetectorsAppHealth'};

/// This process's environment with the compatibility layer in it, whether
/// or not the machine running the test has one.
Map<String, String> get _withLayer => {...Platform.environment, ..._layer};

/// A runner that starts the engine in [environment].
ProcessRunner _runIn(Map<String, String> environment) =>
    (exe, args, {timeout, outputLimit}) => runProcess(
      exe,
      args,
      timeout: timeout,
      outputLimit: outputLimit,
      environment: environment,
    );

void main() {
  group('the engine environment', () {
    test('drops the compatibility layer, however it is spelled', () {
      expect(
        engineEnvironment({
          '__COMPAT_LAYER': 'DetectorsAppHealth',
          'PATH': r'C:\Windows',
        }),
        {'PATH': r'C:\Windows'},
      );
      expect(engineEnvironment({'__compat_layer': 'RunAsInvoker'}), isEmpty);
    });

    test('keeps everything else as it is', () {
      final environment = {'HOME': '/home/u', 'LANG': 'it_IT.UTF-8'};
      expect(engineEnvironment(environment), environment);
    });

    test('is what a process is started in, whole', () async {
      // The shell answers with the variables it was given, and nothing of
      // the layer.
      final answer = await runProcess(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows
            ? ['/c', 'echo %NIMAN_ENGINE_ENV%:%__COMPAT_LAYER%']
            : [
                '-c',
                r'echo "$NIMAN_ENGINE_ENV:${__COMPAT_LAYER:-%__COMPAT_LAYER%}"',
              ],
        environment: engineEnvironment({
          ...Platform.environment,
          ..._layer,
          'NIMAN_ENGINE_ENV': 'given',
        }),
      );
      // An unset variable is left as written by cmd, and by the fallback
      // the POSIX line spells the same way.
      expect(answer.stdout.trim(), 'given:%__COMPAT_LAYER%');
    });

    test('is the one the printer and the capture run the engine in', () {
      expect(identical(ProcessPdfPrinter().run, runEngine), isTrue);
      expect(identical(const EnginePageBrowser('edge').run, runEngine), isTrue);
    });
  });

  group('Edge under a compatibility layer', () {
    String? edge;

    setUpAll(() async {
      if (Platform.isWindows) edge = await findPdfEngine();
    });

    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('niman_edge_layer_');
    });
    tearDown(() async {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // A profile file an engine still holds: the temp folder's to clear.
      }
    });

    /// Prints a page in a folder of its own under [name]: the printer puts
    /// the engine's profile beside the page, and the copy a handed-off
    /// print left running still holds its folder's.
    Future<(PdfOutcome, File)> printIn(
      String name,
      Map<String, String> environment,
    ) async {
      final folder = Directory(p.join(dir.path, name))..createSync();
      final html = File(p.join(folder.path, 'page.html'))
        ..writeAsStringSync('<html><body><h1>Board</h1><p>A card.</p>');
      final pdf = File(p.join(folder.path, 'page.pdf'));
      final outcome = await ProcessPdfPrinter(
        engine: edge,
        run: _runIn(environment),
      ).print(html.path, pdf.path);
      return (outcome, pdf);
    }

    test(
      'prints the PDF in the process that was started',
      () async {
        if (edge == null) return markTestSkipped('no Edge on this machine');
        // The fault: started under the layer, Edge hands the print to a
        // copy of itself and exits before the PDF is there.
        final (handedOff, _) = await printIn('layer', _withLayer);
        expect(handedOff, isA<PdfFailed>());
        // Without it, the PDF is whole when the process ends.
        final (outcome, pdf) = await printIn(
          'clean',
          engineEnvironment(_withLayer),
        );
        expect(outcome, isA<PdfPrinted>());
        final bytes = pdf.readAsBytesSync();
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(
          String.fromCharCodes(bytes.skip(bytes.length - 8)),
          contains('%%EOF'),
        );
      },
      skip: Platform.isWindows ? false : 'Edge hands off on Windows only',
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      "reads a page's DOM once its scripts ran",
      () async {
        if (edge == null) return markTestSkipped('no Edge on this machine');
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        server.listen((request) async {
          request.response
            ..headers.contentType = ContentType.html
            ..write(
              '<html><body><script> '
              "document.body.append('built by its script'); "
              '</script></body></html>',
            );
          await request.response.close();
        });
        final url = Uri.parse('http://127.0.0.1:${server.port}/');
        // The fault: the copy Edge started prints the DOM where it is lost.
        final lost = await EnginePageBrowser(
          edge!,
          run: _runIn(_withLayer),
        ).read(url);
        expect(lost, isNull);
        final dom = await EnginePageBrowser(
          edge!,
          run: _runIn(engineEnvironment(_withLayer)),
        ).read(url);
        expect(dom, contains('built by its script'));
      },
      skip: Platform.isWindows ? false : 'Edge hands off on Windows only',
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
