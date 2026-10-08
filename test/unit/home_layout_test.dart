// #535: the Home's model — what `.niman/home.json` holds, how the grid
// settles after a merge, and how actions follow a rename.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';

HomeLayout _read(String json) => HomeLayout.fromJson(jsonDecode(json))!;

void main() {
  group('JSON', () {
    test('the defaults survive a round trip', () {
      final again = HomeLayout.fromJson(
        jsonDecode(jsonEncode(HomeLayout.defaults.toJson())),
      );
      expect(again, HomeLayout.defaults);
    });

    test('is null for something that is not an object', () {
      expect(HomeLayout.fromJson([1, 2]), isNull);
      expect(HomeLayout.fromJson('x'), isNull);
    });

    test('a tile of a kind this build does not know is kept, not shown', () {
      final layout = _read(
        '{"study": {"kind": "study", "grid": [0, 0, 1, 1], "deck": "x"},'
        ' "recent": {"kind": "recent", "grid": [1, 0, 1, 2]}}',
      );
      expect(layout.column.map((t) => t.id), ['recent']);
      expect(layout.toJson()['study'], {
        'grid': [0, 0, 1, 1],
        'phone': {'at': HomeTile.unplaced},
        'kind': 'study',
        'deck': 'x',
      });
    });

    test('an action keeps the keys it does not know, and its unknown kind', () {
      final layout = _read(
        '{"a": {"kind": "actions", "actions": [ '
        '{"id": "1", "label": "Deck", "do": "study", "deck": "Spanish"}, '
        '{"id": "2", "label": "Meeting", "do": "newNote", "colour": "red",'
        ' "template": "T/m.md", "name": {"fixed": "{{date}}"},'
        ' "fields": {"who": {"ask": true}, "p": {"fixed": "alpha"}},'
        ' "open": false}]}}',
      );
      final [study, meeting] = layout['a']!.actions;
      expect(study.kind, isNull);
      expect(study.toJson(), {
        'id': '1',
        'label': 'Deck',
        'do': 'study',
        'deck': 'Spanish',
      });
      expect(meeting.kind, HomeActionKind.newNote);
      expect(meeting.name, const FieldPreset.value('{{date}}'));
      expect(meeting.fields, {
        'who': const FieldPreset.ask(),
        'p': const FieldPreset.value('alpha'),
      });
      expect(meeting.open, isFalse);
      expect(meeting.toJson()['colour'], 'red');
    });

    test('a broken grid cell is the default size, settled at the foot', () {
      final layout = _read(
        '{"recent": {"kind": "recent", "grid": [0, 0, 1, 2]},'
        ' "pinned": {"kind": "pinned", "grid": "nonsense"}}',
      ).settled();
      expect(layout['pinned']!.cell, (x: 0, y: 2, w: 1, h: 1));
    });

    test('a cell off the grid is clamped onto it', () {
      final layout = _read('{"r": {"kind": "recent", "grid": [3, -2, 9, 0]}}');
      expect(layout['r']!.cell, (x: 0, y: 0, w: 4, h: 1));
    });
  });

  group('settled', () {
    HomeLayout grid(Map<String, HomeCell> cells) => HomeLayout([
      for (final (i, e) in cells.entries.indexed)
        HomeTile(id: e.key, kind: HomeTileKind.pinned, cell: e.value, at: i),
    ]);

    test(
      'two tiles a merge put on the same cells: the later one goes down',
      () {
        final layout = grid({
          'a': (x: 0, y: 0, w: 2, h: 1),
          'b': (x: 1, y: 0, w: 2, h: 1),
        }).settled();
        expect(layout['a']!.cell, (x: 0, y: 0, w: 2, h: 1));
        expect(layout['b']!.cell, (x: 1, y: 1, w: 2, h: 1));
      },
    );

    test('the tile just placed keeps its place, the other one moves', () {
      final layout = grid({
        'a': (x: 0, y: 0, w: 2, h: 1),
        'b': (x: 1, y: 0, w: 2, h: 1),
      }).settled(first: 'b');
      expect(layout['b']!.cell, (x: 1, y: 0, w: 2, h: 1));
      expect(layout['a']!.cell, (x: 0, y: 1, w: 2, h: 1));
    });

    test('tiles rise into the gap a removed one left', () {
      final layout = grid({
        'a': (x: 0, y: 2, w: 1, h: 1),
        'b': (x: 1, y: 5, w: 1, h: 2),
      }).settled();
      expect(layout['a']!.cell.y, 0);
      expect(layout['b']!.cell.y, 0);
    });

    test('a hidden tile is neither moved nor in the way', () {
      final layout = const HomeLayout([
        HomeTile(
          id: 'h',
          kind: HomeTileKind.recent,
          cell: (x: 0, y: 0, w: 4, h: 4),
          at: 0,
          hidden: true,
        ),
        HomeTile(
          id: 'a',
          kind: HomeTileKind.pinned,
          cell: (x: 0, y: 3, w: 1, h: 1),
          at: 1,
        ),
      ]).settled();
      expect(layout['h']!.cell, (x: 0, y: 0, w: 4, h: 4));
      expect(layout['a']!.cell.y, 0);
    });
  });

  group('add', () {
    test('shows again the hidden tile of a kind a Home holds once', () {
      final hidden = HomeLayout.defaults.put(
        HomeLayout.defaults['recent']!.copyWith(hidden: true),
      );
      final shown = hidden.add(HomeTileKind.recent);
      expect(shown.tiles, hasLength(hidden.tiles.length));
      expect(shown['recent']!.hidden, isFalse);
      expect(shown.column.last.id, 'recent');
    });

    test('is a no-op for a shown one of a kind a Home holds once', () {
      expect(HomeLayout.defaults.add(HomeTileKind.recent), HomeLayout.defaults);
    });

    test('adds another search tile under a fresh id, at the foot', () {
      final once = HomeLayout.defaults.add(
        HomeTileKind.search,
        random: Random(1),
      );
      final twice = once.add(HomeTileKind.search, random: Random(1));
      final searches = twice.tiles
          .where((t) => t.kind == HomeTileKind.search)
          .toList();
      expect(searches, hasLength(2));
      expect(searches[0].id, isNot(searches[1].id));
      expect(searches[0].id, startsWith('search-'));
      expect(once['pinned']!.cell.y + 1, searches[0].cell.y);
    });
  });

  test('ordered renumbers the column, the rest after', () {
    final layout = HomeLayout.defaults.ordered(['pinned', 'recent']);
    expect(layout.column.map((t) => t.id), [
      'pinned',
      'recent',
      'actions',
      'journalToday',
      'tasksDue',
    ]);
  });

  group('renamed', () {
    final layout = _read(
      '{"a": {"kind": "actions", "actions": [ '
      '{"id": "1", "label": "M", "do": "newNote",'
      ' "template": "Templates/Meeting.md", "folder": "Work/Meetings"}, '
      '{"id": "2", "label": "O", "do": "openNote", "path": "Work/Plan.md"}]}}',
    );

    test('a renamed template is followed', () {
      final next = layout.renamed(
        'Templates/Meeting.md',
        'Templates/Call.md',
        isDir: false,
      );
      expect(next['a']!.actions.first.template, 'Templates/Call.md');
    });

    test('a renamed folder carries the folder and what is under it', () {
      final next = layout.renamed('Work', 'Job', isDir: true);
      final [meeting, open] = next['a']!.actions;
      expect(meeting.folder, 'Job/Meetings');
      expect(open.path, 'Job/Plan.md');
    });

    test('a move that touches nothing returns the same layout', () {
      expect(
        identical(layout.renamed('Other', 'Else', isDir: true), layout),
        isTrue,
      );
    });
  });

  group('HomeAction', () {
    test('asks before a new note only when something is asked', () {
      const plain = HomeAction(
        id: 'a',
        label: '',
        kind: HomeActionKind.newNote,
        name: FieldPreset.value('Inbox'),
      );
      expect(plain.asks, isFalse);
      expect(plain.copyWith(name: const FieldPreset.ask()).asks, isTrue);
      expect(plain.copyWith(template: 'T/x.md').asks, isTrue);
      expect(
        const HomeAction(id: 'j', label: '', kind: HomeActionKind.journal).asks,
        isFalse,
      );
    });

    test('needs its template and its note, never its folder', () {
      const action = HomeAction(
        id: 'a',
        label: '',
        kind: HomeActionKind.newNote,
        template: 'T/x.md',
        folder: 'Inbox',
      );
      expect(action.requiredPaths, ['T/x.md']);
    });
  });
}
