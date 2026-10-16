// The todo widget payload builder (#1028 items 5 and 6): the injected day
// the sections are bucketed against, and the language ids a tap can carry.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/widget/widget_todo_payload.dart';

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  TodoSnapshot snapshot(List<String> lines) {
    return TodoSnapshot(
      todo: <TodoEntry>[
        for (var i = 0; i < lines.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
      ],
      done: const <TodoEntry>[],
    );
  }

  Map<String, Object?> decode(String payload) {
    return jsonDecode(payload) as Map<String, Object?>;
  }

  List<Map<String, Object?>> headers(Map<String, Object?> payload) {
    return [
      for (final item in payload['rows']! as List<Object?>)
        if ((item! as Map)['kind'] == 'section')
          (item as Map).cast<String, Object?>(),
    ];
  }

  final week = snapshot([
    'overdue due:2026-10-15',
    'today due:2026-10-16',
    'soon due:2026-10-20',
    'far due:2026-12-01',
    'someday',
  ]);

  group('buildTodoWidgetPayload', () {
    test('buckets the sections against the injected day', () {
      final payload = decode(
        buildTodoWidgetPayload(
          week,
          libraryPath: '/lib',
          today: DateTime(2026, 10, 16, 9),
        ),
      );
      expect(payload['library'], '/lib');
      expect(payload['total'], 5);
      expect(payload['truncated'], isFalse);
      expect(
        [for (final header in headers(payload)) header['section']],
        ['due.overdue', 'due.today', 'due.next7', 'due.later', 'due.none'],
      );
      expect(
        [for (final header in headers(payload)) header['count']],
        [1, 1, 1, 1, 1],
      );
      expect(headers(payload).first['tone'], 'error');
      expect(
        headers(payload).every((header) => (header['label']! as String) != ''),
        isTrue,
      );
    });

    test('another day moves the same tasks to other sections', () {
      final payload = decode(
        buildTodoWidgetPayload(
          week,
          libraryPath: '/lib',
          today: DateTime(2026, 10, 17, 9),
        ),
      );
      // The task due on the 16th is overdue the day after; nothing is due
      // today any more.
      final sections = [for (final h in headers(payload)) h['section']];
      expect(sections, ['due.overdue', 'due.next7', 'due.later', 'due.none']);
      final overdue = headers(payload).first;
      expect(overdue['count'], 2);
    });

    test('stamps the language in use and wears the given theme', () {
      AppLanguages.choice = AppLanguage.italian;
      const theme = (
        dark: false,
        background: '#E6FFFBFF',
        primary: '#FF1C1B1F',
        secondary: '#FF49454F',
        accent: '#FF6750A4',
        error: '#FFB3261E',
      );
      final payload = decode(
        buildTodoWidgetPayload(
          snapshot(['someday']),
          libraryPath: '/lib',
          theme: theme,
          today: DateTime(2026, 10, 16),
        ),
      );
      expect(payload['language'], 'it');
      expect(headers(payload).single['label'], 'Senza data');
      expect((payload['theme']! as Map)['error'], '#FFB3261E');
    });
  });

  group('applyWidgetLanguage', () {
    test('adopts a known language id', () {
      applyWidgetLanguage('it');
      expect(AppLanguages.resolved, AppLanguage.italian);
    });

    test('an unknown id leaves the language as it is', () {
      AppLanguages.choice = AppLanguage.french;
      applyWidgetLanguage('xx-not-a-language');
      expect(AppLanguages.choice, AppLanguage.french);
      expect(AppLanguages.resolved.id, 'fr');
    });

    test('the system id, an empty one and null leave it too', () {
      AppLanguages.choice = AppLanguage.german;
      applyWidgetLanguage('system');
      applyWidgetLanguage('');
      applyWidgetLanguage(null);
      expect(AppLanguages.choice, AppLanguage.german);
    });

    test('an unknown id pushes the payload in the language already in use', () {
      applyWidgetLanguage('xx-not-a-language');
      final payload = decode(
        buildTodoWidgetPayload(
          snapshot(['someday']),
          libraryPath: '/lib',
          today: DateTime(2026, 10, 16),
        ),
      );
      expect(payload['language'], AppLanguages.resolved.id);
      expect(headers(payload).single['label'], 'No date');
    });
  });
}
