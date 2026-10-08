// The capture dialog (#531): a page read step by step, then its note's
// title, folder and tags, its preview and frontmatter, and Save, which
// creates the note and answers its path. The reading and the saving are
// the test's own, so no network and no isolate is in the way.
//
// The page is written in pieces of HTML, which run on without spaces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/capture/capture_dialog.dart';

final Uri _url = Uri.parse('https://example.com/garden');

/// A page with an article of its own.
WebReading _reading() {
  const paragraph =
      'Most of the plot sleeps from November to February, but a winter '
      'garden is not an empty one, and each bed asks for a little care. ';
  return (
    page: readPage(
      '<html><head><title>Tending a winter garden</title>'
      '<meta name="author" content="Ada Fielding"></head>'
      '<body><nav><a href="/">Home</a></nav><article>'
      '<p>${paragraph * 3}</p><p>${paragraph * 3}</p>'
      '<img src="https://example.com/kale.png"></article></body></html>',
      _url,
    ),
    bytes: 48 * 1024,
    ranBrowser: false,
    pictures: const ['https://example.com/kale.png'],
  );
}

void main() {
  late List<(String, String, String)> created;
  late List<bool> picturesAsked;

  setUp(() {
    created = [];
    picturesAsked = [];
  });

  Future<({CapturedNote note, int pictures})> save(
    PageReading page, {
    required String libraryRoot,
    required String attachmentsFolder,
    required String unreadableNotice,
    required DateTime captured,
    String? title,
    bool downloadPictures = true,
    List<String> tags = const [],
    LinkType linkType = LinkType.wikilink,
  }) async {
    picturesAsked.add(downloadPictures);
    return (
      note: (name: title ?? page.title, text: 'tags: $tags'),
      pictures: 0,
    );
  }

  CaptureTarget target({CaptureRead? read}) => CaptureTarget(
    libraryRoot: '/library',
    attachmentsFolder: 'assets',
    linkType: LinkType.wikilink,
    folder: 'Reading',
    pickFolder: (current) async => 'Reading/Articles',
    create: (folder, name, text) async {
      created.add((folder, name, text));
      return '$folder/$name.md';
    },
    read:
        read ??
        (url, {PageBrowser? browser, onProgress}) async {
          onProgress?.call((
            stage: CaptureStage.downloading,
            bytes: 0,
            words: 0,
          ));
          return _reading();
        },
    save: save,
    clock: () => DateTime(2026, 10, 8),
  );

  /// Opens the dialog; its answer comes in the record's future.
  Future<({Future<String?> result})> open(
    WidgetTester tester, {
    Uri? url,
    CaptureRead? read,
  }) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Future<String?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => result = showCaptureDialog(
              context,
              target: target(read: read),
              url: url,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return (result: result);
  }

  testWidgets('a page is read, shown, and saved where and as asked', (
    tester,
  ) async {
    final (:result) = await open(tester, url: _url);
    expect(find.byKey(const Key('capture-title')), findsOne);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('capture-title')))
          .controller!
          .text,
      'Tending a winter garden',
    );
    expect(find.text('Ada Fielding'), findsOne, reason: 'the preview');
    final frontmatter = tester
        .widget<SelectableText>(find.byKey(const Key('capture-frontmatter')))
        .data!;
    expect(frontmatter, contains('source: https://example.com/garden'));
    expect(frontmatter, contains('author: Ada Fielding'));
    expect(frontmatter, contains('tags: [web]'));
    expect(find.text('· The navigation menu'), findsOne, reason: 'removed');

    await tester.enterText(find.byKey(const Key('capture-title')), 'Winter');
    await tester.tap(find.byKey(const Key('capture-folder')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('capture-add-tag')), '#garden');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-pictures')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('capture-save')));
    await tester.pumpAndSettle();

    expect(created, [('Reading/Articles', 'Winter', 'tags: [web, garden]')]);
    expect(picturesAsked, [false], reason: 'the pictures were unticked');
    expect(await result, 'Reading/Articles/Winter.md');
    expect(find.byKey(const Key('capture-dialog')), findsNothing);
  });

  testWidgets('an address that is no web page is refused before reading', (
    tester,
  ) async {
    var reads = 0;
    await open(
      tester,
      read: (url, {browser, onProgress}) async {
        reads++;
        return _reading();
      },
    );
    await tester.enterText(
      find.byKey(const Key('capture-address')),
      'file:///etc/passwd',
    );
    await tester.tap(find.byKey(const Key('capture-read')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('capture-error')), findsOne);
    expect(reads, 0);
  });

  testWidgets('a page that cannot be had says why, and can be read again', (
    tester,
  ) async {
    await open(
      tester,
      url: _url,
      read: (url, {browser, onProgress}) async =>
          throw const PageFetchException(PageFetchFailure.status, '404'),
    );
    expect(find.text('The site answered with an error (404).'), findsOne);
    expect(find.byKey(const Key('capture-read')), findsOne);
    expect(created, isEmpty);
  });
}
