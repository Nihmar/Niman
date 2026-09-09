import 'dart:io';

import 'package:copist/src/ui/settings.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/switch_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;
  late Directory tmp;
  late String work;
  late String personal;

  setUp(() async {
    session = FakeLibrarySession();
    tmp = await Directory.current.createTemp('copist_switch_');
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
        home: SwitchLibraryScreen(controller: session, onSwitched: () {}),
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

    testWidgets('the open library cannot be forgotten', (tester) async {
      // Nothing to stop listing: it is the library on screen.
      await pumpScreen(tester);
      await tester.longPress(find.byKey(Key('known-library-$work')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.libraryForgetTitle('Work')), findsNothing);
    });

    testWidgets('another one still can be', (tester) async {
      await pumpScreen(tester);
      await tester.longPress(find.byKey(Key('known-library-$personal')));
      await tester.pumpAndSettle();
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
          home: Scaffold(body: SettingsBody(controller: session)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('opens the same list', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const Key('switch-library-setting')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.switchLibraryTitle), findsWidgets);
      expect(find.byKey(Key('known-library-$personal')), findsOne);
    });

    testWidgets('and switching from it lands on the other library', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const Key('switch-library-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('known-library-$personal')));
      await tester.pumpAndSettle();
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
