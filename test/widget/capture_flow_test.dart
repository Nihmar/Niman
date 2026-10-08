// Where a capture puts its note: the library's web captures folder
// (default `Clippings`, made when the library has none yet), not the
// folder the tree has selected — while its pictures still go in the
// attachments folder. The reading and the saving are the test's own, so
// no network and no isolate is in the way.
//
// The page is written in pieces of HTML, which run on without spaces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show LinkType, defaultCaptureFolder;
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/capture/capture_services.dart';

import '../fakes/fake_library_session.dart';

final Uri _url = Uri.parse('https://example.com/garden');

/// A page with an article of its own.
WebReading _reading() {
  const paragraph =
      'Most of the plot sleeps from November to February, but a winter '
      'garden is not an empty one, and each bed asks for a little care. ';
  return (
    page: readPage(
      '<html><head><title>Tending a winter garden</title></head>'
      '<body><article><p>${paragraph * 3}</p><p>${paragraph * 3}</p>'
      '<img src="https://example.com/kale.png"></article></body></html>',
      _url,
    ),
    bytes: 48 * 1024,
    ranBrowser: false,
    pictures: const ['https://example.com/kale.png'],
  );
}

void main() {
  late FakeLibrarySession session;
  late List<String> picturesTo;
  late List<String> captured;

  setUp(() async {
    session = FakeLibrarySession();
    await session.open('/fake/library', create: true);
    // The tree's selection used to be where a capture landed: a folder
    // the library holds, and the wrong one for a note.
    await session.ensureFolder('Attachments');
    picturesTo = [];
    captured = [];
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
    picturesTo.add(attachmentsFolder);
    return (
      note: (name: title ?? page.title, text: 'tags: $tags'),
      pictures: 1,
    );
  }

  CaptureFlow flow() => CaptureFlow(
    controller: session,
    services: CaptureServices(
      background: BackgroundCapture(notifier: const SilentCaptureNotifier()),
      read: (url, {browser, onProgress}) async => _reading(),
      save: save,
      browser: () async => null,
    ),
    attachmentsFolder: () => 'Attachments',
    linkType: () => LinkType.wikilink,
    onCaptured: captured.add,
    useSheet: false,
  );

  /// Captures [_url] with the desktop's dialog and saves it as it comes.
  Future<void> captureAndSave(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final capture = flow();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => capture.capture(context, url: _url),
            child: const Text('capture'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('capture'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('capture-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('a capture goes in the web captures folder, made for it, '
      'and its pictures in the attachments folder', (tester) async {
    expect(await session.captureFolder, defaultCaptureFolder);
    expect(await session.find('Clippings'), isNull, reason: 'not made yet');

    await captureAndSave(tester);

    expect(captured, ['Clippings/Tending a winter garden.md']);
    expect(await session.find('Clippings'), isNotNull);
    expect(picturesTo, ['Attachments']);
  });

  testWidgets('the folder chosen in the settings is the one it goes in', (
    tester,
  ) async {
    await session.setCaptureFolder(folder: 'Reading/Web');

    await captureAndSave(tester);

    expect(captured, ['Reading/Web/Tending a winter garden.md']);
    expect(picturesTo, ['Attachments']);
  });
}
