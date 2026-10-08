// Capturing a web page (#531), end to end: each page of
// test/fixtures/capture/ is served by a local server, captured into a
// library of its own, and its note compared with the golden `.md` beside
// it — the address of the server written as http://capture.test. A page
// with a `.dom.html` beside it — what a real browser's --dump-dom gave for
// it — is captured a second time with a browser that answers that DOM, and
// compared with its `.browser.md`. A run with NIMAN_UPDATE_GOLDENS=1
// writes the goldens instead.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:path/path.dart' as p;

final String _fixtures = p.join('test', 'fixtures', 'capture');
final bool _update = Platform.environment['NIMAN_UPDATE_GOLDENS'] == '1';

/// The bytes the server gives for a picture at [path]: its own name, so
/// each picture has its own hash.
List<int> _picture(String path) => 'picture:$path'.codeUnits;

/// What a capture gave: its note, its reading, and how it went.
typedef _Captured = ({
  CapturedNote note,
  bool readable,
  bool ranBrowser,
  int pictures,
  PageReading page,
});

/// A browser that answers the DOM recorded beside the page, or nothing.
final class _RecordedBrowser implements PageBrowser {
  const new();

  @override
  Future<String?> read(Uri url) async {
    final dom = File(
      p.join(_fixtures, '${p.basenameWithoutExtension(url.path)}.dom.html'),
    );
    return dom.existsSync() ? dom.readAsStringSync() : null;
  }
}

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
      } else if (path == '/badly-moved') {
        response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, 'http://a:99x/');
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

  /// The page at [path] read, and saved as the capture's screens do.
  Future<_Captured> capture(
    String path, {
    PageBrowser? browser,
    String? title,
    List<CaptureProgress>? steps,
  }) async {
    final reading = await readWebPage(
      Uri.parse('$base$path'),
      browser: browser,
      onProgress: steps?.add,
    );
    final saved = await saveWebCapture(
      reading.page,
      libraryRoot: library.path,
      attachmentsFolder: 'assets',
      unreadableNotice:
          'Niman could not read this page. '
          '[Open the link](<$base$path>) to read it.',
      captured: DateTime(2026, 10, 8),
      tags: const ['web'],
      title: title,
    );
    return (
      note: saved.note,
      readable: reading.page.readable,
      ranBrowser: reading.ranBrowser,
      pictures: saved.pictures,
      page: reading.page,
    );
  }

  final pages =
      Directory(_fixtures)
          .listSync()
          .map((entry) => p.basename(entry.path))
          .where(
            (name) => name.endsWith('.html') && !name.endsWith('.dom.html'),
          )
          .toList()
        ..sort();

  Future<void> compare(_Captured result, String goldenName) async {
    final note = result.note.text.replaceAll(base, 'http://capture.test');
    final golden = File(p.join(_fixtures, goldenName));
    if (_update) {
      golden.writeAsStringSync(note);
      return;
    }
    expect(note, golden.readAsStringSync());
  }

  for (final page in pages) {
    final name = p.basenameWithoutExtension(page);
    test(page, () async {
      final result = await capture('/$page');
      expect(result.ranBrowser, isFalse);
      await compare(result, '$name.md');
    });
    if (!File(p.join(_fixtures, '$name.dom.html')).existsSync()) continue;
    test('$page, run in a browser', () async {
      final result = await capture('/$page', browser: const _RecordedBrowser());
      expect(result.readable, isTrue, reason: 'the browser found the text');
      expect(result.ranBrowser, isTrue);
      await compare(result, '$name.browser.md');
    });
  }

  test('each step is said as it happens', () async {
    final steps = <CaptureProgress>[];
    await capture(
      '/script-built.html',
      browser: const _RecordedBrowser(),
      steps: steps,
    );
    expect(steps.map((step) => step.stage), [
      CaptureStage.downloading,
      CaptureStage.runningBrowser,
    ]);
    expect(steps.last.bytes, greaterThan(0));
    expect(steps.last.words, lessThan(40), reason: 'only the title, words');
  });

  test("the title the user gives is the note's", () async {
    final result = await capture('/jsonld-byline.html', title: ' Leaves ');
    expect(result.note.name, 'Leaves');
    expect(result.note.text, contains('\n# Leaves\n'));
  });

  test('what was left out around the article is counted', () async {
    final result = await capture('/figure-srcset.html');
    final removed = result.page.removed;
    expect(removed.menu, isTrue, reason: 'the nav');
    expect(removed.banner, isFalse);
    expect(removed.wordsAround, greaterThan(0), reason: 'menu and footer');
    expect(result.page.words, greaterThan(150));
  });

  test('a page with its text is not run in a browser', () async {
    final result = await capture(
      '/jsonld-byline.html',
      browser: const _RecordedBrowser(),
    );
    expect(result.ranBrowser, isFalse);
  });

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
    // A redirect to no address at all is the server's error (#639).
    await expectLater(
      capture('/badly-moved'),
      throwsA(
        isA<PageFetchException>().having(
          (e) => e.failure,
          'failure',
          PageFetchFailure.status,
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
