// #351: the switch screen saves the open notes before the library goes,
// as the library window does, and a note that will not save keeps it open.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/switch_library_screen.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

/// An open note whose write is the session's own `saveNote`, so a test can
/// hold it in flight ([FakeLibrarySession.saveGate]) or fail it.
final class _OpenNote implements UnsavedNote {
  new(this.session, this.path);

  final FakeLibrarySession session;

  @override
  final String path;

  @override
  bool unsaved = true;

  @override
  Future<void> save() async {
    await session.saveNote(path, 'edited');
    unsaved = false;
  }
}

final class _SaveFailed implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => message;
}

void main() {
  late FakeLibrarySession session;
  late UnsavedTracker unsaved;
  late Directory tmp;
  late String work;
  late String personal;

  setUp(() async {
    session = FakeLibrarySession();
    unsaved = UnsavedTracker();
    tmp = await Directory.current.createTemp('niman_switch_');
    work = _makeLibrary(tmp, 'Work');
    personal = _makeLibrary(tmp, 'Personal');
    session
      ..seedKnownLibrary(personal, lastOpened: DateTime(2026, 9, 1, 10))
      ..seedKnownLibrary(work, lastOpened: DateTime(2026, 9, 9, 10));
    await session.open(work, create: false);
  });

  tearDown(() async {
    await session.dispose();
    await tmp.delete(recursive: true);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SwitchLibraryScreen(
          controller: session,
          unsaved: unsaved,
          onSwitched: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the switch screen', () {
    testWidgets('lists every known library', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(Key('known-library-$work')), findsOne);
      expect(find.byKey(Key('known-library-$personal')), findsOne);
    });

    testWidgets('marks the one that is open', (tester) async {
      await pumpScreen(tester);
      expect(find.text(AppStrings.libraryOpenNow), findsOne);
      final tile = tester.widget<ListTile>(
        find.byKey(Key('known-library-$work')),
      );
      expect(tile.selected, isTrue);
    });

    testWidgets('picking another one swaps the open library', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(Key('known-library-$personal')));
      await tester.pumpAndSettle();
      expect(session.root, personal);
    });

    testWidgets('picking the open one changes nothing', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(Key('known-library-$work')));
      await tester.pumpAndSettle();
      expect(session.root, work);
    });

    // #351: the switch waits for the open note's write, and the library it
    // is leaving stays on screen until that write has landed.
    testWidgets('switching waits for the open notes', (tester) async {
      final note = _OpenNote(session, 'note.md');
      final pending = Completer<void>();
      session.saveGate = pending;
      unsaved.register(note);
      await pumpScreen(tester);

      await tester.tap(find.byKey(Key('known-library-$personal')));
      await tester.pump();

      expect(session.saves, hasLength(1), reason: 'the write is on the wire');
      expect(session.root, work, reason: 'the library has not gone');
      expect(find.byKey(Key('known-library-$personal')), findsOne);

      pending.complete();
      await tester.pumpAndSettle();
      expect(note.unsaved, isFalse);
      expect(session.root, personal);
    });

    testWidgets('a note that will not save keeps the library open', (
      tester,
    ) async {
      session.saveError = const _SaveFailed('disk full');
      unsaved.register(_OpenNote(session, 'note.md'));
      await pumpScreen(tester);

      await tester.tap(find.byKey(Key('known-library-$personal')));
      await tester.pumpAndSettle();

      expect(session.root, work);
      expect(find.byKey(Key('known-library-$personal')), findsOne);
      expect(find.textContaining('disk full'), findsOne);

      // The library is still open, and the same pick goes through once
      // the write can land.
      session.saveError = null;
      await tester.tap(find.byKey(Key('known-library-$personal')));
      await tester.pumpAndSettle();
      expect(session.root, personal);
    });

    testWidgets('the open library can be forgotten, and closes first', (
      tester,
    ) async {
      // #286: nothing stops the list from dropping the library on screen,
      // and the answer says the two things happen in order.
      await pumpScreen(tester);
      await tester.longPress(find.byKey(Key('known-library-$work')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.libraryForgetTitle('Work')), findsOne);
      expect(find.text(AppStrings.libraryForgetOpenExplained), findsOne);

      await tester.tap(find.byKey(const Key('confirm-forget-library')));
      await tester.pumpAndSettle();

      expect(session.root, isNull);
      expect(
        (await session.knownLibraries()).map((entry) => entry.path),
        isNot(contains(work)),
      );
      // Forgetting is a list operation; the folder is a library still.
      expect(Directory(work).existsSync(), isTrue);
    });

    testWidgets('forgetting the open library saves the notes first', (
      tester,
    ) async {
      // #286 on the phone: the library on screen leaves the same way a
      // switch does, and forgetting is not a way to drop its open notes.
      final note = _OpenNote(session, 'note.md');
      unsaved.register(note);
      await pumpScreen(tester);

      await tester.longPress(find.byKey(Key('known-library-$work')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-forget-library')));
      await tester.pumpAndSettle();

      expect(session.saves, hasLength(1));
      expect(note.unsaved, isFalse);
      expect(session.root, isNull);
    });

    testWidgets('another one still can be', (tester) async {
      await pumpScreen(tester);
      await tester.longPress(find.byKey(Key('known-library-$personal')));
      await tester.pumpAndSettle();
      // Not the open one, so the plain answer — it stays where it is.
      expect(find.text(AppStrings.libraryForgetExplained), findsOne);
      await tester.tap(find.byKey(const Key('confirm-forget-library')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('known-library-$personal')), findsNothing);
      expect(Directory(personal).existsSync(), isTrue);
    });
  });

  group('the settings row', () {
    Future<void> pumpSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsBody(controller: session, unsaved: unsaved),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens the same list', (tester) async {
      await pumpSettings(tester);
      // The row sits in the home's Maintenance group (issue #104).
      await tester.tap(find.byKey(const Key('switch-library-setting')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.switchLibraryTitle), findsWidgets);
      expect(find.byKey(Key('known-library-$personal')), findsOne);
    });

    testWidgets('and switching from it lands on the other library', (
      tester,
    ) async {
      // #351: the row's screen has the session's tracker — the open notes
      // are written before the shell the row belongs to goes.
      final note = _OpenNote(session, 'note.md');
      unsaved.register(note);
      await pumpSettings(tester);
      await tester.tap(find.byKey(const Key('switch-library-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('known-library-$personal')));
      await tester.pumpAndSettle();
      expect(session.saves, hasLength(1));
      expect(session.root, personal);
      // The list went with the library it belonged to; what is left is
      // the settings row that opened it.
      expect(find.byKey(Key('known-library-$personal')), findsNothing);
    });
  });
}

String _makeLibrary(Directory parent, String name) {
  return (Directory(p.join(parent.path, name))..createSync()).path;
}
