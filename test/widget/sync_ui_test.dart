// WebDAV sync UI (mockups S1–S11): the settings screen with its test and
// first sync, the status icon and panel, conflicts, and the shell and
// settings entry points.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/sync/sync_conflict_screen.dart';
import 'package:niman/src/ui/sync/sync_flow.dart';
import 'package:niman/src/ui/sync/sync_settings_screen.dart';
import 'package:niman/src/ui/sync/sync_status.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_sync_service.dart';
import '../fakes/shell_harness.dart';

SyncDecision _decision(String path, SyncActionKind kind) =>
    SyncDecision(path: path, kind: kind, why: 'test');

void main() {
  late FakeSyncService sync;

  setUp(() => sync = FakeSyncService());

  /// Types into the field keyed [key], waiting out the previous tap so
  /// two quick taps on different fields are not read as a double tap.
  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(500, 1400));
    await tester.pumpWidget(
      MaterialApp(
        home: SyncSettingsScreen(sync: sync, libraryName: 'Notes'),
      ),
    );
    await tester.pump();
  }

  group('settings screen', () {
    testWidgets('a tested folder can be saved and starts its first sync', (
      tester,
    ) async {
      sync.planToConfirm = SyncPlan([
        _decision('a.md', SyncActionKind.upload),
        _decision('b.md', SyncActionKind.upload),
        _decision('c.md', SyncActionKind.download),
        _decision('d.md', SyncActionKind.conflict),
      ], rowCount: 0);
      await pumpScreen(tester);

      final save = find.byKey(const Key('sync-save'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await type(tester, 'sync-url', 'http://10.8.0.1:8080/webdav/Niman/');
      await type(tester, 'sync-user', 'ale');
      await type(tester, 'sync-password', 'pw');
      await tester.pump();
      expect(
        find.text(
          'Unencrypted connection: fine over a VPN or on your local '
          'network.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('sync-test')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sync-test-result')), findsOneWidget);
      expect(find.text('Connection works'), findsOneWidget);
      expect(find.text('Compatible mode · 412 ms'), findsOneWidget);
      expect(find.text('No renames on the server'), findsOneWidget);

      // Changing a field after the test takes "Save" away again.
      await type(tester, 'sync-user', 'other');
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await type(tester, 'sync-user', 'ale');
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(sync.calls, [
        'test http://10.8.0.1:8080/webdav/Niman/',
        'save http://10.8.0.1:8080/webdav/Niman/',
        'sync',
      ]);
      expect(sync.savedPassword, 'pw');

      // The first-sync summary, with its counts.
      expect(find.byKey(const Key('sync-first-dialog')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('sync-first-upload')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('sync-first-start')));
      await tester.pumpAndSettle();
      expect(sync.confirmed, isTrue);
      // Now configured: the overview replaces the form.
      expect(find.byKey(const Key('sync-overview-card')), findsOneWidget);
    });

    testWidgets('a failed test explains itself and offers no save', (
      tester,
    ) async {
      sync.testResult = const SyncTestResult(
        outcome: SyncTestOutcome.authentication,
      );
      await pumpScreen(tester);
      await type(tester, 'sync-url', 'https://x/');
      await tester.tap(find.byKey(const Key('sync-test')));
      await tester.pumpAndSettle();
      expect(find.text('User or password rejected'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('sync-save')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('configured: sync now, edit keeps the password, disconnect', (
      tester,
    ) async {
      sync.status = SyncStatus(
        destination: FakeSyncService.destination(
          lastSyncAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
        capabilities: WebDavCapabilities(probedAt: DateTime.now()),
      );
      await pumpScreen(tester);
      expect(find.byKey(const Key('sync-overview-card')), findsOneWidget);
      expect(find.byKey(const Key('sync-url')), findsNothing);

      await tester.tap(find.byKey(const Key('sync-now')));
      await tester.pumpAndSettle();
      expect(sync.calls, ['sync']);

      await tester.tap(find.byKey(const Key('sync-edit-server')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('sync-url')))
            .controller!
            .text,
        'http://10.8.0.1:8080/webdav/Niman/',
      );
      expect(
        find.text('Leave empty to keep the saved password.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('sync-test')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sync-save')));
      await tester.pumpAndSettle();
      expect(sync.savedPassword, isNull, reason: 'the stored one is kept');

      await tester.tap(find.byKey(const Key('sync-disconnect')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sync-disconnect-confirm')));
      await tester.pumpAndSettle();
      expect(sync.calls.last, 'disconnect');
      expect(find.byKey(const Key('sync-url')), findsOneWidget);
    });
  });

  group('status and panel', () {
    Widget harness() => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            actions: [
              SyncStatusButton(
                sync: sync,
                onSync: () => runSyncFromUi(context, sync),
                onOpenPanel: () => showSyncPanel(
                  context,
                  sync: sync,
                  onSyncNow: () => runSyncFromUi(context, sync),
                  onOpenSettings: () {},
                  onResolve: (path) => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          SyncConflictScreen(sync: sync, path: path),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SyncProgressStrip(sync: sync),
        ),
      ),
    );

    testWidgets('hidden without a destination; a tap syncs', (tester) async {
      await tester.pumpWidget(harness());
      expect(find.byKey(const Key('sync-status-button')), findsNothing);

      sync.status = SyncStatus(
        destination: FakeSyncService.destination(lastSyncAtMs: 1),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('sync-status-button')));
      await tester.pumpAndSettle();
      expect(sync.calls, ['sync']);
    });

    testWidgets('a running sync shows its progress', (tester) async {
      sync.status = SyncStatus(
        destination: FakeSyncService.destination(),
        running: true,
        stage: SyncStage.applying,
        done: 11,
        total: 38,
      );
      await tester.pumpWidget(harness());
      await tester.pump();
      expect(find.byKey(const Key('sync-progress-strip')), findsOneWidget);
      expect(find.text('Syncing · 12 of 38'), findsOneWidget);
    });

    testWidgets('conflicts open the panel, and one is resolved from there', (
      tester,
    ) async {
      final report = SyncReport()
        ..conflicts.add(
          const SyncConflict(
            path: 'todo.md',
            localSha256: 'aa',
            remoteSha256: 'bb',
          ),
        )
        ..failures.add((path: 'video.mp4', error: 'PUT video.mp4: 507'));
      sync.status = SyncStatus(
        destination: FakeSyncService.destination(lastSyncAtMs: 1),
        lastReport: report,
      );
      await tester.pumpWidget(harness());
      await tester.tap(find.byKey(const Key('sync-status-button')));
      await tester.pumpAndSettle();
      expect(sync.calls, isEmpty, reason: 'attention opens the panel');
      expect(find.byKey(const Key('sync-panel')), findsOneWidget);
      expect(find.text('Changed here and on the server · 1'), findsOneWidget);
      expect(find.text('Not synced · 1'), findsOneWidget);

      await tester.tap(find.text('Resolve'));
      await tester.pumpAndSettle();
      expect(find.byType(SyncConflictScreen), findsOneWidget);
      expect(find.text('theirs'), findsOneWidget);
      expect(find.text('mine'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sync-keep-local')));
      await tester.pumpAndSettle();
      expect(sync.calls, ['texts todo.md', 'resolve todo.md local']);
      expect(find.byType(SyncConflictScreen), findsNothing);
      expect(sync.status.conflicts, isEmpty);
    });

    testWidgets('a mass deletion asks, and cancelling stops it', (
      tester,
    ) async {
      sync
        ..status = SyncStatus(
          destination: FakeSyncService.destination(lastSyncAtMs: 1),
        )
        ..firstSync = false
        ..planToConfirm = SyncPlan([
          for (var i = 0; i < 12; i++)
            _decision('n$i.md', SyncActionKind.trashLocal),
        ], rowCount: 14);
      await tester.pumpWidget(harness());
      await tester.tap(find.byKey(const Key('sync-status-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sync-mass-dialog')), findsOneWidget);
      expect(find.text('Move 12 files to the trash?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(sync.confirmed, isFalse);
    });
  });

  group('entry points', () {
    late FakeLibrarySession controller;

    setUp(() => controller = FakeLibrarySession()..syncService = sync);

    tearDown(() async {
      await controller.close();
      await controller.dispose();
    });

    testWidgets('settings list the sync row and open the screen', (
      tester,
    ) async {
      setSurfaceSize(tester, const Size(900, 3000));
      await controller.open('/fake/library', create: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsBody(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      final row = find.byKey(const Key('sync-setting'));
      await tester.scrollUntilVisible(row, 200);
      expect(
        find.descendant(
          of: row,
          matching: find.text('Not set up for this library'),
        ),
        findsOneWidget,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(SyncSettingsScreen), findsOneWidget);
      expect(find.text('Library library'), findsOneWidget);
    });

    testWidgets('the files bar shows the icon once a destination exists', (
      tester,
    ) async {
      final picker = useFakeFilePicker();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [librarySessionProvider.overrideWithValue(controller)],
          child: const NimanApp(),
        ),
      );
      await tester.pump();
      await openLibrary(tester, picker);
      expect(find.byKey(const Key('sync-status-button')), findsNothing);

      sync.status = SyncStatus(
        destination: FakeSyncService.destination(lastSyncAtMs: 1),
      );
      await settle(tester);
      expect(find.byKey(const Key('sync-status-button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sync-status-button')));
      await settle(tester);
      expect(sync.calls, ['sync']);
    });
  });
}
