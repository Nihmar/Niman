// Issue #23: the open notes' model — where tabs open, which one shows
// after a close, what renames and deletes do to them, and the stored form.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The paths of [pane]'s tabs, the showing one in brackets.
String _row(Workspace w, [int pane = 0]) {
  final p = w.panes[pane];
  String label(int i) => i == p.active ? '[${p.tabs[i].path}]' : p.tabs[i].path;
  return [for (var i = 0; i < p.tabs.length; i++) label(i)].join(' ');
}

Workspace _opened(List<String> paths) =>
    paths.fold(Workspace.empty, (w, path) => w.open(path));

void main() {
  group('opening', () {
    test('a new note opens after the showing tab, and shows', () {
      final w = _opened(['a.md', 'b.md']).activate(0, 0).open('c.md');
      expect(_row(w), 'a.md [c.md] b.md');
      expect(w.activePath, 'c.md');
    });

    test('a note already open shows where it is: one place only', () {
      final w = _opened(['a.md', 'b.md']).open('a.md');
      expect(_row(w), '[a.md] b.md');
      expect(w.tabs, hasLength(2));
    });

    test('replacing swaps the showing tab for the new note', () {
      final w = _opened(['a.md', 'b.md']).replaceActive('c.md');
      expect(_row(w), 'a.md [c.md]');
    });

    test('replacing with an open note shows it instead', () {
      final w = _opened(['a.md', 'b.md']).replaceActive('a.md');
      expect(_row(w), '[a.md] b.md');
    });

    test('an empty workspace opens its first tab either way', () {
      expect(_row(Workspace.empty.replaceActive('a.md')), '[a.md]');
      expect(Workspace.empty.activePath, isNull);
    });
  });

  group('closing', () {
    test('the showing tab gives way to its right-hand neighbour', () {
      final w = _opened(['a.md', 'b.md', 'c.md']).activate(0, 1).close(0, 1);
      expect(_row(w), 'a.md [c.md]');
    });

    test('at the end of the row, to its left one', () {
      final w = _opened(['a.md', 'b.md', 'c.md']).close(0, 2);
      expect(_row(w), 'a.md [b.md]');
    });

    test('closing a tab before the showing one keeps it showing', () {
      final w = _opened(['a.md', 'b.md', 'c.md']).close(0, 0);
      expect(_row(w), 'b.md [c.md]');
    });

    test('closing the last tab leaves nothing open', () {
      final w = _opened(['a.md']).closePath('a.md');
      expect(w.activePath, isNull);
      expect(w.tabs, isEmpty);
    });

    test('an index that is not there changes nothing', () {
      final w = _opened(['a.md']);
      expect(identical(w.close(0, 5), w), isTrue);
    });
  });

  group('splitting', () {
    test('the second pane opens empty and takes the focus', () {
      final w = _opened(['a.md']).split(SplitAxis.down);
      expect(w.isSplit, isTrue);
      expect(w.axis, SplitAxis.down);
      expect(w.focused, 1);
      expect(w.activePath, isNull);
      expect(_row(w.open('b.md'), 1), '[b.md]');
    });

    test('a note open on the left shows there, not twice', () {
      final w = _opened(['a.md']).split(SplitAxis.right).open('a.md');
      expect(w.focused, 0);
      expect(w.panes[1].isEmpty, isTrue);
    });

    test('emptying the second pane closes the split', () {
      final w = _opened(['a.md'])
          .split(SplitAxis.right)
          .open('b.md')
          .closePath('b.md');
      expect(w.isSplit, isFalse);
      expect(w.focused, 0);
      expect(_row(w), '[a.md]');
    });

    test('emptying the first pane keeps the second, as the only one', () {
      final w = _opened(['a.md'])
          .split(SplitAxis.right)
          .open('b.md')
          .closePath('a.md');
      expect(w.isSplit, isFalse);
      expect(_row(w), '[b.md]');
    });

    test('a tab moves across and shows there', () {
      final w = _opened(['a.md', 'b.md'])
          .split(SplitAxis.right)
          .open('c.md')
          .moveTab(0, 0, 1);
      expect(_row(w), '[b.md]');
      expect(_row(w, 1), 'c.md [a.md]');
      expect(w.focused, 1);
    });

    // #204: dragged, a tab lands where it was dropped.
    test('a tab moves across into a place in the row', () {
      final w = _opened(['a.md', 'b.md'])
          .split(SplitAxis.right)
          .open('c.md')
          .open('d.md')
          .moveTab(0, 0, 1, at: 1);
      expect(_row(w), '[b.md]');
      expect(_row(w, 1), 'c.md [a.md] d.md');
      expect(w.focused, 1);
    });

    test("moving a pane's only tab closes that pane", () {
      final w = _opened(['a.md'])
          .split(SplitAxis.right)
          .open('b.md')
          .moveTab(1, 0, 0);
      expect(w.isSplit, isFalse);
      expect(_row(w), 'a.md [b.md]');
    });

    // #204: dragging a tab along its own row.
    test('a tab is reordered in its row, and keeps showing', () {
      final w = _opened(['a.md', 'b.md', 'c.md']).reorder(0, 0, 2);
      expect(_row(w), 'b.md c.md [a.md]');
    });

    test('a reorder onto its own place changes nothing', () {
      final w = _opened(['a.md', 'b.md']).activate(0, 0);
      expect(_row(w.reorder(0, 0, 0)), '[a.md] b.md');
    });

    test('a reorder past the row lands last, and one outside does nothing', () {
      final w = _opened(['a.md', 'b.md']);
      expect(_row(w.reorder(0, 0, 9)), 'b.md [a.md]');
      expect(w.reorder(0, 5, 0), w);
    });

    test('an empty pane takes the focus, and the next note', () {
      final w = _opened(['a.md']).split(SplitAxis.right).focus(0).focus(1);
      expect(_row(w.open('b.md'), 1), '[b.md]');
    });

    test('splitting with a tab moves it across', () {
      final w = _opened(['a.md', 'b.md']).splitWith(0, 0, SplitAxis.right);
      expect(_row(w), '[b.md]');
      expect(_row(w, 1), '[a.md]');
      expect(w.focused, 1);
    });

    test("splitting with a pane's only tab opens the other empty", () {
      final w = _opened(['a.md']).splitWith(0, 0, SplitAxis.down);
      expect(w.isSplit, isTrue);
      expect(_row(w), '[a.md]');
      expect(w.panes[1].isEmpty, isTrue);
    });

    test('open beside: in the other pane, splitting first if need be', () {
      var w = _opened(['a.md']).openBeside('b.md', SplitAxis.right);
      expect(_row(w, 1), '[b.md]');
      w = w.focus(1).openBeside('c.md', SplitAxis.right);
      expect(_row(w), 'a.md [c.md]');
      expect(w.focused, 0);
      // Already open: shown where it is.
      expect(w.openBeside('b.md', SplitAxis.right).focused, 1);
    });

    test('the divider keeps both panes usable', () {
      final w = _opened(['a.md']).split(SplitAxis.right);
      expect(w.withFraction(0.05).fraction, 0.2);
      expect(w.withFraction(0.99).fraction, 0.8);
    });
  });

  group('the library changing under the tabs', () {
    test('a renamed note keeps its tab, and its memento', () {
      const memento = NoteMemento(selectionExtent: 4);
      final w = _opened(['a.md'])
          .withMemento('a.md', memento)
          .renamed('a.md', 'z.md');
      expect(_row(w), '[z.md]');
      expect(w.tabs.single.memento, memento);
    });

    test('a renamed folder takes every note under it along', () {
      final w = _opened(['Notes/a.md', 'Notes/deep/b.md', 'Notes2/c.md'])
          .renamed('Notes', 'Archive/Notes');
      expect(w.tabs.map((t) => t.path), [
        'Archive/Notes/a.md',
        'Archive/Notes/deep/b.md',
        // A sibling that only shares the prefix is not under it.
        'Notes2/c.md',
      ]);
    });

    test('a rename that touches no tab leaves the workspace as it was', () {
      final w = _opened(['a.md']);
      expect(identical(w.renamed('b.md', 'c.md'), w), isTrue);
    });

    test('a deleted folder closes every tab under it', () {
      final w = _opened(['x.md', 'Notes/a.md', 'Notes/b.md'])
          .activate(0, 1)
          .deleted('Notes');
      expect(_row(w), '[x.md]');
    });

    test('a note gone from disk stays open, marked', () {
      final w = _opened(['a.md', 'b.md']).withMissing({'a.md'});
      expect(w.tabs.first.missing, isTrue);
      expect(w.tabs.last.missing, isFalse);
      // And unmarked once it is back.
      expect(w.withMissing({}).tabs.first.missing, isFalse);
    });
  });

  group('the stored form', () {
    Workspace roundTrip(Workspace w) =>
        Workspace.fromJson(jsonDecode(jsonEncode(w.toJson())));

    test('reads back what it wrote', () {
      final w = _opened(['a.md', 'b.md'])
          .withMemento(
            'a.md',
            const NoteMemento(
              selectionBase: 1,
              selectionExtent: 3,
              scrollOffset: 120.5,
              editorKind: 'wysiwyg',
              preview: false,
            ),
          )
          .split(SplitAxis.down)
          .open('c.md')
          .withFraction(0.3);
      expect(roundTrip(w), w);
    });

    test('the dock, open or shut, and its pane come back (#175)', () {
      final w = _opened(['a.md']).withDock(open: false, pane: DockPane.history);
      final back = roundTrip(w);
      expect(back.dockOpen, isFalse);
      expect(back.dockPane, DockPane.history);
      // Closing every note leaves the dock as it was.
      expect(w.closeAll().dockPane, DockPane.history);
      // A form from before the dock opens it on the outline.
      final old = Workspace.fromJson(const {
        'version': 1,
        'panes': [
          {
            'active': 0,
            'tabs': [
              {'path': 'a.md'},
            ],
          },
        ],
      });
      expect((old.dockOpen, old.dockPane), (true, DockPane.outline));
    });

    test('a missing mark is not stored: it is found again', () {
      final w = _opened(['a.md']).withMissing({'a.md'});
      expect(roundTrip(w).tabs.single.missing, isFalse);
    });

    test('anything unreadable opens nothing', () {
      for (final raw in <Object?>[
        null,
        'nope',
        <String, Object>{},
        {'version': 99, 'panes': <Object>[]},
        {'version': 1, 'panes': 'x'},
      ]) {
        expect(Workspace.fromJson(raw), Workspace.empty, reason: '$raw');
      }
    });

    test('a bad tab is dropped, a note open twice keeps its first tab', () {
      final w = Workspace.fromJson(const {
        'version': 1,
        'focused': 7,
        'panes': [
          {
            'active': 9,
            'tabs': [
              {'path': 'a.md'},
              {'path': ''},
              {'nope': 1},
              {'path': 'b.md', 'memento': 'garbage'},
            ],
          },
          {
            'active': 0,
            'tabs': [
              {'path': 'a.md'},
            ],
          },
        ],
      });
      // The second pane held only the duplicate, so it is gone too.
      expect(w.isSplit, isFalse);
      expect(w.focused, 0);
      expect(_row(w), 'a.md [b.md]');
      expect(w.tabs.last.memento.isEmpty, isTrue);
    });
  });
}
