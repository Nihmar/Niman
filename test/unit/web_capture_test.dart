// Capturing a web page (#531), end to end: each page of
// test/fixtures/capture/ is served by a local server, captured into a
// library of its own, and its note compared with the golden `.md` beside
// it — the address of the server written as http://capture.test. A run
// with NIMAN_UPDATE_GOLDENS=1 writes the goldens instead.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:path/path.dart' as p;

final String _fixtures = p.join('test', 'fixtures', 'capture');
final bool _update = Platform.environment['NIMAN_UPDATE_GOLDENS'] == '1';

/// The bytes the server gives for a picture at [path]: its own name, so
/// each picture has its own hash.
List<int> _picture(String path) => 'picture:$path'.codeUnits;

void main() {
  late HttpServer server;
  late String base;
  late Directory library;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    library = await Directory.systemTemp.createTemp('niman_capture_');
    server.listen((request) async {
      final path = request.uri.path;
      final response = request.response;
      if (path.startsWith('/media/')) {
        response.headers.contentType = ContentType('image', 'png');
        response.add(_picture(path));
      } else if (path == '/moved') {
        await response.redirect(Uri.parse('/figure-srcset.html'));
        return;
      } else if (path == '/report.pdf') {
        response.headers.contentType = ContentType('application', 'pdf');
        response.write('%PDF-1.7');
      } else {
        final file = File(p.join(_fixtures, p.basename(path)));
        if (!file.existsSync()) {
          response.statusCode = HttpStatus.notFound;
        } else {
          response.headers.contentType = ContentType('text', 'html');
          response.add(file.readAsBytesSync());
        }
      }
      await response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await library.delete(recursive: true);
  });

  Future<WebCapture> capture(String path) => captureWebPage(
    Uri.parse('$base$path'),
    libraryRoot: library.path,
    attachmentsFolder: 'assets',
    unreadableNotice:
        'Niman could not read this page. '
        '[Open the link](<$base$path>) to read it.',
    captured: DateTime(2026, 10, 8),
    tags: const ['web'],
  );

  final pages =
      Directory(_fixtures)
          .listSync()
          .map((entry) => p.basename(entry.path))
          .where((name) => name.endsWith('.html'))
          .toList()
        ..sort();

  for (final page in pages) {
    test(page, () async {
      final result = await capture('/$page');
      final note = result.note.text.replaceAll(base, 'http://capture.test');
      final golden = File(
        p.join(_fixtures, '${p.basenameWithoutExtension(page)}.md'),
      );
      if (_update) {
        golden.writeAsStringSync(note);
        return;
      }
      expect(note, golden.readAsStringSync());
    });
  }

  test('the pictures are in the attachments folder, by their hash', () async {
    final result = await capture('/figure-srcset.html');
    expect(result.readable, isTrue);
    expect(result.pictures, 2);
    for (final path in ['/media/kale-1200.png', '/media/leeks.png']) {
      final name = '${sha256.convert(_picture(path))}.png';
      expect(File(p.join(library.path, 'assets', name)).existsSync(), isTrue);
    }
  });

  test('a redirect is followed, and the note is the page it ends at', () async {
    final result = await capture('/moved');
    expect(result.note.text, contains('source: $base/figure-srcset.html'));
  });

  test('what is not a page, or not there, is refused', () async {
    await expectLater(
      capture('/report.pdf'),
      throwsA(
        isA<PageFetchException>().having(
          (e) => e.failure,
          'failure',
          PageFetchFailure.notHtml,
        ),
      ),
    );
    await expectLater(
      capture('/nowhere.html'),
      throwsA(
        isA<PageFetchException>().having(
          (e) => e.failure,
          'failure',
          PageFetchFailure.status,
        ),
      ),
    );
  });
}
