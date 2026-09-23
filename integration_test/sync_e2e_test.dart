// WebDAV sync, end to end in the real app (issue #20): a library on
// disk, the real LibraryController and UI, and a WebDAV server in the
// same process — set the destination up from the settings screen, edit a
// note, sync from the icon, then resolve a conflict in the merge screen.
//
// Needs a device (or a desktop target): it opens a real library, which
// the headless test runner cannot do — the scan and the note writes run
// in isolates. The counterpart that does run headless is
// test/unit/sync_e2e_test.dart, the same flow without the UI.
//
//   flutter test integration_test/sync_e2e_test.dart -d <device>
//
// The WebDAV server runs in the app's own process, on loopback, so
// nothing has to be set up first.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_conflict_screen.dart';
import 'package:niman/src/ui/sync/sync_settings_screen.dart';
import 'package:path/path.dart' as p;

import '../test/fakes/fake_sync_secret_store.dart';
import '../test/fakes/fake_webdav_server.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late FakeWebDavServer server;
  late Directory library;
  late Directory scratch;
  late AppDatabase appDb;
  late LibraryController controller;

  setUp(() async {
    server = await FakeWebDavServer.start()
      ..putFile('.keep', const []);
    library = Directory.systemTemp.createTempSync('niman_e2e_lib_');
    scratch = Directory.systemTemp.createTempSync('niman_e2e_app_');
    File(p.join(library.path, 'Plan.md'))
        .writeAsStringSync('# Plan\nwrite the sync\ntest it\n');
    appDb = AppDatabase(NativeDatabase(File(p.join(scratch.path, 'app.db'))));
    await AppSettingsRepo(appDb).setLastLibraryPath(library.path);
    controller = LibraryController(
      () async => appDb,
      indexDbFactory: (path) async =>
          IndexDatabase(NativeDatabase(File(p.join(scratch.path, 'i.db')))),
      syncSecrets: FakeSyncSecretStore(),
    );
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await appDb.close();
    await server.close();
    library.deleteSync(recursive: true);
    scratch.deleteSync(recursive: true);
  });

  String remote(String path) {
    final bytes = server.file(path);
    return bytes == null ? '' : utf8.decode(bytes);
  }

  String? onDisk(String path) {
    final file = File(p.join(library.path, path));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  /// Pumps for [ms], in frames, without asking the app to go quiet.
  ///
  /// Once a sync is configured something is always moving — the status
  /// icon, the queue — so `pumpAndSettle` never returns and the test
  /// died on its ten-minute timeout instead of failing on what it was
  /// about.
  Future<void> pumpFor(WidgetTester tester, [int ms = 600]) async {
    for (var left = ms; left > 0; left -= 100) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps real frames until [probe] holds.
  Future<void> waitUntil(
    WidgetTester tester,
    bool Function() probe,
    String what, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (probe()) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail(
      'timed out waiting for: $what (library ${controller.phase.name}'
      '${controller.lastError == null ? '' : ', ${controller.lastError}'})',
    );
  }

  testWidgets('set up, sync, and resolve a conflict by merging', (
    tester,
  ) async {
    // A phone's window: Settings is a tab there. A wide one has the rail
    // instead, and since #202 opens Settings as a floating window — a
    // different walk through the same flow.
    tester.view
      ..physicalSize = const Size(420, 900)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    // The app resumes the last library by itself on a device; here the
    // open is explicit, so the test does not depend on that timing.
    unawaited(controller.open(library.path, create: false));
    await waitUntil(
      tester,
      () => controller.phase == LibraryPhase.ready,
      'the library to open',
    );
    await tester.pumpAndSettle();

    // --- Settings → Sync → WebDAV: address, test, save, first sync ----
    await tester.tap(find.byKey(const Key('tab-settings')));
    await tester.pumpAndSettle();
    // Through the settings search rather than by scrolling the list:
    // the search is the app's own way in, and a list that grows does not
    // break the walk (the scroll had become ambiguous — the screen has
    // more than one scrollable).
    await tester.enterText(
      find.byKey(const Key('settings-search-field')),
      AppStrings.settingsSectionSync,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('settings-search-settings-area-sync')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SyncSettingsScreen), findsOneWidget);

    await tester.enterText(find.byKey(const Key('sync-url')), '${server.url}');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sync-test')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync-test-result')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sync-save')));
    // The first sync asks before it starts.
    await waitUntil(
      tester,
      () => find.byKey(const Key('sync-first-dialog')).evaluate().isNotEmpty,
      'the first-sync question',
    );
    await tester.tap(find.byKey(const Key('sync-first-start')));
    await waitUntil(
      tester,
      () => server.exists('Plan.md'),
      'the first sync to upload the note',
    );
    expect(remote('Plan.md'), '# Plan\nwrite the sync\ntest it\n');

    // --- An edit here reaches the server by itself -------------------
    await controller.ops!.saveNote(
      'Plan.md',
      '# Plan\nwrite the sync\ntest it\nship it\n',
    );
    await waitUntil(
      tester,
      () => remote('Plan.md').contains('ship it'),
      'the edit to reach the server on its own',
      timeout: const Duration(seconds: 60),
    );

    // --- Both sides change the same line: a conflict -----------------
    server.putFile(
      'Plan.md',
      utf8.encode('# Plan\nwrite the sync\ntest it on the NAS\nship it\n'),
    );
    await controller.ops!.saveNote(
      'Plan.md',
      '# Plan\nwrite the sync\ntest it on the phone\nship it\n',
    );
    await waitUntil(
      tester,
      () => controller.sync!.status.conflicts.isNotEmpty,
      'the conflict to be reported',
      timeout: const Duration(seconds: 60),
    );

    // --- The panel, then the merge screen ----------------------------
    // Out of the sync screen first: the tab bar is under it.
    while (find.backButton().evaluate().isNotEmpty) {
      await tester.tap(find.backButton().first);
      await pumpFor(tester);
    }
    await tester.tap(find.byKey(const Key('tab-files')));
    await pumpFor(tester);
    await tester.tap(find.byKey(const Key('sync-status-button')));
    await pumpFor(tester);
    expect(find.byKey(const Key('sync-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sync-conflict-Plan.md')));
    await pumpFor(tester);
    await tester.tap(find.text('Resolve'));
    await pumpFor(tester);
    expect(find.byType(SyncConflictScreen), findsOneWidget);
    await waitUntil(
      tester,
      () => find.byKey(const Key('sync-conflict-merge')).evaluate().isNotEmpty,
      'the merge of both versions',
    );

    // Keep both lines of the overlap, then save the merge.
    await tester.tap(find.text(AppStrings.syncMergeKeepBoth));
    await pumpFor(tester);
    await tester.tap(find.byKey(const Key('sync-save-merge')));
    await waitUntil(
      tester,
      // Both markers: the server already holds the remote line from the
      // conflict setup, so waiting for it alone returns at once. And the
      // conflict gone: the upload lands before the resolution records the
      // agreement and takes the conflict off the panel, so the server
      // holding the merge alone says the resolution is still going.
      () =>
          remote('Plan.md').contains('on the phone') &&
          remote('Plan.md').contains('on the NAS') &&
          controller.sync!.status.conflicts.isEmpty,
      'the merged text to reach the server',
      timeout: const Duration(seconds: 60),
    );
    final merged = onDisk('Plan.md');
    expect(merged, contains('on the phone'));
    expect(merged, contains('on the NAS'));
    expect(remote('Plan.md'), merged);
    expect(controller.sync!.status.conflicts, isEmpty);

    // The replaced text is in the note's history.
    final versions = await controller.ops!.noteHistory('Plan.md');
    expect(versions.versions, isNotEmpty);
  });
}
