// The background capture (#531): a page shared on a phone is read and
// saved with the app off screen, one capture at a time, and the
// notifications say how it went — reading with Cancel, then saved with
// Open and Show folder, or why not. The reading and the saving are the
// test's own, so no network and no isolate is in the way.
//
// The page is written in pieces of HTML, which run on without spaces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/capture/capture_reading_task.dart';
import 'package:niman/src/ui/capture/capture_routes.dart';

final Uri _url = Uri.parse('https://example.com/garden');

WebReading _reading({bool readable = true}) {
  const paragraph =
      'Most of the plot sleeps from November to February, but a winter '
      'garden is not an empty one, and each bed asks for a little care. ';
  final body = readable ? '<p>${paragraph * 3}</p><p>${paragraph * 3}</p>' : '';
  return (
    page: readPage(
      '<html><head><title>Tending a winter garden</title></head>'
      '<body><article>$body</article></body></html>',
      _url,
    ),
    bytes: 1024,
    ranBrowser: false,
    pictures: const [],
  );
}

/// What the notifications said, in order.
final class _Notifier implements CaptureNotifier {
  final List<String> said = [];
  final List<({String title, String body, String? open, String? folder})>
  results = [];
  String? cancel;

  /// What [begin] waits for, when set: the platform's round trip.
  Completer<void>? started;

  @override
  Future<void> begin({
    required String title,
    String? body,
    String? cancel,
  }) async {
    await started?.future;
    said.add('begin $title');
    this.cancel = cancel;
  }

  @override
  Future<void> update({
    required String title,
    String? body,
    String? cancel,
  }) async {
    said.add('update $title${body == null ? '' : ' / $body'}');
    this.cancel = cancel;
  }

  @override
  Future<void> end() async => said.add('end');

  @override
  Future<void> result({
    required String title,
    required String body,
    String? open,
    String? folder,
  }) async {
    said.add('result $title');
    results.add((title: title, body: body, open: open, folder: folder));
  }
}

void main() {
  late _Notifier notifier;
  late List<(String, String)> created;

  setUp(() {
    notifier = _Notifier();
    created = [];
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
  }) async => (
    note: (name: title ?? page.title, text: 'tags: $tags'),
    pictures: downloadPictures ? 3 : 0,
  );

  CaptureTarget target() => CaptureTarget(
    libraryRoot: '/library',
    attachmentsFolder: 'assets',
    linkType: LinkType.wikilink,
    folder: 'Reading',
    pickFolder: (current) async => null,
    create: (folder, name, text) async {
      created.add((folder, name));
      return '$folder/$name.md';
    },
    save: save,
    clock: () => DateTime(2026, 10, 8),
  );

  CaptureReadingTask reading(Future<WebReading> Function() read) =>
      CaptureReadingTask.start(
        _url,
        read: (url, {browser, onProgress}) => read(),
      );

  const chosen = (
    folder: 'Reading',
    title: null,
    tags: ['web'],
    downloadPictures: true,
  );

  test(
    'a page is read, saved, and said to be saved, with its way back',
    () async {
      final capture = BackgroundCapture(notifier: notifier);
      await capture.add(
        reading(() async => _reading()),
        target: target(),
        chosen: chosen,
      );
      await pumpEventQueue();
      expect(created, [('Reading', 'Tending a winter garden')]);
      expect(notifier.said.first, startsWith('begin Reading example.com'));
      expect(notifier.said.last, 'end');
      final result = notifier.results.single;
      expect(result.title, 'Saved: Tending a winter garden');
      expect(result.body, contains('3 images'));
      expect(
        captureRouteOf(result.open),
        isA<CaptureOpenNote>().having(
          (route) => route.path,
          'path',
          'Reading/Tending a winter garden.md',
        ),
      );
      expect(
        captureRouteOf(result.folder),
        isA<CaptureShowFolder>().having((r) => r.folder, 'folder', 'Reading'),
      );
      expect(capture.busy, isFalse);
    },
  );

  test('a page with no article is said to be saved without it', () async {
    final capture = BackgroundCapture(notifier: notifier);
    await capture.add(
      reading(() async => _reading(readable: false)),
      target: target(),
      chosen: chosen,
    );
    await pumpEventQueue();
    expect(notifier.results.single.title, 'Saved without the article');
    expect(notifier.results.single.body, contains('example.com'));
  });

  test('a page that cannot be had is said, and nothing is made', () async {
    final capture = BackgroundCapture(notifier: notifier);
    await capture.add(
      reading(
        () async => throw const PageFetchException(PageFetchFailure.network),
      ),
      target: target(),
      chosen: chosen,
    );
    await pumpEventQueue();
    expect(created, isEmpty);
    expect(notifier.results.single.title, 'Could not capture example.com');
    expect(notifier.results.single.open, isNull);
    expect(notifier.said.last, 'end');
  });

  test('Cancel while reading makes nothing and says nothing more', () async {
    final page = Completer<WebReading>();
    final capture = BackgroundCapture(notifier: notifier);
    await capture.add(
      reading(() => page.future),
      target: target(),
      chosen: chosen,
    );
    await pumpEventQueue();
    final route = captureRouteOf(notifier.cancel);
    expect(route, isA<CaptureCancel>());
    expect(capture.cancel((route! as CaptureCancel).id), isTrue);
    page.complete(_reading());
    await pumpEventQueue();
    expect(created, isEmpty);
    expect(notifier.results, isEmpty);
    expect(notifier.said.last, 'end');
  });

  test('a reading past the limit gives up, and the app may sleep', () {
    fakeAsync((async) {
      final capture = BackgroundCapture(notifier: notifier);
      unawaited(
        capture.add(
          reading(() => Completer<WebReading>().future),
          target: target(),
          chosen: chosen,
        ),
      );
      async.elapse(captureTimeLimit + const Duration(seconds: 1));
      expect(created, isEmpty);
      expect(notifier.results.single.body, 'The page did not answer in time.');
      expect(notifier.said.last, 'end');
    });
  });

  test('a capture is added once its service has started (#638)', () async {
    // The app goes to the back when add completes: Android starts no
    // foreground service after that.
    notifier.started = Completer<void>();
    var added = false;
    unawaited(
      BackgroundCapture(notifier: notifier)
          .add(
            reading(() async => _reading()),
            target: target(),
            chosen: chosen,
          )
          .then((_) => added = true),
    );
    await pumpEventQueue();
    expect(added, isFalse);
    notifier.started!.complete();
    await pumpEventQueue();
    expect(added, isTrue);
  });

  test('captures shared one after another run one at a time', () async {
    final first = Completer<WebReading>();
    final capture = BackgroundCapture(notifier: notifier);
    await capture.add(
      reading(() => first.future),
      target: target(),
      chosen: chosen,
    );
    await capture.add(
      reading(() async => _reading()),
      target: target(),
      chosen: (
        folder: 'Inbox',
        title: 'Second',
        tags: const [],
        downloadPictures: false,
      ),
    );
    await pumpEventQueue();
    expect(created, isEmpty);
    first.complete(_reading());
    await pumpEventQueue();
    expect(created, [
      ('Reading', 'Tending a winter garden'),
      ('Inbox', 'Second'),
    ]);
    expect(notifier.said.where((line) => line == 'end'), hasLength(1));
  });
}
