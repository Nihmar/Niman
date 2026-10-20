// #1109, the seam in a built shell: a feature that is off offers none of
// its commands — in the palette, on its key, in the phone's + menu, in the
// destinations — and on again brings them back. Switching writes nothing
// to Navigation, and a palette query that matched only the commands of a
// feature that is off says so.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Features offFeatures(Iterable<LibraryFeature> features) =>
      [for (final feature in features) feature]
          .fold(const Features(), (all, f) => all.withSwitch(f, on: false));

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> keys(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool shift = false,
  }) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  Future<void> openPalette(WidgetTester tester, [String? query]) async {
    await keys(tester, LogicalKeyboardKey.keyP, shift: true);
    if (query == null) return;
    await tester.enterText(find.byKey(const Key('palette-field')), query);
    await settle(tester);
  }

  Future<void> closePalette(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
  }

  Set<AppCommand> offered(WidgetTester tester) => {
    for (final command
        in tester.widget<CommandPalette>(find.byType(CommandPalette)).commands)
      command.command,
  };

  String todayPath() {
    const journal = JournalSettings();
    return journal.entryPath(journal.today(DateTime.now()));
  }

  group('commands', () {
    // One feature of each kind: a planning one, finding, a note kind.
    final cases = <(LibraryFeature, AppCommand, String)>[
      (LibraryFeature.todo, AppCommand.newTodo, 'new todo'),
      (LibraryFeature.search, AppCommand.focusSearch, 'focus search'),
      (LibraryFeature.kindSlides, AppCommand.newSlides, 'new slides'),
      (LibraryFeature.journal, AppCommand.journalToday, 'journal'),
    ];
    for (final (feature, command, query) in cases) {
      testWidgets('${feature.id} off: the palette lists no ${command.name}, '
          'and on again lists it', (tester) async {
        await pumpAt(tester, const Size(1400, 900));
        await openPalette(tester, query);
        expect(offered(tester), contains(command));
        await closePalette(tester);

        controller.features.value = offFeatures([feature]);
        await settle(tester);
        await openPalette(tester, query);
        expect(offered(tester), isNot(contains(command)));
        await closePalette(tester);

        controller.features.value = const Features();
        await settle(tester);
        await openPalette(tester, query);
        expect(offered(tester), contains(command));
      });
    }

    testWidgets('a key of a feature that is off does nothing', (tester) async {
      await pumpAt(tester, const Size(1400, 900));
      controller.features.value = offFeatures([LibraryFeature.journal]);
      await settle(tester);

      await keys(tester, LogicalKeyboardKey.keyJ, shift: true);
      expect(controller.contentOf(todayPath()), isNull);

      controller.features.value = const Features();
      await settle(tester);
      await keys(tester, LogicalKeyboardKey.keyJ, shift: true);
      expect(controller.contentOf(todayPath()), startsWith('# '));
    });

    testWidgets("the phone's + menu leaves out what is off", (tester) async {
      await pumpAt(tester, const Size(390, 844));
      controller.features.value = offFeatures([
        LibraryFeature.journal,
        LibraryFeature.templates,
        LibraryFeature.kindSlides,
        LibraryFeature.capture,
      ]);
      await settle(tester);
      await tester.tap(find.byKey(const Key('new-note-fab')));
      await settleFabMenu(tester);

      for (final key in [
        'journal-today-action',
        'new-from-template-action',
        'new-slides-action',
        'capture-web-page-action',
      ]) {
        expect(find.byKey(Key(key)), findsNothing, reason: key);
      }
      // What stays keeps working.
      expect(find.byKey(const Key('new-note-action')), findsOne);
      expect(find.byKey(const Key('new-flashcards-action')), findsOne);
    });

    testWidgets("the desktop's + New menu leaves out what is off", (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      controller.features.value = offFeatures([
        LibraryFeature.journal,
        LibraryFeature.kindAudio,
        LibraryFeature.templates,
      ]);
      await settle(tester);
      await openNewItemMenu(tester);

      for (final key in [
        'journal-today-action',
        'new-audio-note-action',
        'new-from-template-action',
      ]) {
        expect(find.byKey(Key(key)), findsNothing, reason: key);
      }
      expect(find.byKey(const Key('new-note-action')), findsOne);
      expect(find.byKey(const Key('new-slides-action')), findsOne);
      expect(find.byKey(const Key('new-folder-action')), findsOne);
    });

    testWidgets('the File bar drops the journal with it', (tester) async {
      await pumpAt(tester, const Size(390, 844));
      expect(find.byKey(const Key('open-journal')), findsOne);
      controller.features.value = offFeatures([LibraryFeature.journal]);
      await settle(tester);
      expect(find.byKey(const Key('open-journal')), findsNothing);
    });
  });

  group('the palette says why', () {
    testWidgets('a query that matched only commands of an off feature', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      controller.features.value = offFeatures([LibraryFeature.todo]);
      await settle(tester);

      await openPalette(tester, 'new todo');
      expect(
        tester.widget<Text>(find.byKey(const Key('palette-feature-off'))).data,
        AppStrings.featureOffInLibraryNamed(AppStrings.featureNameTodo),
      );
      expect(find.byKey(const Key('palette-feature-link')), findsOne);
    });

    testWidgets('no line while the feature is on, or a command matched', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      await openPalette(tester, 'new todo');
      expect(find.byKey(const Key('palette-feature-off')), findsNothing);
      await closePalette(tester);

      // "new" matches the commands of the notes too: the line is for a
      // query that found no command at all.
      controller.features.value = offFeatures([LibraryFeature.todo]);
      await settle(tester);
      await openPalette(tester, 'new');
      expect(find.byKey(const Key('palette-feature-off')), findsNothing);
    });

    testWidgets('its link closes the palette and opens Settings', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      controller.features.value = offFeatures([LibraryFeature.todo]);
      await settle(tester);
      await openPalette(tester, 'new todo');

      await tester.tap(find.byKey(const Key('palette-feature-link')));
      await settle(tester);
      expect(find.byKey(const Key('command-palette')), findsNothing);
      expect(find.byKey(const Key('settings-window')), findsOne);
    });
  });

  group('destinations', () {
    testWidgets('a feature that is off leaves the rail, and writes nothing', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1200, 900));
      expect(find.byKey(const Key('rail-todo')), findsOne);
      expect(find.byKey(const Key('rail-search')), findsOne);

      controller.features.value = offFeatures([
        LibraryFeature.todo,
        LibraryFeature.search,
      ]);
      await settle(tester);
      expect(find.byKey(const Key('rail-todo')), findsNothing);
      expect(find.byKey(const Key('rail-search')), findsNothing);
      // The layout is where it was left.
      final saved = await controller.navigation;
      expect(saved.library, isNull);
      expect(saved.device, isNull);

      controller.features.value = const Features();
      await settle(tester);
      expect(find.byKey(const Key('rail-todo')), findsOne);
      expect(find.byKey(const Key('rail-search')), findsOne);
    });

    testWidgets('the phone: the bar follows, and the tab on screen gives way', (
      tester,
    ) async {
      await pumpAt(tester, const Size(390, 844));
      await tester.tap(find.byKey(const Key('tab-todo')));
      await settle(tester);
      expect(
        tester.widget<ShellTabBar>(find.byType(ShellTabBar)).current,
        ShellTab.todo,
      );

      controller.features.value = offFeatures([LibraryFeature.todo]);
      await settle(tester);
      expect(find.byKey(const Key('tab-todo')), findsNothing);
      expect(
        tester.widget<ShellTabBar>(find.byType(ShellTabBar)).current,
        isNot(ShellTab.todo),
      );
    });

    testWidgets('a destination command of an off feature is not offered', (
      tester,
    ) async {
      await pumpAt(tester, const Size(1400, 900));
      controller.features.value = offFeatures([LibraryFeature.home]);
      await settle(tester);
      await openPalette(tester, 'go');
      expect(offered(tester), isNot(contains(AppCommand.tabHome)));
      expect(offered(tester), contains(AppCommand.tabSettings));
    });
  });
}
