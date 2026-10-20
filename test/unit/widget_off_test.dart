// #1109 phase 5: a home-screen widget whose feature -- or the Home-screen
// widgets switch -- is off is sent the off payload (the sentence and the
// button) and nothing else is written for it; on again, it gets its data.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/shell_home_widgets.dart';
import 'package:niman/src/widget/study_widget.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_off.dart';
import 'package:niman/src/widget/widget_refresh.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_widget_host_service.dart';
import '../fakes/fake_widget_pin_store.dart';
import '../fakes/fake_widget_target_service.dart';

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  Features without(LibraryFeature feature) =>
      const Features().withSwitch(feature, on: false);

  group('which switch keeps a widget off', () {
    test('every feature on: none', () {
      for (final provider in WidgetProvider.values) {
        expect(widgetOffFeature(provider, const Features()), isNull);
      }
    });

    test('the todo widget follows todo, the study widget flashcards', () {
      expect(
        widgetOffFeature(WidgetProvider.todo, without(LibraryFeature.todo)),
        LibraryFeature.todo,
      );
      expect(
        widgetOffFeature(
          WidgetProvider.study,
          without(LibraryFeature.kindFlashcards),
        ),
        LibraryFeature.kindFlashcards,
      );
      // Not each other's.
      expect(
        widgetOffFeature(WidgetProvider.study, without(LibraryFeature.todo)),
        isNull,
      );
      expect(
        widgetOffFeature(
          WidgetProvider.todo,
          without(LibraryFeature.kindFlashcards),
        ),
        isNull,
      );
    });

    test('the note widget has no feature but the widgets switch', () {
      for (final feature in LibraryFeature.values) {
        if (feature == LibraryFeature.widgets) continue;
        expect(widgetOffFeature(WidgetProvider.note, without(feature)), isNull);
      }
    });

    test('the widgets switch turns all three off, and speaks first', () {
      final off = without(LibraryFeature.widgets)
          .withSwitch(LibraryFeature.todo, on: false);
      for (final provider in WidgetProvider.values) {
        expect(widgetOffFeature(provider, off), LibraryFeature.widgets);
      }
    });
  });

  group('the off payload', () {
    Map<String, Object?> payload(LibraryFeature feature) =>
        jsonDecode(widgetOffPayload(feature: feature, libraryPath: '/lib'))
            as Map<String, Object?>;

    test('names the library, the feature, the sentence and the button', () {
      final todo = payload(LibraryFeature.todo);
      expect(todo['library'], '/lib');
      expect(todo['off'], {
        'feature': 'todo',
        'text': 'Todo is off in this library',
        'action': 'Open Features',
      });
      expect(
        todo.containsKey('rows'),
        isFalse,
        reason: 'no data rides with it',
      );
      expect(
        (payload(LibraryFeature.kindFlashcards)['off']! as Map)['text'],
        'Study is off in this library',
      );
      expect(
        (payload(LibraryFeature.widgets)['off']! as Map)['text'],
        'Home-screen widgets are off in this library',
      );
    });

    test('is written in the app language', () {
      AppLanguages.choice = AppLanguage.italian;
      final off = payload(LibraryFeature.todo);
      expect(off['language'], 'it');
      expect((off['off']! as Map)['action'], 'Apri Funzioni');
    });

    test('every language has the sentences and the button', () {
      final english = {
        for (final feature in [
          LibraryFeature.todo,
          LibraryFeature.kindFlashcards,
          LibraryFeature.widgets,
        ])
          feature: (payload(feature)['off']! as Map)['text'],
      };
      for (final language in AppLanguage.values) {
        if (language == AppLanguage.system) continue;
        AppLanguages.choice = language;
        for (final feature in english.keys) {
          final off = payload(feature)['off']! as Map;
          expect(off['text'], isNotEmpty, reason: language.id);
          expect(off['action'], isNotEmpty, reason: language.id);
          if (language != AppLanguage.english) {
            expect(
              off['text'],
              isNot(english[feature]),
              reason: '${language.id} is translated',
            );
          }
        }
      }
    });

    test('a feature that owns no widget is a mistake', () {
      expect(
        () =>
            widgetOffPayload(feature: LibraryFeature.search, libraryPath: '/'),
        throwsArgumentError,
      );
    });

    test('is a target the app can open', () {
      final target = WidgetTarget.fromMap({
        'kind': 'features',
        'libraryPath': '/lib',
      });
      expect(target?.kind, WidgetTargetKind.features);
      expect(target?.toMap()['kind'], 'features');
    });
  });

  group('the refresh', () {
    final root = p.join('/fake', 'Work');
    late FakeLibrarySession session;
    late List<(String, String?)> saves;

    WidgetUpdater recorder() => WidgetUpdater(
      saveData: (id, data) async {
        saves.add((id, data));
        return true;
      },
      updateWidgets: ({
        required androidName,
        required qualifiedAndroidName,
      }) async => true,
    );

    TodoSnapshot snapshot() => TodoSnapshot(
      todo: [TodoEntry(lineIndex: 0, task: parseTodoLine('call mum'))],
      done: const [],
    );

    Map<String, Object?> pushed(int index) =>
        jsonDecode(saves[index].$2!) as Map<String, Object?>;

    setUp(() async {
      session = FakeLibrarySession();
      saves = [];
      await session.open(root, create: false);
    });

    group('todo', () {
      setUp(() {
        session.seedWidgetConfig(
          androidWidgetId: 7,
          provider: 'todo',
          libraryPath: root,
        );
      });

      Future<void> refresh({TodoSnapshot? snap}) => refreshTodoWidgets(
        session: session,
        snapshot: snap ?? snapshot(),
        updater: recorder(),
      );

      test('on: the rows', () async {
        await refresh();
        expect(pushed(0).containsKey('off'), isFalse);
        expect(pushed(0)['total'], 1);
      });

      test('off: the sentence, no rows, even before the file loads', () async {
        session.features.value = without(LibraryFeature.todo);
        await refreshTodoWidgets(
          session: session,
          snapshot: null,
          updater: recorder(),
        );
        expect(saves.single.$1, 'todo_7');
        final off = pushed(0);
        expect(off['library'], root);
        expect((off['off']! as Map)['text'], 'Todo is off in this library');
        expect(off.containsKey('rows'), isFalse);
      });

      test('off, then on again: real data replaces the sentence', () async {
        session.features.value = without(LibraryFeature.todo);
        await refresh();
        session.features.value = const Features();
        await refresh();
        expect(saves, hasLength(2));
        expect(pushed(0).containsKey('off'), isTrue);
        expect(pushed(1).containsKey('off'), isFalse);
        expect(pushed(1)['total'], 1);
      });

      test('widgets off: says so, whatever todo says', () async {
        session.features.value = without(LibraryFeature.widgets);
        await refresh();
        expect(
          (pushed(0)['off']! as Map)['text'],
          'Home-screen widgets are off in this library',
        );
      });

      test('another feature off leaves it alone', () async {
        session.features.value = without(LibraryFeature.journal);
        await refresh();
        expect(pushed(0).containsKey('off'), isFalse);
      });
    });

    group('study', () {
      var counted = 0;

      Future<List<DeckSummary>?> decks() async {
        counted++;
        return const [
          DeckSummary(
            path: 'Verbs.md',
            name: 'Verbs',
            category: [],
            tags: [],
            total: 2,
            due: 2,
            fresh: 0,
            newAvailable: 0,
          ),
        ];
      }

      setUp(() {
        counted = 0;
        session.seedWidgetConfig(
          androidWidgetId: 9,
          provider: 'study',
          libraryPath: root,
        );
      });

      test('off: the sentence, and the decks are not even counted', () async {
        session.features.value = without(LibraryFeature.kindFlashcards);
        await refreshStudyWidgets(
          session: session,
          decks: decks,
          updater: recorder(),
        );
        expect(counted, 0);
        expect(saves.single.$1, 'study_9');
        expect(
          (pushed(0)['off']! as Map)['text'],
          'Study is off in this library',
        );
      });

      test('on again: the decks', () async {
        session.features.value = without(LibraryFeature.kindFlashcards);
        await refreshStudyWidgets(
          session: session,
          decks: decks,
          updater: recorder(),
        );
        session.features.value = const Features();
        await refreshStudyWidgets(
          session: session,
          decks: decks,
          updater: recorder(),
        );
        expect(counted, 1);
        expect(pushed(1).containsKey('off'), isFalse);
        expect(pushed(1)['total'], 2);
      });
    });

    group('note', () {
      var read = 0;

      Future<void> refresh() => refreshNoteWidgets(
        session: session,
        updater: recorder(),
        host: FakeWidgetHostService()..noteIds = [5],
        pinStore: FakeWidgetPinStore(),
        readNote: (root, notePath) async {
          read++;
          return '# hi\n\nbody\n';
        },
      );

      setUp(() {
        read = 0;
        session.seedWidgetConfig(
          androidWidgetId: 5,
          provider: 'note',
          libraryPath: root,
          notePath: 'Note.md',
        );
      });

      test(
        'widgets off: the sentence, and the note is not even read',
        () async {
          session.features.value = without(LibraryFeature.widgets);
          await refresh();
          expect(read, 0);
          expect(saves.single.$1, 'note_5');
          expect(
            (pushed(0)['off']! as Map)['text'],
            'Home-screen widgets are off in this library',
          );
        },
      );

      test('a feature of a kind does not turn the note widget off', () async {
        session.features.value = without(LibraryFeature.kindList);
        await refresh();
        expect(read, 1);
        expect(pushed(0).containsKey('off'), isFalse);
      });
    });
  });

  group('the background ops', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('niman_widget_off_');
    });

    tearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    void settings(Map<String, Object?> json) {
      File(p.join(root.path, '.niman', 'settings.json'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(json));
    }

    Uri todoToggle() => Uri(
      scheme: 'niman',
      host: 'todo-toggle',
      queryParameters: {'id': '7', 'library': root.path, 'line': '0'},
    );

    test('a library that never opened the screen allows them', () async {
      expect(await widgetUriAllowed(todoToggle()), isTrue);
      settings({'features': <String, Object?>{}});
      expect(await widgetUriAllowed(todoToggle()), isTrue);
    });

    test(
      'a todo toggle and a day refresh are dropped while todo is off',
      () async {
        settings({
          'features': {'todo': false},
        });
        expect(await widgetUriAllowed(todoToggle()), isFalse);
        final refresh = Uri(
          scheme: 'niman',
          host: 'todo-refresh',
          queryParameters: {'id': '7', 'library': root.path},
        );
        expect(await widgetUriAllowed(refresh), isFalse);
      },
    );

    test('note row ops follow the widgets switch only', () async {
      final toggle = Uri(
        scheme: 'niman',
        host: 'note-row-toggle',
        queryParameters: {
          'id': '5',
          'library': root.path,
          'note': 'List.md',
          'line': '2',
        },
      );
      settings({
        'features': {'todo': false, 'kinds.list': false},
      });
      expect(await widgetUriAllowed(toggle), isTrue);
      settings({
        'features': {'widgets': false},
      });
      expect(await widgetUriAllowed(toggle), isFalse);
    });

    test(
      'a URI that names no library, or none of ours, goes through',
      () async {
        expect(await widgetUriAllowed(null), isTrue);
        expect(
          await widgetUriAllowed(Uri.parse('niman://todo-toggle?id=1')),
          isTrue,
        );
        expect(
          await widgetUriAllowed(Uri.parse('niman://other?library=/x')),
          isTrue,
        );
      },
    );

    test('an unreadable settings file leaves every feature on', () async {
      File(p.join(root.path, '.niman', 'settings.json'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('not json');
      expect(await widgetUriAllowed(todoToggle()), isTrue);
    });
  });

  group('the shell flow', () {
    final root = p.join('/fake', 'Work');
    late FakeLibrarySession session;
    late FakeWidgetHostService host;
    late FakeWidgetTargetService targets;
    late List<(String, String?)> saves;
    late int openedFeatures;
    late ShellHomeWidgets flow;

    setUp(() async {
      session = FakeLibrarySession();
      await session.open(root, create: false);
      session.seedWidgetConfig(
        androidWidgetId: 7,
        provider: 'todo',
        libraryPath: root,
      );
      host = FakeWidgetHostService()..todoIds = [7];
      targets = FakeWidgetTargetService();
      saves = [];
      openedFeatures = 0;
      flow = ShellHomeWidgets(
        controller: session,
        targets: targets,
        updater: WidgetUpdater(
          saveData: (id, data) async {
            saves.add((id, data));
            return true;
          },
          updateWidgets: ({
            required androidName,
            required qualifiedAndroidName,
          }) async => true,
        ),
        host: host,
        todoSnapshot: () => TodoSnapshot(
          todo: [TodoEntry(lineIndex: 0, task: parseTodoLine('call mum'))],
          done: const [],
        ),
        decks: () async => null,
        openTodo: () {},
        openStudy: () {},
        openFeatures: () => openedFeatures++,
        openNote: (path, anchor) {},
        mounted: () => true,
        onTargetBlocked: () {},
      )..start();
    });

    tearDown(() async {
      await flow.dispose();
      await targets.dispose();
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    test(
      'a switch, from the screen or a sync, re-pushes the widgets',
      () async {
        session.features.value = without(LibraryFeature.todo);
        await settle();
        expect(saves, isNotEmpty);
        expect(
          jsonDecode(saves.last.$2!),
          containsPair('off', isA<Map<String, Object?>>()),
        );

        saves.clear();
        session.features.value = const Features();
        await settle();
        final back = jsonDecode(saves.last.$2!) as Map<String, Object?>;
        expect(back.containsKey('off'), isFalse);
        expect(back['total'], 1, reason: 'real data again');
      },
    );

    test('after dispose the switches no longer push', () async {
      await flow.dispose();
      session.features.value = without(LibraryFeature.todo);
      await settle();
      expect(saves, isEmpty);
    });

    test('the button of an off widget opens the Features hook', () async {
      targets.emit(
        WidgetTarget(kind: WidgetTargetKind.features, libraryPath: root),
      );
      await settle();
      expect(openedFeatures, 1);
    });
  });
}
