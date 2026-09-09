import 'dart:io';

import 'package:copist/src/ui/open_library.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;
  late Directory tmp;

  setUp(() async {
    session = FakeLibrarySession();
    // Real folders: the list checks whether each one is still there, and
    // a row for a missing folder is supposed to say so.
    tmp = await Directory.current.createTemp('copist_home_');
  });

  tearDown(() async {
    await session.dispose();
    await tmp.delete(recursive: true);
  });

  /// An existing library folder under the temp dir.
  String makeLibrary(String name) {
    final dir = Directory(p.join(tmp.path, name))..createSync();
    return dir.path;
  }

  Future<void> pump(WidgetTester tester, {double width = 900}) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: OpenLibraryScreen(controller: session)),
    );
    await tester.pumpAndSettle();
  }

  group('a first run', () {
    testWidgets('is the welcome screen it always was', (tester) async {
      await pump(tester);
      expect(find.byKey(const Key('branding')), findsOne);
      expect(find.text(AppStrings.openLibraryIntro), findsOne);
      expect(find.text(AppStrings.knownLibrariesTitle), findsNothing);
    });

    testWidgets('has no app bar repeating the name below it', (tester) async {
      // The feather and the name are a few pixels down (user,
      // 2026-09-09); the bar cost a bar's worth of the list.
      await pump(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text(AppStrings.appTitle), findsOne);
    });

    testWidgets('offers open and create as the main action', (tester) async {
      await pump(tester);
      expect(find.byType(FilledButton), findsWidgets);
      expect(find.byKey(const Key('open-existing-library')), findsOne);
      expect(find.byKey(const Key('create-library')), findsOne);
    });
  });

  group('with libraries to list', () {
    testWidgets('the branding header stays above the list', (tester) async {
      session.seedKnownLibrary(makeLibrary('Work'));
      await pump(tester);
      expect(find.byKey(const Key('branding')), findsOne);
      expect(find.text(AppStrings.knownLibrariesTitle), findsOne);
    });

    testWidgets('the one-line intro gives way to the list', (tester) async {
      session.seedKnownLibrary(makeLibrary('Work'));
      await pump(tester);
      expect(find.text(AppStrings.openLibraryIntro), findsNothing);
    });

    testWidgets('a row shows the name and the path', (tester) async {
      final path = makeLibrary('Work');
      session.seedKnownLibrary(path);
      await pump(tester);
      final row = find.byKey(Key('known-library-$path'));
      expect(row, findsOne);
      expect(find.descendant(of: row, matching: find.text('Work')), findsOne);
      // Two libraries can share a name; the path is what tells them apart.
      expect(find.descendant(of: row, matching: find.text(path)), findsOne);
    });

    testWidgets('rows read most recently opened first', (tester) async {
      final older = makeLibrary('Older');
      final newer = makeLibrary('Newer');
      session
        ..seedKnownLibrary(older, lastOpened: DateTime(2026, 9, 1, 10))
        ..seedKnownLibrary(newer, lastOpened: DateTime(2026, 9, 9, 10));
      await pump(tester);
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(tiles.map((t) => (t.key! as ValueKey<String>).value), [
        'known-library-$newer',
        'known-library-$older',
      ]);
    });

    testWidgets('tapping a row opens that library', (tester) async {
      final path = makeLibrary('Work');
      session.seedKnownLibrary(path);
      await pump(tester);
      await tester.tap(find.byKey(Key('known-library-$path')));
      await tester.pumpAndSettle();
      expect(session.root, path);
    });

    testWidgets('open and create step back to plain buttons', (tester) async {
      // The list is what the screen is about once there is one.
      session.seedKnownLibrary(makeLibrary('Work'));
      await pump(tester);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byKey(const Key('open-existing-library')), findsOne);
      expect(find.byKey(const Key('create-library')), findsOne);
    });
  });

  group('a library that is not there', () {
    testWidgets('says so instead of opening onto an empty tree', (
      tester,
    ) async {
      final gone = p.join(tmp.path, 'Unplugged');
      session.seedKnownLibrary(gone, name: 'Unplugged');
      await pump(tester);
      expect(find.text(AppStrings.libraryUnreachable), findsOne);
    });

    testWidgets('a reachable one shows when it was last opened', (
      tester,
    ) async {
      session.seedKnownLibrary(makeLibrary('Work'), lastOpened: DateTime.now());
      await pump(tester);
      expect(find.text(AppStrings.libraryOpenedToday), findsOne);
      expect(find.text(AppStrings.libraryUnreachable), findsNothing);
    });
  });

  group('forgetting a library', () {
    testWidgets('asks first, and says what it does not touch', (tester) async {
      final path = makeLibrary('Work');
      session.seedKnownLibrary(path);
      await pump(tester);
      await tester.longPress(find.byKey(Key('known-library-$path')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.libraryForgetTitle('Work')), findsOne);
      expect(find.text(AppStrings.libraryForgetExplained), findsOne);
    });

    testWidgets('cancelling keeps the row', (tester) async {
      final path = makeLibrary('Work');
      session.seedKnownLibrary(path);
      await pump(tester);
      await tester.longPress(find.byKey(Key('known-library-$path')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.actionCancel));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('known-library-$path')), findsOne);
    });

    testWidgets('confirming drops the row and leaves the folder', (
      tester,
    ) async {
      final path = makeLibrary('Work');
      session.seedKnownLibrary(path);
      await pump(tester);
      await tester.longPress(find.byKey(Key('known-library-$path')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-forget-library')));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('known-library-$path')), findsNothing);
      expect(await session.knownLibraries(), isEmpty);
      // Forgetting is a list operation; the folder is still a library.
      expect(Directory(path).existsSync(), isTrue);
    });

    testWidgets('the last row leaves the welcome screen behind', (
      tester,
    ) async {
      final path = makeLibrary('Work');
      session.seedKnownLibrary(path);
      await pump(tester);
      await tester.longPress(find.byKey(Key('known-library-$path')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-forget-library')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.openLibraryIntro), findsOne);
    });
  });
}
