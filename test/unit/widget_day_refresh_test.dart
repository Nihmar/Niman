// The todo widget's day-boundary re-push (#1018): URI parsing and the
// re-read-and-push against a temp library root with an injected day.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/widget/widget_day_refresh.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

void main() {
  group('refresh URI', () {
    test('parses id, library, theme and language', () {
      final target = parseTodoRefreshUri(
        Uri.parse(
          'niman://todo-refresh?id=7&library=%2Flib&lg=it'
          '&td=0&bg=%23E6FFFBFF&fg=%23FF1C1B1F&fs=%23FF49454F&ac=%23FF6750A4'
          '&er=%23FFB3261E',
        ),
      );
      expect(target?.id, 7);
      expect(target?.library, '/lib');
      expect(target?.language, 'it');
      expect(target?.theme?.error, '#FFB3261E');
    });

    test('theme and language are optional', () {
      expect(
        parseTodoRefreshUri(Uri.parse('niman://todo-refresh?id=7&library=/l')),
        (id: 7, library: '/l', theme: null, language: null),
      );
    });

    test('rejects garbage', () {
      expect(parseTodoRefreshUri(null), isNull);
      expect(parseTodoRefreshUri(Uri.parse('niman://todo-refresh')), isNull);
      expect(
        parseTodoRefreshUri(Uri.parse('niman://todo-toggle?id=7&library=/l')),
        isNull,
      );
      expect(
        parseTodoRefreshUri(Uri.parse('niman://todo-refresh?id=-1&library=/l')),
        isNull,
      );
      expect(
        parseTodoRefreshUri(Uri.parse('niman://todo-refresh?id=7&library=')),
        isNull,
      );
    });
  });

  group('refresh', () {
    late Directory root;
    late List<(String, String?)> saves;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('niman_day_refresh_');
      saves = [];
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    WidgetUpdater recorder() {
      return WidgetUpdater(
        saveData: (id, data) async {
          saves.add((id, data));
          return true;
        },
        updateWidgets:
            ({required androidName, required qualifiedAndroidName}) async {
              return true;
            },
      );
    }

    Uri refreshUri({String? library, Map<String, String> extra = const {}}) {
      return Uri(
        scheme: 'niman',
        host: 'todo-refresh',
        queryParameters: {'id': '7', 'library': library ?? root.path, ...extra},
      );
    }

    List<(String, String)> headings() {
      final payload = jsonDecode(saves.last.$2!) as Map<String, Object?>;
      return [
        for (final item in payload['rows']! as List<Object?>)
          if ((item! as Map)['kind'] == 'section')
            ((item as Map)['section']! as String, item['label']! as String),
      ];
    }

    test(
      'a task due yesterday moves from Today to Overdue overnight',
      () async {
        File(p.join(root.path, 'todo.txt'))
            .writeAsStringSync('pay rent due:2026-10-16\nsomeday\n');

        final evening = await refreshWidgetTodoForNewDay(
          refreshUri(),
          updater: recorder(),
          today: DateTime(2026, 10, 16, 23, 59),
        );
        expect(evening, isTrue);
        expect(headings().map((h) => h.$1), ['due.today', 'due.none']);

        final morning = await refreshWidgetTodoForNewDay(
          refreshUri(),
          updater: recorder(),
          today: DateTime(2026, 10, 17, 0, 1),
        );
        expect(morning, isTrue);
        expect(saves.map((s) => s.$1), ['todo_7', 'todo_7']);
        expect(headings().map((h) => h.$1), ['due.overdue', 'due.none']);
      },
    );

    test('words the headings in the language the widget carried', () async {
      addTearDown(AppLanguages.reset);
      File(p.join(root.path, 'todo.txt')).writeAsStringSync('someday\n');

      final refreshed = await refreshWidgetTodoForNewDay(
        refreshUri(extra: {'lg': 'it'}),
        updater: recorder(),
        today: DateTime(2026, 10, 17),
      );
      expect(refreshed, isTrue);
      expect(headings().single.$2, 'Senza data');
    });

    test('a library that is gone keeps what the widget shows', () async {
      final gone = p.join(root.path, 'missing');
      expect(
        await refreshWidgetTodoForNewDay(
          refreshUri(library: gone),
          updater: recorder(),
        ),
        isFalse,
      );
      expect(saves, isEmpty);
    });

    test('garbage fails quiet', () async {
      expect(
        await refreshWidgetTodoForNewDay(null, updater: recorder()),
        isFalse,
      );
      expect(saves, isEmpty);
    });
  });
}
