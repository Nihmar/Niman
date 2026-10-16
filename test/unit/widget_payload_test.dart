// Widget launcher payloads (issue 6): keys, names and the todo JSON.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_sections.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';
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

  WidgetTodoSection section(
    String id,
    List<TodoEntry> entries, {
    int? count,
    String? label,
  }) {
    return (
      id: id,
      label: label ?? 'label $id',
      count: count ?? entries.length,
      entries: entries,
    );
  }

  List<Map<String, Object?>> rowsOf(String payload) {
    final decoded = jsonDecode(payload) as Map<String, Object?>;
    return [
      for (final item in decoded['rows']! as List<Object?>)
        item! as Map<String, Object?>,
    ];
  }

  group('todo payload', () {
    test('rows carry prose, due, priority, tokens, line and section', () {
      final payload = todoWidgetPayload(
        [
          section(todoDueNext7SectionId, [
            entry(3, '(A) call the office +work @home #urgent due:2026-09-10'),
          ]),
          section(todoDueNoneSectionId, [entry(9, 'buy milk')]),
        ],
        libraryPath: '/lib/Work',
        total: 2,
      );
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['library'], '/lib/Work');
      expect(decoded['truncated'], isFalse);
      expect(decoded['total'], 2);
      expect(decoded['rows'], [
        {
          'kind': 'section',
          'section': 'due.next7',
          'label': 'label due.next7',
          'count': 1,
        },
        {
          'text': 'call the office',
          'due': '2026-09-10',
          'priority': 'A',
          'projects': ['work'],
          'contexts': ['home'],
          'tags': ['urgent'],
          'line': 3,
          'section': 'due.next7',
          'showDue': true,
        },
        {
          'kind': 'section',
          'section': 'due.none',
          'label': 'label due.none',
          'count': 1,
        },
        {
          'text': 'buy milk',
          'due': null,
          'priority': null,
          'projects': <Object?>[],
          'contexts': <Object?>[],
          'tags': <Object?>[],
          'line': 9,
          'section': 'due.none',
          'showDue': true,
        },
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

    test('only the overdue header is drawn in the error tone', () {
      final items = rowsOf(
        todoWidgetPayload([
          section(todoDueOverdueSectionId, [entry(0, 'late due:2020-01-01')]),
          section(todoDueTodaySectionId, [entry(1, 'now')]),
        ], libraryPath: '/lib'),
      );
      final headers = items.where((item) => item['kind'] == 'section');
      expect([for (final header in headers) header['tone']], ['error', null]);
    });

    test('a row under Today leaves its date out of the meta line', () {
      final items = rowsOf(
        todoWidgetPayload([
          section(todoDueOverdueSectionId, [entry(0, 'late due:2020-01-01')]),
          section(todoDueTodaySectionId, [entry(1, 'now due:2026-10-16')]),
          section(todoDueLaterSectionId, [entry(2, 'far due:2027-01-01')]),
        ], libraryPath: '/lib'),
      );
      final showDue = {
        for (final item in items)
          if (item['kind'] != 'section') item['section']: item['showDue'],
      };
      expect(showDue, {
        'due.overdue': true,
        'due.today': false,
        'due.later': true,
      });
      // The date itself stays in the row: only the meta line skips it.
      expect(
        items.firstWhere(
          (item) => item['kind'] == null && item['section'] == 'due.today',
        )['due'],
        '2026-10-16',
      );
    });

    test('total defaults to the row count, headers not counted', () {
      final defaulted = jsonDecode(
        todoWidgetPayload([
          section(todoDueNoneSectionId, [entry(0, 'first')]),
        ], libraryPath: '/lib'),
      ) as Map<String, Object?>;
      expect(defaulted['total'], 1);
      // With one, truncation of the rows does not truncate the total.
      final capped = jsonDecode(
        todoWidgetPayload(
          [
            section(todoDueNoneSectionId, [
              entry(0, 'first'),
              entry(1, 'second'),
            ]),
          ],
          libraryPath: '/lib',
          total: 12,
        ),
      ) as Map<String, Object?>;
      expect(capped['total'], 12);
    });

    test('items drop from the end past the cap, a bare header with them', () {
      final sections = [
        section(todoDueTodaySectionId, [entry(0, 'first'), entry(1, 'second')]),
        section(todoDueNoneSectionId, [entry(2, 'third')], count: 40),
      ];
      final full = todoWidgetPayload(sections, libraryPath: '/lib', total: 42);
      final firstOnly = todoWidgetPayload(
        sections.sublist(0, 1),
        libraryPath: '/lib',
        total: 42,
      );
      // Room for the first section and the second header, but not its row.
      final cap = (firstOnly.length + full.length) ~/ 2;
      final payload = todoWidgetPayload(
        sections,
        libraryPath: '/lib',
        total: 42,
        maxChars: cap,
      );
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      expect(decoded['truncated'], isTrue);
      expect(decoded['total'], 42);
      final items = rowsOf(payload);
      expect(items.first['kind'], 'section');
      expect(items.last['kind'], isNull, reason: 'no header left bare');
      expect(items.where((item) => item['kind'] == 'section'), hasLength(1));
      expect(payload.length, lessThanOrEqualTo(cap));
    });

    test(
      'a header counts the rows under it, not the own count of a section',
      () {
        // The row cap of widgetTodoSections leaves 1 of 250 rows: the
        // header says 1, the payload's `total` carries the true count.
        final payload = todoWidgetPayload(
          [
            section(todoDueNoneSectionId, [entry(0, 'first')], count: 250),
          ],
          libraryPath: '/lib',
          total: 250,
        );
        final items = rowsOf(payload);
        expect(items.first['count'], 1);
        expect(items, hasLength(2));
        expect((jsonDecode(payload) as Map<String, Object?>)['total'], 250);
      },
    );

    test('the character cap recounts a header it cut mid-section (#1007)', () {
      final sections = [
        section(todoDueTodaySectionId, [entry(0, 'first'), entry(1, 'second')]),
        section(todoDueLaterSectionId, [
          for (var i = 2; i < 12; i++) entry(i, 'later $i'),
        ], count: 250),
      ];
      final full = todoWidgetPayload(sections, libraryPath: '/lib', total: 252);
      // Room for most of the second section, not all of it.
      final cap = full.length - 3 * (full.length ~/ 15);
      final payload = todoWidgetPayload(
        sections,
        libraryPath: '/lib',
        total: 252,
        maxChars: cap,
      );
      expect(
        (jsonDecode(payload) as Map<String, Object?>)['truncated'],
        isTrue,
      );
      final items = rowsOf(payload);
      final headers = items.where((item) => item['kind'] == 'section').toList();
      expect(headers, hasLength(2), reason: 'the cut section keeps its header');
      // Every header says exactly the rows that follow it.
      var rows = 0;
      for (var i = items.length - 1; i >= 0; i--) {
        if (items[i]['kind'] == 'section') {
          expect(
            items[i]['count'],
            rows,
            reason: 'header ${items[i]['section']}',
          );
          rows = 0;
        } else {
          rows++;
        }
      }
      expect(headers.last['count'], lessThan(10));
      expect(headers.last['count'], greaterThan(0));
    });

    test('a theme and a language ride along when given, absent otherwise', () {
      const theme = (
        dark: true,
        background: '#E61A1C1E',
        primary: '#FFE2E2E5',
        secondary: '#FFC3C6CF',
        accent: '#FFD0BCFF',
      );
      final sections = [
        section(todoDueNoneSectionId, [entry(0, 'first')]),
      ];
      final themed = jsonDecode(
        todoWidgetPayload(
          sections,
          libraryPath: '/lib',
          theme: theme,
          language: 'it',
        ),
      ) as Map<String, Object?>;
      expect(themed['theme'], {
        'dark': true,
        'background': '#E61A1C1E',
        'primary': '#FFE2E2E5',
        'secondary': '#FFC3C6CF',
        'accent': '#FFD0BCFF',
      });
      expect(themed['language'], 'it');
      final plain = jsonDecode(
        todoWidgetPayload(sections, libraryPath: '/lib'),
      ) as Map<String, Object?>;
      expect(plain.containsKey('theme'), isFalse);
      expect(plain.containsKey('language'), isFalse);
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
