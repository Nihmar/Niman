// Converting an HTML file to a note (#1293): the job end to end into a
// temporary library, its refusals, its progress, and a cancel that leaves
// nothing behind.
//
// HTML is written in pieces, and a space between two would be a word of
// the page: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/html/html_conversion.dart';
import 'package:niman/src/import/html/html_convert_job.dart';
import 'package:path/path.dart' as p;

const List<int> _png = [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3];
const List<int> _jpg = [255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 9, 9];
const List<int> _gif = [71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 8, 8];

String _name(List<int> bytes, String extension) =>
    '${sha256.convert(bytes)}$extension';

void main() {
  late Directory tmp;
  late String library;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_html_convert_');
    library = p.join(tmp.path, 'library');
    Directory(library).createSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  String page(String name, String html) {
    final file = File(p.join(tmp.path, 'saved', name))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(html);
    return file.path;
  }

  void picture(String path, List<int> bytes) =>
      File(p.join(tmp.path, 'saved', path))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes);

  HtmlConvertRequest request(
    String source, {
    String parent = '',
    LinkType linkType = LinkType.wikilink,
    String? name,
    String staging = '.html.niman-tmp-1',
  }) => (
    source: source,
    name: name,
    libraryRoot: library,
    parent: parent,
    staging: p.joinAll([
      library,
      if (parent.isNotEmpty) ...parent.split('/'),
      staging,
    ]),
    attachments: 'assets',
    linkType: linkType,
    extent: HtmlExtent.article,
    importedOn: DateTime(2026, 11, 20),
  );

  String read(String relative) =>
      File(p.joinAll([library, ...relative.split('/')])).readAsStringSync();

  /// Everything under the library, as `/`-separated relative paths.
  List<String> tree() => [
    for (final entry in Directory(library).listSync(recursive: true))
      p.relative(entry.path, from: library).replaceAll(r'\', '/'),
  ]..sort();

  Future<FetchedPicture?> noFetch(String url) async => null;

  group('a page', () {
    test('becomes a note, its pictures kept', () async {
      picture('Page_files/a.png', _png);
      picture('Page_files/b.jpg', _jpg);
      final source = page(
        'Dune review.html',
        '<html lang="en"><head><title>Dune review</title>'
            '<link rel="canonical" href="https://example.org/dune">'
            '<meta name="author" content="Ada"></head><body>'
            '<h1>Dune review</h1>'
            '<p id="intro">A <a href="#verdict">verdict</a> below.</p>'
            '<p><img src="Page_files/a.png" alt="Arrakis"> and '
            '<img src="./Page_files/a.png"> and '
            '<img src="Page_files/b.jpg" alt="Paul"></p>'
            '<p><img src="Page_files/missing.png"> '
            '<img src="data:image/gif;base64,${base64.encode(_gif)}" alt="dot"> '
            '<img src="https://example.org/i/web.png" alt="far"> '
            '<img src="https://example.org/i/down.png" alt="down"></p>'
            '<h2 id="verdict">Verdict</h2><p>Read it.</p></body></html>',
      );
      final fetched = <String>[];
      final progress = <HtmlConvertProgress>[];
      final converted = await convertHtml(
        request(source, parent: 'Reading'),
        fetch: (url) async {
          fetched.add(url);
          return url.endsWith('down.png')
              ? null
              : (
                  bytes: Uint8List.fromList(_jpg.reversed.toList()),
                  extension: '.png',
                );
        },
        progress: progress.add,
      );
      expect(converted.made, 'Reading/Dune review.md');
      expect(converted.open, converted.made);
      expect(converted.notes, 1);
      // a.png once (two srcs), b.jpg, the gif and the web one: four.
      expect(converted.pictures, 4);
      expect(fetched, hasLength(2));

      final text = read(converted.made);
      final web = _name(_jpg.reversed.toList(), '.png');
      expect(
        text,
        '---\n'
        'source: https://example.org/dune\n'
        'imported: 2026-11-20\n'
        'author: Ada\n'
        '---\n'
        '\n'
        '# Dune review\n'
        '\n'
        'A [verdict](#Verdict) below.\n'
        '\n'
        '![[assets/${_name(_png, '.png')}]] and '
        '![[assets/${_name(_png, '.png')}]] and '
        '![[assets/${_name(_jpg, '.jpg')}]]\n'
        '\n'
        '![[assets/${_name(_gif, '.gif')}]] '
        '![[assets/$web]] '
        '![down](https://example.org/i/down.png)\n'
        '\n'
        '## Verdict\n'
        '\n'
        'Read it.\n',
      );
      expect(
        tree(),
        [
          'Reading',
          'Reading/Dune review.md',
          'assets',
          'assets/${_name(_png, '.png')}',
          'assets/${_name(_jpg, '.jpg')}',
          'assets/${_name(_gif, '.gif')}',
          'assets/$web',
        ]..sort(),
      );
      // The page and its pictures stay where they were.
      expect(File(source).existsSync(), isTrue);
      expect(
        File(p.join(tmp.path, 'saved', 'Page_files', 'a.png')).existsSync(),
        isTrue,
      );
      // Six distinct sources and the note: the last step is the note's.
      expect(progress.last.total, 7);
      expect(progress.last.done, 6);
      expect(progress.last.what, 'Dune review');
      final counts = [for (final step in progress) step.done];
      expect(counts, orderedEquals([...counts]..sort()));
      expect(counts.toSet(), {0, 1, 2, 3, 4, 5, 6});
    });

    test('is written with Markdown links in a Markdown library', () async {
      picture('a.png', _png);
      final converted = await convertHtml(
        request(
          page('p.html', '<title>Trip</title><p><img src="a.png" alt="x"></p>'),
          parent: 'Travel/2026',
          linkType: LinkType.markdown,
        ),
        fetch: noFetch,
      );
      expect(
        read(converted.made),
        contains('![x](../../assets/${_name(_png, '.png')})'),
      );
    });

    test('is named after its title, free in the folder', () async {
      final source = page('p.html', '<title>Same: name?</title><p>One.</p>');
      final first = await convertHtml(request(source), fetch: noFetch);
      final second = await convertHtml(request(source), fetch: noFetch);
      expect(first.made, 'Same name.md');
      expect(second.made, 'Same name_1.md');
    });

    test('is named after its file when it has no title', () async {
      final first = await convertHtml(
        request(page('Plain page.html', '<p>Just text.</p>')),
        fetch: noFetch,
      );
      expect(first.made, 'Plain page.md');
      final shared = await convertHtml(
        request(
          page('1729512345678-x.html', '<p>Shared text.</p>'),
          name: 'Shared article.html',
        ),
        fetch: noFetch,
      );
      expect(shared.made, 'Shared article.md');
    });

    test('keeps a picture the library has already, once', () async {
      picture('a.png', _png);
      final source = page('p.html', '<title>A</title><p><img src="a.png"></p>');
      await convertHtml(request(source), fetch: noFetch);
      final marker = File(p.join(library, 'assets', _name(_png, '.png')))
        ..setLastModifiedSync(DateTime(2020));
      await convertHtml(request(source), fetch: noFetch);
      expect(Directory(p.join(library, 'assets')).listSync(), hasLength(1));
      // The one in the library was not written over.
      expect(marker.lastModifiedSync(), DateTime(2020));
    });

    test('with no pictures makes no attachments folder', () async {
      await convertHtml(
        request(page('p.html', '<title>T</title><p>Words.</p>')),
        fetch: noFetch,
      );
      expect(tree(), ['T.md']);
    });
  });

  group('the pictures from the web', () {
    test('come four at a time', () async {
      var running = 0;
      var most = 0;
      final urls = [for (var i = 0; i < 10; i++) 'https://example.org/$i.png'];
      final progress = <HtmlConvertProgress>[];
      final converted = await convertHtml(
        request(
          page(
            'p.html',
            '<title>T</title>${[for (final url in urls) '<img src="$url">'].join()}',
          ),
        ),
        fetch: (url) async {
          most = ++running > most ? running : most;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          running--;
          // Each one its own bytes: ten pictures.
          return (
            bytes: Uint8List.fromList([..._png, urls.indexOf(url)]),
            extension: '.png',
          );
        },
        progress: progress.add,
      );
      expect(most, parallelPictureDownloads);
      expect(converted.pictures, 10);
      // Counted as they finish: every count is reached, none goes back.
      final counts = [for (final step in progress) step.done];
      expect(counts, orderedEquals([...counts]..sort()));
      expect(counts.toSet(), {for (var i = 0; i <= 10; i++) i});
      expect(progress.last.total, 11);
    });
  });

  group('a file it refuses', () {
    Matcher refusedFor(HtmlRefusal reason) => throwsA(
      isA<HtmlRefused>().having((error) => error.reason, 'reason', reason),
    );

    test('that is not there, or is a folder', () async {
      await expectLater(
        convertHtml(request(p.join(tmp.path, 'gone.html')), fetch: noFetch),
        refusedFor(HtmlRefusal.notAFile),
      );
      await expectLater(
        convertHtml(request(tmp.path), fetch: noFetch),
        refusedFor(HtmlRefusal.notAFile),
      );
      expect(tree(), isEmpty);
    });

    test('that is over 32 MiB', () async {
      final big = File(p.join(tmp.path, 'big.html'));
      big.openSync(mode: FileMode.write)
        ..truncateSync(htmlMaxBytes + 1)
        ..closeSync();
      await expectLater(
        convertHtml(request(big.path), fetch: noFetch),
        refusedFor(HtmlRefusal.tooLarge),
      );
      expect(tree(), isEmpty);
    });

    test('in a charset it does not decode', () async {
      await expectLater(
        convertHtml(
          request(page('sj.html', '<meta charset="shift_jis"><p>x</p>')),
          fetch: noFetch,
        ),
        refusedFor(HtmlRefusal.unsupportedCharset),
      );
      expect(tree(), isEmpty);
    });
  });

  group('a conversion that does not finish', () {
    test('told to stop before it starts, writes nothing', () async {
      final source = page('p.html', '<title>T</title><p>x</p>');
      await expectLater(
        convertHtml(request(source), fetch: noFetch, stopped: () => true),
        throwsA(isA<HtmlConvertStopped>()),
      );
      expect(tree(), isEmpty);
    });

    test('stopped among its pictures, leaves nothing of them', () async {
      picture('a.png', _png);
      picture('b.png', _jpg);
      picture('c.png', _gif);
      final source = page(
        'p.html',
        '<title>T</title><p><img src="a.png"><img src="b.png">'
            '<img src="c.png"></p>',
      );
      var stop = false;
      await expectLater(
        convertHtml(
          request(source),
          fetch: noFetch,
          progress: (step) {
            // Told when the first picture is in the staging folder.
            if (step.done == 1) stop = true;
          },
          stopped: () => stop,
        ),
        throwsA(isA<HtmlConvertStopped>()),
      );
      expect(tree(), isEmpty);
    });

    test('stopped while pictures download, nothing lands', () async {
      final gates = <Completer<FetchedPicture?>>[];
      final started = Completer<void>();
      var stop = false;
      final source = page(
        'p.html',
        '<title>T</title>${[for (var i = 0; i < 6; i++) '<img src="https://example.org/$i.png">'].join()}',
      );
      final run = convertHtml(
        request(source),
        fetch: (url) {
          final gate = Completer<FetchedPicture?>();
          gates.add(gate);
          if (gates.length == 4 && !started.isCompleted) started.complete();
          return gate.future;
        },
        stopped: () => stop,
      );
      await started.future;
      stop = true;
      // Ends with every download still on its way.
      await expectLater(
        run.timeout(const Duration(seconds: 5)),
        throwsA(isA<HtmlConvertStopped>()),
      );
      // The downloads that arrive late write nothing.
      for (final gate in gates) {
        gate.complete((bytes: Uint8List.fromList(_png), extension: '.png'));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(tree(), isEmpty);
      expect(gates, hasLength(4));
    });

    test('told not to finish, moves nothing in', () async {
      picture('a.png', _png);
      final source = page('p.html', '<title>T</title><p><img src="a.png"></p>');
      await expectLater(
        convertHtml(
          request(source),
          fetch: noFetch,
          mayFinish: () async => false,
        ),
        throwsA(isA<HtmlConvertStopped>()),
      );
      expect(tree(), isEmpty);
    });

    test('that fails, leaves nothing', () async {
      picture('a.png', _png);
      final source = page('p.html', '<title>T</title><p><img src="a.png"></p>');
      await expectLater(
        convertHtml(
          request(source),
          fetch: noFetch,
          mayFinish: () async => throw StateError('boom'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(tree(), isEmpty);
    });
  });

  group('on its isolate', () {
    test('answers what it wrote, and says how far it got', () async {
      picture('a.png', _png);
      final conversion = await HtmlConversion.start(
        source: page('p.html', '<title>Run</title><p><img src="a.png"></p>'),
        libraryRoot: library,
        parent: 'Web',
        attachments: 'assets',
        linkType: LinkType.wikilink,
        importedOn: DateTime(2026, 11, 20),
      );
      final seen = <int>[];
      conversion.progress.addListener(() {
        final step = conversion.progress.value;
        if (step != null) seen.add(step.done);
      });
      final converted = await conversion.done;
      expect(converted.made, 'Web/Run.md');
      expect(converted.pictures, 1);
      expect(
        read('Web/Run.md'),
        contains('![[assets/${_name(_png, '.png')}]]'),
      );
      expect(seen, [0, 1, 1]);
      expect(conversion.cancellable, isFalse);
      expect(tree(), [
        'Web',
        'Web/Run.md',
        'assets',
        'assets/${_name(_png, '.png')}',
      ]);
    });

    test('tells a refusal apart', () async {
      final conversion = await HtmlConversion.start(
        source: p.join(tmp.path, 'gone.html'),
        libraryRoot: library,
        parent: '',
        attachments: 'assets',
        linkType: LinkType.wikilink,
      );
      await expectLater(
        conversion.done,
        throwsA(
          isA<HtmlRefused>().having(
            (error) => error.reason,
            'reason',
            HtmlRefusal.notAFile,
          ),
        ),
      );
      expect(tree(), isEmpty);
    });

    test('cancelled, leaves the library as it was', () async {
      final before = IsolateGauge.inFlight;
      final paragraphs = List.filled(4000, '<p>${'text ' * 50}</p>').join();
      final conversion = await HtmlConversion.start(
        source: page('big.html', '<title>Big</title>$paragraphs'),
        libraryRoot: library,
        parent: '',
        attachments: 'assets',
        linkType: LinkType.wikilink,
      );
      expect(IsolateGauge.inFlight, before + 1);
      expect(await conversion.cancel(), isTrue);
      await expectLater(conversion.done, throwsA(isA<HtmlConvertCancelled>()));
      expect(IsolateGauge.inFlight, before);
      expect(tree(), isEmpty);
    });

    test(
      'a cancel racing a refusal answers once, and throws nothing',
      () async {
        final uncaught = <Object>[];
        await runZonedGuarded(() async {
          for (var round = 0; round < 10; round++) {
            final conversion = await HtmlConversion.start(
              source: p.join(tmp.path, 'gone.html'),
              libraryRoot: library,
              parent: '',
              attachments: 'assets',
              linkType: LinkType.wikilink,
            );
            final cancelled = conversion.cancel();
            await expectLater(
              conversion.done,
              throwsA(anyOf(isA<HtmlConvertCancelled>(), isA<HtmlRefused>())),
            );
            await cancelled;
          }
        }, (error, _) => uncaught.add(error));
        expect(uncaught, isEmpty);
        expect(tree(), isEmpty);
      },
    );
  });
}
