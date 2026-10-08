// #40: a share lands in the shell — text at the end of the quick note, a
// file imported into the library and opened. #531: a web page shared from
// the browser opens the capture sheet instead, and Save captures it.
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_services.dart';
import 'package:niman/src/ui/quick_note_tab.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_share_service.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeShareInService shares;
  late FakeShortcutService shortcuts;
  late FakeFilePicker filePicker;
  late List<Uri> pagesRead;

  setUp(() {
    pagesRead = [];
    controller = FakeLibrarySession();
    shares = FakeShareInService();
    shortcuts = FakeShortcutService();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        shortcutServiceProvider.overrideWithValue(shortcuts),
        shareInServiceProvider.overrideWithValue(shares),
        // The page is the test's own: no network, no isolate.
        captureServicesProvider.overrideWithValue(
          CaptureServices(
            background: BackgroundCapture(
              notifier: const SilentCaptureNotifier(),
            ),
            browser: () async => null,
            read: (url, {browser, onProgress}) async {
              pagesRead.add(url);
              return (
                page: readPage(
                  '<html><head><title>A winter garden</title></head></html>',
                  url,
                ),
                bytes: 64,
                ranBrowser: false,
                pictures: const <String>[],
              );
            },
            save:
                (
                  page, {
                  required libraryRoot,
                  required attachmentsFolder,
                  required unreadableNotice,
                  required captured,
                  title,
                  downloadPictures = true,
                  tags = const [],
                  linkType = LinkType.wikilink,
                }) async => (
                  note: (name: title ?? page.title, text: 'tags: $tags'),
                  pictures: 0,
                ),
          ),
        ),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> close() async {
    await controller.close();
    await controller.dispose();
    await shares.dispose();
    await shortcuts.dispose();
  }

  Future<void> pumpOpenLibrary(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  testWidgets('shared text lands at the end of the quick note', (tester) async {
    await pumpOpenLibrary(tester);
    await controller.seedFile('Quick note.md', content: 'existing');
    await controller.setQuickNotePath(path: 'Quick note.md');

    shares.emit(const SharedText('shared from the web'));
    await settle(tester);

    expect(
      controller.contentOf('Quick note.md'),
      'existing\n\nshared from the web',
    );
    // It landed on the quick note, not on the choose/create screen.
    expect(find.byType(QuickNoteTab), findsNothing);
    await close();
  });

  testWidgets('a shared web page opens the capture sheet, and Save captures '
      'it', (tester) async {
    await pumpOpenLibrary(tester);
    await controller.seedFile('Quick note.md', content: 'existing');
    await controller.setQuickNotePath(path: 'Quick note.md');

    shares.emit(
      const SharedText(
        'https://example.com/garden',
        subject: 'Tending a winter garden',
      ),
    );
    await settle(tester);
    expect(find.byKey(const Key('capture-sheet')), findsOne);
    expect(pagesRead, [Uri.parse('https://example.com/garden')]);

    await tester.tap(find.byKey(const Key('capture-sheet-save')));
    await settle(tester);
    expect(find.byKey(const Key('capture-sheet')), findsNothing);
    expect(controller.contentOf('Tending a winter garden.md'), 'tags: [web]');
    // The quick note is not where a page goes.
    expect(controller.contentOf('Quick note.md'), 'existing');
    await close();
  });

  testWidgets('shared text with no quick note waits for the choice', (
    tester,
  ) async {
    await pumpOpenLibrary(tester);
    await controller.seedFile('Ideas.md', content: 'ideas');

    shares.emit(const SharedText('captured thought'));
    await settle(tester);

    // No quick note yet: the choose/create screen, and the text is still
    // waiting.
    expect(find.byType(QuickNoteTab), findsOne);
    expect(controller.contentOf('Ideas.md'), 'ideas');
    await tester.tap(find.byKey(const Key('quick-note-choose')));
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('note-picker')),
        matching: find.text('Ideas.md'),
      ),
    );
    await settle(tester);

    // The chosen note became the quick note and took the text.
    expect(await controller.quickNotePath, 'Ideas.md');
    expect(controller.contentOf('Ideas.md'), 'ideas\n\ncaptured thought');
    expect(find.byType(QuickNoteTab), findsNothing);
    await close();
  });

  testWidgets('a cold-start share is taken when the shell mounts', (
    tester,
  ) async {
    shares.launchRequest = const SharedText('from a cold start');
    await pumpOpenLibrary(tester);

    // Mounted with no quick note set: the share opened the chooser, and
    // the text is waiting for whatever note it lands on.
    expect(find.byType(QuickNoteTab), findsOne);
    await controller.seedFile('Quick note.md');
    await tester.tap(find.byKey(const Key('quick-note-choose')));
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('note-picker')),
        matching: find.text('Quick note.md'),
      ),
    );
    await settle(tester);

    expect(controller.contentOf('Quick note.md'), 'from a cold start');
    await close();
  });

  testWidgets('a shared Notion export is imported into the library', (
    tester,
  ) async {
    // A real folder to import into: the fake session would answer for the
    // notes, but the import writes the files itself.
    final tmp = Directory.systemTemp.createTempSync('niman_share_zip_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker, parent: tmp.path);

    // A Notion export, small: one page under its workspace folder.
    const id = '1f2e4c8a9b0d1e2f3a4b5c6d7e8f9012';
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          'Workspace $id/Roadmap 4a1b2c3d4e5f60718293a4b5c6d7e8f9.md',
          '# Roadmap\n',
        ),
      );
    final zip = File(p.join(tmp.path, 'Export $id.zip'))
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    shares.emit(SharedFile(path: zip.path, name: 'Export.zip'));
    final target = File(p.join(tmp.path, 'library', 'Workspace', 'Roadmap.md'));
    // The import reads the zip, writes the note and consumes the copy for
    // real, which a widget test's fake clock cannot drive on its own: each
    // turn here gives the isolate real time and pumps the continuation it
    // wakes. The wait is on the result — the note's bytes and the consumed
    // copy — and generous, because a shared runner is slower than a desk
    // and a timeout here reads as a failure of the feature.
    for (
      var i = 0;
      i < 500 &&
          !(target.existsSync() &&
              target.lengthSync() > 0 &&
              !zip.existsSync());
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await settle(tester);

    expect(target.readAsStringSync(), contains('# Roadmap'));
    expect(
      zip.existsSync(),
      isFalse,
      reason: 'the shared copy is consumed by the import',
    );
    await close();
  });

  testWidgets('a shared file is imported into the library and opened', (
    tester,
  ) async {
    await pumpOpenLibrary(tester);
    // Sync I/O: a widget test body is fake-async, where an awaited real
    // file operation never completes.
    final tmp = Directory.systemTemp.createTempSync('niman_share_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final copy = File(p.join(tmp.path, 'Report.md'))
      ..writeAsStringSync('---\ntitle: Shared report\n---\nbody text');

    // The handler reads the platform's copy for real, and a widget test
    // body is fake-async: real time is let through for the read, a pump
    // for the continuation it wakes. The loop is the seam between the two.
    shares.emit(SharedFile(path: copy.path, name: 'Report.md'));
    for (var i = 0; i < 300 && controller.contentOf('Report.md') == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await settle(tester);

    expect(controller.contentOf('Report.md'), contains('body text'));
    expect(
      copy.existsSync(),
      isFalse,
      reason: 'the platform copy is consumed by the import',
    );
    await close();
  });
}
