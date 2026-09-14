// Widget launcher payloads (issue 6): keys, names and the todo JSON.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/widget/note_excerpt.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_payload.dart';

void main() {
  TodoEntry entry(int index, String line) {
    return TodoEntry(lineIndex: index, task: parseTodoLine(line));
  }

  group('names and keys', () {
    test('providers map to their classes', () {
      expect(
        widgetProviderAndroidName(WidgetProvider.todo),
        'TodoWidgetProvider',
      );
      expect(
        widgetProviderAndroidName(WidgetProvider.note),
        'NoteWidgetProvider',
      );
      expect(
        widgetProviderQualifiedName(WidgetProvider.todo),
        'dev.niman.niman.TodoWidgetProvider',
      );
    });

    test('keys carry provider and instance', () {
      expect(widgetPayloadKey(WidgetProvider.todo, 7), 'todo_7');
      expect(widgetPayloadKey(WidgetProvider.note, 7), 'note_7');
      expect(
        widgetPayloadKey(WidgetProvider.todo, 7) !=
            widgetPayloadKey(WidgetProvider.todo, 8),
        isTrue,
        reason: 'two instances never share a payload',
      );
    });
  });

  group('todo payload', () {
    test('rows carry prose, due, priority and line', () {
      final payload = todoWidgetPayload(
        [
          entry(3, '(A) call the office +work due:2026-09-10'),
          entry(9, 'buy milk'),
        ],
        libraryPath: '/lib/Work',
        total: 2,
      );
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['library'], '/lib/Work');
      expect(decoded['truncated'], isFalse);
      expect(decoded['total'], 2);
      final rows = decoded['rows']! as List<Object?>;
      expect(rows, [
        {
          'text': 'call the office',
          'due': '2026-09-10',
          'priority': 'A',
          'line': 3,
        },
        {'text': 'buy milk', 'due': null, 'priority': null, 'line': 9},
      ]);
    });

    test('an empty list encodes without truncation', () {
      final decoded = jsonDecode(
        todoWidgetPayload(const [], libraryPath: '/lib'),
      );
      expect(decoded, {
        'library': '/lib',
        'rows': <Object?>[],
        'truncated': false,
        'total': 0,
      });
    });

    test('total defaults to the row count and stays true when truncated', () {
      // Without an explicit total, the row count stands in.
      final defaulted = jsonDecode(
        todoWidgetPayload([entry(0, 'first')], libraryPath: '/lib'),
      ) as Map<String, Object?>;
      expect(defaulted['total'], 1);
      // With one, truncation of the rows does not truncate the total.
      final capped = jsonDecode(
        todoWidgetPayload(
          [entry(0, 'first'), entry(1, 'second')],
          libraryPath: '/lib',
          total: 12,
        ),
      ) as Map<String, Object?>;
      expect(capped['total'], 12);
    });

    test('rows drop from the end past the cap', () {
      final entries = [
        entry(0, 'first'),
        entry(1, 'second'),
        entry(2, 'third'),
      ];
      final payload = todoWidgetPayload(
        entries,
        libraryPath: '/lib',
        total: 3,
        maxChars: 150,
      );
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['truncated'], isTrue);
      expect(decoded['total'], 3);
      final rows = decoded['rows']! as List<Object?>;
      expect(rows.length, lessThan(3));
      expect((rows.first! as Map)['text'], 'first');
      expect(payload.length, lessThanOrEqualTo(150));
    });
  });

  group('note payload', () {
    test('a prose note carries library, note, title, kind and body', () {
      final payload = noteWidgetPayload(
        libraryPath: '/lib/Work',
        notePath: 'Note.md',
        title: 'Note',
        kind: 'note',
        body: '# hi\n\nbody text',
        truncated: false,
      );
      expect(jsonDecode(payload), {
        'library': '/lib/Work',
        'note': 'Note.md',
        'title': 'Note',
        'kind': 'note',
        'rows': <Object?>[],
        'body': '# hi\n\nbody text',
        'truncated': false,
        'total': 0,
      });
    });

    test('a list note carries the checklist rows', () {
      final payload = noteWidgetPayload(
        libraryPath: '/lib/Work',
        notePath: 'List.md',
        title: 'List',
        kind: 'list',
        rows: const [
          ChecklistRow(text: 'milk', checked: false, line: 3, depth: 0),
          ChecklistRow(text: 'eggs', checked: true, line: 4, depth: 1),
        ],
        truncated: false,
        total: 12,
      );
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['rows'], [
        {'text': 'milk', 'checked': false, 'line': 3, 'depth': 0},
        {'text': 'eggs', 'checked': true, 'line': 4, 'depth': 1},
      ]);
      expect(decoded['body'], '');
      expect(decoded['truncated'], false);
      // The true count, not the (capped) row count.
      expect(decoded['total'], 12);
    });

    test('total defaults to the row count', () {
      final payload = noteWidgetPayload(
        libraryPath: '/lib/Work',
        notePath: 'List.md',
        title: 'List',
        kind: 'list',
        rows: const [
          ChecklistRow(text: 'milk', checked: false, line: 3, depth: 0),
        ],
        truncated: false,
      );
      expect((jsonDecode(payload) as Map<String, Object?>)['total'], 1);
    });
  });
}
