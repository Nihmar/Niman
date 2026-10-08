// The desktop page browser (#531): the engine run headless with --dump-dom
// in a throwaway profile, removed afterwards, and nothing when it fails.
// NIMAN_CAPTURE_BROWSER=<engine> runs the live case against that Chromium
// (or Edge), reading a page that builds its text with a script.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/core/process_run.dart';
import 'package:path/path.dart' as p;

void main() {
  final url = Uri.parse('https://example.com/a');

  test('the engine dumps the DOM headless, in a profile of its own', () async {
    late List<String> seen;
    late String profile;
    final browser = EnginePageBrowser(
      'chromium',
      run: (exe, args, {timeout, outputLimit}) async {
        seen = args;
        profile = args
            .firstWhere((arg) => arg.startsWith('--user-data-dir='))
            .substring('--user-data-dir='.length);
        expect(Directory(profile).existsSync(), isTrue);
        expect(timeout, browserReadTimeout);
        expect(outputLimit, maxBrowserDomCharacters);
        return (exit: 0, stdout: '<html><body>page</body></html>');
      },
    );
    expect(await browser.read(url), '<html><body>page</body></html>');
    expect(seen, containsAll(<String>['--headless=new', '--dump-dom']));
    expect(seen.last, url.toString(), reason: 'the page is the last word');
    expect(
      Directory(profile).existsSync(),
      isFalse,
      reason: 'the profile goes once the page is read',
    );
  });

  test(
    'a failed run, a run past its time or a non-web address give nothing',
    () async {
      var runs = 0;
      Future<ProcessAnswer> failing(
        String exe,
        List<String> args, {
        Duration? timeout,
        int? outputLimit,
      }) async {
        runs++;
        return (exit: 1, stdout: '');
      }

      Future<ProcessAnswer> hung(
        String exe,
        List<String> args, {
        Duration? timeout,
        int? outputLimit,
      }) async {
        runs++;
        throw const ProcessTimedOut();
      }

      expect(
        await EnginePageBrowser('chromium', run: failing).read(url),
        isNull,
      );
      expect(await EnginePageBrowser('chromium', run: hung).read(url), isNull);
      expect(
        await EnginePageBrowser(
          'chromium',
          run: failing,
        ).read(Uri.parse('file:///etc/passwd')),
        isNull,
      );
      expect(runs, 2, reason: 'a file address is never handed to the engine');
    },
  );

  final engine = Platform.environment['NIMAN_CAPTURE_BROWSER'];
  test(
    'live: a real engine runs the page',
    skip: engine == null ? 'NIMAN_CAPTURE_BROWSER is not set' : false,
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response
          ..headers.contentType = ContentType.html
          ..add(
            File(p.join('test', 'fixtures', 'capture', 'script-built.html'))
                .readAsBytesSync(),
          );
        await request.response.close();
      });
      final dom = await EnginePageBrowser(engine!)
          .read(Uri.parse('http://127.0.0.1:${server.port}/script-built.html'));
      expect(dom, contains('<p>Most of the plot sleeps'));
    },
  );
}
