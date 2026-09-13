// Widget launcher payloads (issue 6): keys, names and the todo JSON.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
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
      final payload = todoWidgetPayload([
        entry(3, '(A) call the office +work due:2026-09-10'),
        entry(9, 'buy milk'),
      ], libraryPath: '/lib/Work');
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['library'], '/lib/Work');
      expect(decoded['truncated'], isFalse);
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
      });
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
        maxChars: 150,
      );
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['truncated'], isTrue);
      final rows = decoded['rows']! as List<Object?>;
      expect(rows.length, lessThan(3));
      expect((rows.first! as Map)['text'], 'first');
      expect(payload.length, lessThanOrEqualTo(150));
    });
  });
}
