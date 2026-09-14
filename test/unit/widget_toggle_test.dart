// Background todo toggle (round 2, R2): URI parsing and the
// check-and-repush against a temp library root.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/widget_toggle.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

void main() {
  group('toggle URI', () {
    test('parses id, library and line', () {
      expect(
        parseToggleUri(
          Uri.parse('niman://todo-toggle?id=7&library=%2Flib&line=3'),
        ),
        (id: 7, library: '/lib', line: 3, theme: null),
      );
    });

    test('parses the theme params', () {
      final target = parseToggleUri(
        Uri.parse(
          'niman://todo-toggle?id=7&library=%2Flib&line=3'
          '&td=1&bg=%23E61A1C1E&fg=%23FFE2E2E5&fs=%23FFC3C6CF&ac=%23FFD0BCFF',
        ),
      );
      expect(target?.theme, (
        dark: true,
        background: '#E61A1C1E',
        primary: '#FFE2E2E5',
        secondary: '#FFC3C6CF',
        accent: '#FFD0BCFF',
      ));
    });

    test('rejects garbage', () {
      expect(parseToggleUri(null), isNull);
      expect(parseToggleUri(Uri.parse('niman://todo-toggle')), isNull);
      expect(
        parseToggleUri(Uri.parse('niman://other?id=7&library=/l&line=3')),
        isNull,
      );
      expect(
        parseToggleUri(Uri.parse('niman://todo-toggle?id=x&line=-1')),
        isNull,
      );
    });
  });

  group('toggle', () {
    late Directory root;
    late List<(String, String?)> saves;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('niman_toggle_');
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

    Uri toggleUri(int line) {
      return Uri(
        scheme: 'niman',
        host: 'todo-toggle',
        queryParameters: {'id': '7', 'library': root.path, 'line': '$line'},
      );
    }

    test('completes the line and re-pushes its widget', () async {
      File(p.join(root.path, 'todo.txt'))
          .writeAsStringSync('(A) call due:2026-09-10\nbuy milk\n');

      expect(await toggleWidgetTodo(toggleUri(1), updater: recorder()), isTrue);
      expect(
        File(p.join(root.path, 'todo.txt')).readAsStringSync(),
        '(A) call due:2026-09-10\n',
      );
      expect(
        File(p.join(root.path, 'done.txt')).readAsStringSync(),
        contains('buy milk'),
      );

      expect(saves.map((s) => s.$1), ['todo_7']);
      final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
      final rows = payload['rows']! as List<Object?>;
      expect(rows, hasLength(1));
      expect((rows.single! as Map)['text'], 'call');
    });

    test('a stale line fails quiet', () async {
      File(p.join(root.path, 'todo.txt')).writeAsStringSync('only\n');
      expect(
        await toggleWidgetTodo(toggleUri(9), updater: recorder()),
        isFalse,
      );
      expect(saves, isEmpty);
    });

    test('garbage fails quiet', () async {
      expect(await toggleWidgetTodo(null, updater: recorder()), isFalse);
      expect(saves, isEmpty);
    });
  });
}
