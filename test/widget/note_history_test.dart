// Note history UI (issues #55, #67): the diff view, the version list, the
// version screen with restore, and the tree menu entry that opens them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/diff/diff_view.dart';
import 'package:niman/src/ui/history/note_history_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  final now = DateTime(2026, 9, 15, 9);

  group('DiffView', () {
    Widget app(String oldText, String newText) => MaterialApp(
      home: Scaffold(
        body: DiffView(oldText: oldText, newText: newText),
      ),
    );

    testWidgets('marks removed and added lines and folds the rest', (
      tester,
    ) async {
      final old = [for (var i = 1; i <= 20; i++) 'line $i'];
      final changed = [...old]..[17] = 'line 18 edited';
      await tester.pumpWidget(app(old.join('\n'), changed.join('\n')));
      await tester.pump();

      expect(find.text('line 18'), findsOneWidget);
      expect(find.text('line 18 edited'), findsOneWidget);
      // Lines 1..14 are folded before the hunk (context 3 around line 18).
      expect(find.text('line 1'), findsNothing);
      expect(find.text('14 unchanged lines'), findsOneWidget);
      expect(find.text('Lines 15–20'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('diff-gap-0')));
      await tester.pump();
      expect(find.text('line 1'), findsOneWidget);
      expect(find.text('14 unchanged lines'), findsNothing);
    });

    testWidgets('says so when nothing changed', (tester) async {
      await tester.pumpWidget(app('same\n', 'same'));
      await tester.pump();
      expect(find.byKey(const Key('diff-identical')), findsOneWidget);
    });
  });

  group('history screens', () {
    late FakeLibrarySession session;

    setUp(() async {
      session = FakeLibrarySession();
      await session.open('/lib', create: false);
      await session.seedFile('Plan.md', content: 'current\ntext\n');
      session
        ..seedVersion(
          'Plan.md',
          number: 1,
          savedAt: DateTime(2026, 9, 12, 9, 15),
          text: 'first\n',
        )
        ..seedVersion(
          'Plan.md',
          number: 2,
          savedAt: DateTime(2026, 9, 14, 18, 2),
          text: 'first\nsecond\n',
          reason: HistoryReason.interval,
          pin: syncBasePin,
        )
        ..seedVersion(
          'Plan.md',
          number: 3,
          savedAt: DateTime(2026, 9, 15, 8, 24),
          text: 'old\ntext\n',
        );
    });

    tearDown(() async {
      await session.close();
      await session.dispose();
    });

    Future<HistoryVersion?> pumpHistory(WidgetTester tester) async {
      HistoryVersion? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<HistoryVersion>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteHistoryScreen(
                        ops: session,
                        path: 'Plan.md',
                        limit: 10,
                        now: () => now,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('lists versions newest first, by day, with the sync base', (
      tester,
    ) async {
      await pumpHistory(tester);

      expect(find.byKey(const Key('history-current')), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('12 Sep'), findsOneWidget);
      expect(find.text('08:24'), findsOneWidget);
      expect(find.byKey(const Key('history-sync-base')), findsOneWidget);
      expect(find.text('before editing'), findsNWidgets(2));
      // v2 against v1 added one line.
      expect(find.text('+1 −0'), findsOneWidget);
      // The pinned base is not counted against the limit.
      expect(find.textContaining('2 of 10 versions kept'), findsOneWidget);

      final today = tester.getTopLeft(find.text('08:24')).dy;
      final older = tester.getTopLeft(find.text('09:15')).dy;
      expect(today, lessThan(older));
    });

    testWidgets('a version shows its diff, its text, and restores', (
      tester,
    ) async {
      HistoryVersion? restored;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  restored = await Navigator.push<HistoryVersion>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteHistoryScreen(
                        ops: session,
                        path: 'Plan.md',
                        limit: 10,
                        now: () => now,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('history-version-3')));
      await tester.pumpAndSettle();
      expect(find.text('Today, 08:24'), findsOneWidget);
      expect(find.text('old'), findsOneWidget);
      expect(find.text('current'), findsOneWidget);

      await tester.tap(find.text('Version'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-version-text')), findsOneWidget);

      await tester.tap(find.byKey(const Key('history-restore')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-restore-dialog')), findsOneWidget);
      expect(find.text('Restore the version of today, 08:24?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('history-restore-confirm')));
      await tester.pumpAndSettle();

      expect(session.restores, [('Plan.md', 3)]);
      expect(session.contentOf('Plan.md'), 'old\ntext\n');
      expect(restored?.number, 3);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('an empty history explains when versions appear', (
      tester,
    ) async {
      await session.seedFile('Empty.md', content: 'x');
      await tester.pumpWidget(
        MaterialApp(
          home: NoteHistoryScreen(
            ops: session,
            path: 'Empty.md',
            limit: 10,
            now: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('history-empty')), findsOneWidget);
    });
  });

  group('entry points', () {
    late FakeLibrarySession controller;
    late FakeFilePicker filePicker;

    setUp(() {
      controller = FakeLibrarySession();
      filePicker = useFakeFilePicker();
    });

    tearDown(() async {
      await controller.close();
      await controller.dispose();
    });

    testWidgets('the tree menu opens the history of a note, not a folder', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [librarySessionProvider.overrideWithValue(controller)],
          child: const NimanApp(),
        ),
      );
      await tester.pump();
      await openLibrary(tester, filePicker);
      await controller.createNote(parentPath: '', name: 'Note');
      await controller.createFolder(parentPath: '', name: 'Folder');
      await settle(tester);

      await tester.longPress(noteRow('Folder'));
      await settle(tester);
      expect(find.byKey(const Key('menu-history')), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);

      await tester.longPress(noteRow('Note.md'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('menu-history')));
      await settle(tester);
      expect(find.byType(NoteHistoryScreen), findsOneWidget);
    });
  });
}
