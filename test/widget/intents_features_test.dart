// #1109: the ways into the app from outside follow the library's features.
// Shared text with Quick note off is imported as a note; a web page with
// Web capture off is plain text; a shortcut, a notification or a widget tap
// for a feature that is off says so in one sentence instead of opening a
// screen that is not there.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/intent_features.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_share_service.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_widget_target_service.dart';
import '../fakes/shell_harness.dart';

Features _off(LibraryFeature feature, [LibraryFeature? also]) {
  var features = const Features().withSwitch(feature, on: false);
  if (also != null) features = features.withSwitch(also, on: false);
  return features;
}

void main() {
  group('the classifiers', () {
    test('every shortcut answers a feature or core', () {
      expect(
        featureOfShortcut(ShortcutAction.quickNote),
        LibraryFeature.quickNote,
      );
      expect(
        featureOfShortcut(ShortcutAction.journalToday),
        LibraryFeature.journal,
      );
      expect(featureOfShortcut(ShortcutAction.newTodo), LibraryFeature.todo);
      expect(
        featureOfShortcut(ShortcutAction.newList),
        LibraryFeature.kindList,
      );
      expect(
        featureOfShortcut(ShortcutAction.newVoice),
        LibraryFeature.kindAudio,
      );
      expect(featureOfShortcut(ShortcutAction.newNote), isNull);
    });

    test('a notification answers the feature it leads to', () {
      expect(
        featureOfReminderPayload(todoReminderPayload),
        LibraryFeature.todo,
      );
      expect(
        featureOfReminderPayload(journalReminderPayload(DateTime(2026, 3, 4))),
        LibraryFeature.calendar,
      );
      expect(featureOfReminderPayload('capture-open:a.md'), isNull);
      expect(featureOfReminderPayload(null), isNull);
    });

    test('a widget tap answers the feature it opens', () {
      expect(featureOfWidgetTarget(WidgetTargetKind.todo), LibraryFeature.todo);
      expect(
        featureOfWidgetTarget(WidgetTargetKind.study),
        LibraryFeature.kindFlashcards,
      );
      expect(featureOfWidgetTarget(WidgetTargetKind.note), isNull);
      expect(featureOfWidgetTarget(WidgetTargetKind.features), isNull);
    });

    test('shared text goes where its switches say', () {
      const on = Features();
      SharedTextRoute route(Features f, {required bool web}) =>
          sharedTextRoute(isWebPage: web, features: f);
      expect(route(on, web: true), SharedTextRoute.capture);
      expect(route(on, web: false), SharedTextRoute.quickNote);
      // No capture: the link is plain text, for the quick note.
      expect(
        route(_off(LibraryFeature.capture), web: true),
        SharedTextRoute.quickNote,
      );
      // No quick note: imported, a web page too when capture is off.
      expect(
        route(_off(LibraryFeature.quickNote), web: false),
        SharedTextRoute.importAsNote,
      );
      expect(
        route(_off(LibraryFeature.quickNote), web: true),
        SharedTextRoute.capture,
      );
      expect(
        route(
          _off(LibraryFeature.quickNote, LibraryFeature.capture),
          web: true,
        ),
        SharedTextRoute.importAsNote,
      );
    });

    test('imported text is named by its subject, else its first line', () {
      expect(sharedTextNoteName('body', subject: 'A: title?'), 'A title');
      expect(sharedTextNoteName('\n\n  First line \nsecond'), 'First line');
      expect(sharedTextNoteName('   \n'), 'Shared');
      expect(sharedTextNoteName('x' * 100).length, 60);
      expect(sharedTextNoteName('...hidden'), 'hidden');
    });
  });

  group('in the shell', () {
    late FakeLibrarySession controller;
    late FakeShareInService shares;
    late FakeShortcutService shortcuts;
    late FakeWidgetTargetService targets;
    late FakeReminderService reminders;
    late FakeFilePicker filePicker;
    final home = p.join('/fake', 'library');

    setUp(() {
      controller = FakeLibrarySession();
      shares = FakeShareInService();
      shortcuts = FakeShortcutService();
      targets = FakeWidgetTargetService();
      reminders = FakeReminderService();
      filePicker = useFakeFilePicker();
    });

    Future<void> pump(WidgetTester tester) async {
      setSurfaceSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            librarySessionProvider.overrideWithValue(controller),
            shortcutServiceProvider.overrideWithValue(shortcuts),
            shareInServiceProvider.overrideWithValue(shares),
            widgetTargetServiceProvider.overrideWithValue(targets),
            reminderServiceProvider.overrideWithValue(reminders),
            todoSourceFactoryProvider.overrideWithValue(
              (_) => FakeTodoSource(),
            ),
          ],
          child: const NimanApp(),
        ),
      );
      await tester.pump();
      await openLibrary(tester, filePicker);
    }

    Future<void> close() async {
      await controller.close();
      await controller.dispose();
      await shares.dispose();
      await shortcuts.dispose();
      await targets.dispose();
      await reminders.dispose();
    }

    Finder sentence(String text) => find.text(text);

    testWidgets('shared text with Quick note off becomes a note', (
      tester,
    ) async {
      await pump(tester);
      await controller.seedFile('Quick note.md', content: 'existing');
      await controller.setQuickNotePath(path: 'Quick note.md');
      controller.features.value = _off(LibraryFeature.quickNote);

      shares.emit(const SharedText('Milk\nand bread', subject: 'Shopping'));
      await settle(tester);

      expect(controller.contentOf('Shopping.md'), 'Milk\nand bread');
      expect(
        controller.contentOf('Quick note.md'),
        'existing',
        reason: 'the quick note was not touched',
      );
      await close();
    });

    testWidgets('shared text with Quick note on still goes to it', (
      tester,
    ) async {
      await pump(tester);
      await controller.seedFile('Quick note.md', content: 'existing');
      await controller.setQuickNotePath(path: 'Quick note.md');

      shares.emit(const SharedText('Milk', subject: 'Shopping'));
      await settle(tester);

      expect(controller.contentOf('Quick note.md'), 'existing\n\nMilk');
      expect(controller.contentOf('Shopping.md'), isNull);
      await close();
    });

    testWidgets('a shared link with capture off is plain text', (tester) async {
      await pump(tester);
      await controller.seedFile('Quick note.md', content: 'existing');
      await controller.setQuickNotePath(path: 'Quick note.md');
      controller.features.value = _off(LibraryFeature.capture);

      shares.emit(const SharedText('https://example.com/garden'));
      await settle(tester);

      expect(find.byKey(const Key('capture-sheet')), findsNothing);
      expect(
        controller.contentOf('Quick note.md'),
        'existing\n\nhttps://example.com/garden',
      );
      await close();
    });

    testWidgets('a shortcut for a feature that is off says so', (tester) async {
      await pump(tester);
      controller.features.value = _off(LibraryFeature.journal);

      shortcuts.emit(ShortcutAction.journalToday);
      await settle(tester);
      expect(sentence('Journal is off in this library'), findsOneWidget);
      // Nothing was made for it.
      expect(await controller.ops!.find('Journal'), isNull);

      // A feature that is on still runs.
      shortcuts.emit(ShortcutAction.newTodo);
      await settle(tester);
      expect(find.byKey(const Key('todo-dialog-save')), findsOneWidget);
      await close();
    });

    testWidgets('a shortcut for Todo off says so, a voice note too', (
      tester,
    ) async {
      await pump(tester);
      controller.features.value = _off(
        LibraryFeature.todo,
        LibraryFeature.kindAudio,
      );

      shortcuts.emit(ShortcutAction.newTodo);
      await settle(tester);
      expect(sentence('Todo is off in this library'), findsOneWidget);
      expect(find.byKey(const Key('todo-dialog-save')), findsNothing);

      shortcuts.emit(ShortcutAction.newVoice);
      await settle(tester);
      expect(
        sentence('This feature is off in this library'),
        findsOneWidget,
        reason: 'no name among the strings yet: the unnamed form',
      );
      await close();
    });

    testWidgets('a todo reminder for Todo off says so', (tester) async {
      await pump(tester);
      controller.features.value = _off(LibraryFeature.todo);

      reminders.tap(todoReminderPayload);
      await settle(tester);
      expect(sentence('Todo is off in this library'), findsOneWidget);
      expect(find.text(AppStrings.todoEmptyOpen), findsNothing);

      controller.features.value = const Features();
      reminders.tap(todoReminderPayload);
      await settle(tester);
      expect(find.text(AppStrings.todoEmptyOpen), findsOneWidget);
      await close();
    });

    testWidgets('an event reminder for Calendar off says so', (tester) async {
      await pump(tester);
      controller.features.value = _off(LibraryFeature.calendar);

      reminders.tap(journalReminderPayload(DateTime(2026, 3, 4)));
      await settle(tester);
      expect(sentence('Calendar is off in this library'), findsOneWidget);
      await close();
    });

    testWidgets('a widget tap for Todo or Study off says so', (tester) async {
      await pump(tester);
      controller.features.value = _off(
        LibraryFeature.todo,
        LibraryFeature.kindFlashcards,
      );

      targets.emit(
        WidgetTarget(kind: WidgetTargetKind.todo, libraryPath: home),
      );
      await settle(tester);
      expect(sentence('Todo is off in this library'), findsOneWidget);

      targets.emit(
        WidgetTarget(kind: WidgetTargetKind.study, libraryPath: home),
      );
      await settle(tester);
      expect(sentence('Flashcards is off in this library'), findsOneWidget);
      await close();
    });

    testWidgets('a widget tap on Open Features is never refused', (
      tester,
    ) async {
      await pump(tester);
      controller.features.value = _off(
        LibraryFeature.todo,
        LibraryFeature.widgets,
      );

      targets.emit(
        WidgetTarget(kind: WidgetTargetKind.features, libraryPath: home),
      );
      await settle(tester);
      expect(find.textContaining('is off in this library'), findsNothing);
      await close();
    });
  });
}
