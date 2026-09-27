// Background note-row ops (issue 6): URI parsing and the flip-and-repush
// against a temp library root, plus the callback dispatch.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/widget_note_ops.dart';
import 'package:niman/src/widget/widget_toggle.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

void main() {
  group('URI parsing', () {
    test('toggle parses id, library, note and line', () {
      expect(
        parseNoteRowToggleUri(
          Uri.parse(
            'niman://note-row-toggle?id=7&library=%2Flib&note=List.md&line=3',
          ),
        ),
        (id: 7, library: '/lib', note: 'List.md', line: 3, theme: null),
      );
    });

    test('rejects garbage', () {
      expect(parseNoteRowToggleUri(null), isNull);
      expect(
        parseNoteRowToggleUri(
          Uri.parse('niman://other?id=7&library=/l&note=n&line=3'),
        ),
        isNull,
      );
      expect(
        parseNoteRowToggleUri(
          Uri.parse('niman://note-row-toggle?id=x&line=-1'),
        ),
        isNull,
      );
      expect(
        parseNoteRowToggleUri(
          Uri.parse('niman://note-row-toggle?id=7&library=/l&line=3'),
        ),
        isNull,
        reason: 'no note',
      );
    });

    test('rejects a note path that escapes the library (issue #332)', () {
      expect(
        parseNoteRowToggleUri(
          Uri.parse(
            'niman://note-row-toggle?id=7&library=%2Flib&note=..%2Fout.md&line=3',
          ),
        ),
        isNull,
        reason: 'a .. segment',
      );
      expect(
        parseNoteRowToggleUri(
          Uri.parse(
            'niman://note-row-toggle?id=7&library=%2Flib&note=%2Fetc%2Fpasswd'
            '&line=3',
          ),
        ),
        isNull,
        reason: 'an absolute path',
      );
    });
  });

  group('add URI parsing', () {
    test('add parses id, library, note and text', () {
      expect(
        parseNoteRowAddUri(
          Uri.parse(
            'niman://note-row-add?id=7&library=%2Flib&note=List.md&text=buy%20milk',
          ),
        ),
        (
          id: 7,
          library: '/lib',
          note: 'List.md',
          text: 'buy milk',
          theme: null,
        ),
      );
    });

    test('add rejects garbage', () {
      expect(parseNoteRowAddUri(null), isNull);
      expect(
        parseNoteRowAddUri(
          Uri.parse('niman://other?id=7&library=/l&note=n&text=x'),
        ),
        isNull,
      );
      expect(
        parseNoteRowAddUri(
          Uri.parse('niman://note-row-add?id=7&library=/l&note=n'),
        ),
        isNull,
        reason: 'no text',
      );
      expect(
        parseNoteRowAddUri(
          Uri.parse('niman://note-row-add?id=7&library=/l&note=n&text=%20'),
        ),
        isNull,
        reason: 'blank text',
      );
    });

    test('add rejects a note path that escapes the library (issue #332)', () {
      expect(
        parseNoteRowAddUri(
          Uri.parse(
            'niman://note-row-add?id=7&library=%2Flib&note=..%2Fout.md&text=x',
          ),
        ),
        isNull,
      );
    });
  });

  group('row ops', () {
    late Directory root;
    late List<(String, String?)> saves;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('niman_note_ops_');
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
        host: 'note-row-toggle',
        queryParameters: {
          'id': '7',
          'library': root.path,
          'note': 'List.md',
          'line': '$line',
        },
      );
    }

    test('toggle flips the box and re-pushes the rows', () async {
      File(p.join(root.path, 'List.md'))
          .writeAsStringSync('---\ntype: list\n---\n- [ ] milk\n- [x] eggs\n');

      expect(
        await toggleWidgetNoteRow(toggleUri(3), updater: recorder()),
        isTrue,
      );
      expect(
        File(p.join(root.path, 'List.md')).readAsStringSync(),
        '---\ntype: list\n---\n- [x] milk\n- [x] eggs\n',
      );
      expect(saves.map((s) => s.$1), ['note_7']);
      final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
      expect(payload['kind'], 'list');
      final rows = payload['rows']! as List<Object?>;
      expect(rows.first, {
        'text': 'milk',
        'checked': true,
        'line': 3,
        'depth': 0,
      });
    });

    test('a stale line fails quiet', () async {
      File(p.join(root.path, 'List.md'))
          .writeAsStringSync('---\ntype: list\n---\n- [ ] milk\n');

      expect(
        await toggleWidgetNoteRow(toggleUri(9), updater: recorder()),
        isFalse,
      );
      expect(saves, isEmpty);
    });

    test('a missing note fails quiet', () async {
      expect(
        await toggleWidgetNoteRow(toggleUri(3), updater: recorder()),
        isFalse,
      );
      expect(saves, isEmpty);
    });

    test('the callback routes note-row hosts to the note ops', () async {
      File(p.join(root.path, 'List.md'))
          .writeAsStringSync('---\ntype: list\n---\n- [ ] milk\n');

      await widgetToggleCallback(toggleUri(3));

      expect(
        File(p.join(root.path, 'List.md')).readAsStringSync(),
        contains('- [x] milk'),
      );
    });

    test(
      'a toggle whose note escapes the library fails quiet (#332)',
      () async {
        final uri = Uri(
          scheme: 'niman',
          host: 'note-row-toggle',
          queryParameters: {
            'id': '7',
            'library': root.path,
            'note': '../outside.md',
            'line': '3',
          },
        );

        expect(await toggleWidgetNoteRow(uri, updater: recorder()), isFalse);
        expect(saves, isEmpty);
      },
    );
  });

  group('add op', () {
    late Directory root;
    late List<(String, String?)> saves;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('niman_note_ops_');
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

    Uri addUri(String text) {
      return Uri(
        scheme: 'niman',
        host: 'note-row-add',
        queryParameters: {
          'id': '7',
          'library': root.path,
          'note': 'List.md',
          'text': text,
        },
      );
    }

    test('add appends the item and re-pushes the rows', () async {
      File(p.join(root.path, 'List.md'))
          .writeAsStringSync('---\ntype: list\n---\n- [ ] milk\n- [x] eggs\n');

      expect(
        await addWidgetNoteRow(addUri('bread'), updater: recorder()),
        isTrue,
      );
      expect(
        File(p.join(root.path, 'List.md')).readAsStringSync(),
        '---\ntype: list\n---\n- [ ] milk\n- [x] eggs\n- [ ] bread\n',
      );
      expect(saves.map((s) => s.$1), ['note_7']);
      final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
      expect(payload['kind'], 'list');
      final rows = payload['rows']! as List<Object?>;
      expect(rows.last, {
        'text': 'bread',
        'checked': false,
        'line': 5,
        'depth': 0,
      });
    });

    test('an add into a non-list note fails quiet', () async {
      File(p.join(root.path, 'List.md')).writeAsStringSync('# not a list\n');

      expect(
        await addWidgetNoteRow(addUri('bread'), updater: recorder()),
        isFalse,
      );
      expect(saves, isEmpty);
    });

    test('a missing note fails quiet', () async {
      expect(
        await addWidgetNoteRow(addUri('bread'), updater: recorder()),
        isFalse,
      );
      expect(saves, isEmpty);
    });

    test('the callback routes note-row-add to the add op', () async {
      File(p.join(root.path, 'List.md'))
          .writeAsStringSync('---\ntype: list\n---\n- [ ] milk\n');

      await widgetToggleCallback(addUri('eggs'));

      expect(
        File(p.join(root.path, 'List.md')).readAsStringSync(),
        contains('- [ ] eggs'),
      );
    });

    test(
      'an add whose note escapes the library writes nothing (#332)',
      () async {
        final outside = await Directory.systemTemp.createTemp('niman_outside_');
        addTearDown(() async {
          if (outside.existsSync()) await outside.delete(recursive: true);
        });
        final prey = File(p.join(outside.path, 'outside.md'))
          ..writeAsStringSync('- [ ] untouched\n');
        final writes = <String>[];
        final uri = Uri(
          scheme: 'niman',
          host: 'note-row-add',
          queryParameters: {
            'id': '7',
            'library': root.path,
            'note': '../${p.basename(outside.path)}/outside.md',
            'text': 'sneaky',
          },
        );

        expect(
          await addWidgetNoteRow(
            uri,
            readNote: (_, _) async => '- [ ] untouched\n',
            writeNote: (_, note, _) async => writes.add(note),
            updater: recorder(),
          ),
          isFalse,
        );
        expect(writes, isEmpty);
        expect(prey.readAsStringSync(), '- [ ] untouched\n');
      },
    );

    test('the note IO refuses a path outside the library (#332)', () async {
      await expectLater(
        writeNoteText(root.path, '../outside.md', 'x'),
        throwsArgumentError,
      );
      expect(await readNoteText(root.path, '../outside.md'), isNull);
    });
  });
}
