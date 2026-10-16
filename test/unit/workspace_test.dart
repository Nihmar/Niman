// Issue #23: the open notes' model — where tabs open, which one shows
// after a close, what renames and deletes do to them, and the stored form.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:niman/src/workspace/note_places.dart';
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

  // #1077: the scroll is a place in the note, not a distance.
  group('the scroll of a memento', () {
    test('a place round-trips through the stored form', () {
      const memento = NoteMemento(
        selectionExtent: 4,
        scrollLine: 120,
        scrollFraction: 0.25,
        preview: true,
      );
      final back = NoteMemento.fromJson(
        jsonDecode(jsonEncode(memento.toJson())),
      );
      expect(back, memento);
      expect(back.scrollLine, 120);
      expect(back.scrollFraction, 0.25);
    });

    test('a memento written with pixels still decodes, and says so', () {
      final old = NoteMemento.fromJson(const {
        'base': 3,
        'extent': 3,
        'scroll': 640.5,
        'editor': 'source',
      });
      expect(old.scrollOffset, 640.5);
      expect(old.scrollLine, isNull);
      expect(old.hasScroll, isTrue);
      expect(old.selectionExtent, 3);
    });

    test('a fraction without its line, or out of range, is mended', () {
      expect(NoteMemento.fromJson(const {'into': 0.4}).hasScroll, isFalse);
      final over = NoteMemento.fromJson(const {'line': 9, 'into': 7});
      expect(over.scrollFraction, 1.0);
      expect(NoteMemento.fromJson(const {'line': -1}).hasScroll, isFalse);
    });

    test('a memento that knows no place keeps the tab’s', () {
      const known = NoteMemento(scrollLine: 40, scrollFraction: 0.5);
      final w = _opened(['a.md'])
          .withMemento('a.md', known)
          .withMemento('a.md', const NoteMemento(selectionExtent: 2));
      expect(w.tabs.single.memento.scrollLine, 40);
      expect(w.tabs.single.memento.scrollFraction, 0.5);
      expect(w.tabs.single.memento.selectionExtent, 2);
    });

    test('line 0 is a place, not an absence', () {
      final w = _opened(['a.md'])
          .withMemento('a.md', const NoteMemento(scrollLine: 40))
          .withMemento('a.md', const NoteMemento(scrollLine: 0));
      expect(w.tabs.single.memento.scrollLine, 0);
    });
  });

  // #1069: the tree's expanded folders ride with the workspace.
  group('the expanded folders', () {
    test('survive the stored form; an old one has none', () {
      final w = _opened(['a.md']).withExpanded(['A', 'A/B']);
      final back = Workspace.fromJson(jsonDecode(jsonEncode(w.toJson())));
      expect(back.expanded, ['A', 'A/B']);
      expect(back, w);
      expect(Workspace.empty.toJson().containsKey('expanded'), isFalse);
    });

    test('are deduplicated, mended and bounded to the latest', () {
      final w = Workspace.fromJson(const {
        'version': 1,
        'panes': [
          {'active': 0, 'tabs': <Object>[]},
        ],
        'expanded': ['A', 'A', 3, '', 'B'],
      });
      expect(w.expanded, ['A', 'B']);
      final many = Workspace.empty.withExpanded([
        for (var i = 0; i < Workspace.maxExpanded + 5; i++) 'f$i',
      ]);
      expect(many.expanded.length, Workspace.maxExpanded);
      expect(many.expanded.first, 'f5');
    });

    test('closing every tab leaves the tree as it was', () {
      final w = _opened(['a.md']).withExpanded(['A']).closeAll();
      expect(w.expanded, ['A']);
    });
  });

  group('where a note was left', () {
    // #1075: an editor torn down before it was laid out hands in a memento
    // that cannot say where it was scrolled.
    test('a memento without a scroll keeps the one the tab had', () {
      const scrolled = NoteMemento(selectionExtent: 4, scrollOffset: 640);
      final w = _opened(['a.md'])
          .withMemento('a.md', scrolled)
          .withMemento('a.md', const NoteMemento(selectionExtent: 9));
      expect(w.tabs.single.memento.selectionExtent, 9);
      expect(w.tabs.single.memento.scrollOffset, 640);
    });

    test('a scroll that is known replaces the old one, the top included', () {
      final w = _opened(['a.md'])
          .withMemento('a.md', const NoteMemento(scrollOffset: 640))
          .withMemento('a.md', const NoteMemento(scrollOffset: 0));
      expect(w.tabs.single.memento.scrollOffset, 0);
    });
  });

  // #1076: the position is the note's, not the tab's.
  group('the places of notes that are not open', () {
    const placeA = NoteMemento(selectionExtent: 12, scrollOffset: 300);

    test('a note replaced and opened again comes back where it was', () {
      final w = _opened(['a.md'])
          .withMemento('a.md', placeA)
          .replaceActive('b.md')
          .replaceActive('a.md');
      expect(_row(w), '[a.md]');
      expect(w.tabs.single.memento, placeA);
    });

    test('a note closed and opened again comes back where it was', () {
      final w = _opened(['a.md', 'b.md'])
          .withMemento('a.md', placeA)
          .closePath('a.md')
          .open('a.md');
      expect(w.tabs.firstWhere((t) => t.path == 'a.md').memento, placeA);
    });

    test('the closing editor’s late word, with no tab left, is its place', () {
      final w = _opened(['a.md'])
          .replaceActive('b.md')
          .withMemento('a.md', placeA)
          .replaceActive('a.md');
      expect(w.tabs.single.memento, placeA);
    });

    test('a late word that knows no scroll keeps the place’s scroll', () {
      final w = _opened(['a.md'])
          .withMemento('a.md', placeA)
          .replaceActive('b.md')
          .withMemento('a.md', const NoteMemento(selectionExtent: 40))
          .replaceActive('a.md');
      expect(w.tabs.single.memento.selectionExtent, 40);
      expect(w.tabs.single.memento.scrollOffset, 300);
    });

    test('a rename takes the place along, a folder’s notes too', () {
      final w = _opened(['Notes/a.md'])
          .withMemento('Notes/a.md', placeA)
          .replaceActive('c.md')
          .renamed('Notes', 'Archive')
          .replaceActive('Archive/a.md');
      expect(w.tabs.single.memento, placeA);
      expect(w.places['Notes/a.md'], isNull);
    });

    test('a deleted note keeps no place', () {
      final w = _opened(['a.md'])
          .withMemento('a.md', placeA)
          .replaceActive('b.md')
          .deleted('a.md');
      expect(w.places['a.md'], isNull);
    });

    test('moving a tab to the other pane is not closing it', () {
      final w = _opened(['a.md', 'b.md']).split(SplitAxis.right);
      final moved = w.moveTab(0, 0, 1);
      expect(moved.places.length, 0);
    });

    test('the store is bounded: the least recently left goes first', () {
      var w = Workspace.empty;
      for (var i = 0; i < NotePlaces.capacity + 20; i++) {
        w = w.withMemento('n$i.md', NoteMemento(selectionExtent: i));
      }
      expect(w.places.length, NotePlaces.capacity);
      expect(w.places['n0.md'], isNull);
      expect(w.places['n${NotePlaces.capacity + 19}.md'], isNotNull);
    });

    test('they survive the stored form, and an old one has none', () {
      final w = _opened(['a.md'])
          .withMemento('a.md', placeA)
          .replaceActive('b.md');
      final back = Workspace.fromJson(jsonDecode(jsonEncode(w.toJson())));
      expect(back.places['a.md'], placeA);
      expect(back, w);

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
      expect(old.places.length, 0);
      expect(old.tabs.single.path, 'a.md');
    });

    test('opening before the showing tab leaves the showing tab showing', () {
      final w = _opened(['b.md', 'c.md']).activate(0, 1);
      final back = w.withMemento('a.md', placeA).openBeforeActive('a.md');
      expect(_row(back), 'b.md a.md [c.md]');
      expect(back.tabs.firstWhere((t) => t.path == 'a.md').memento, placeA);
      expect(back.openBeforeActive('b.md'), back);
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

    test('closing every path it names closes the tabs under them too', () {
      final w = _opened(['x.md', 'Notes/a.md', 'Notes/b.md', 'y.md'])
          .activate(0, 1)
          .deletedAll({'Notes', 'y.md'});
      expect(_row(w), '[x.md]');
      expect(w.deletedAll(<String>{}), w, reason: 'no paths, no change');
    });

    test('a note gone from disk stays open, marked', () {
      final w = _opened(['a.md', 'b.md']).withMissing({'a.md'});
      expect(w.tabs.first.missing, isTrue);
      expect(w.tabs.last.missing, isFalse);
      // And unmarked once it is back.
      expect(w.withPresent({'a.md'}).tabs.first.missing, isFalse);
    });

    test('a later removal adds to the marks, it does not replace them', () {
      // The shell hands over each re-index's removals, not every path that
      // is gone: a second note deleted outside the app says nothing about
      // the first, which is still gone.
      final w = _opened(['a.md', 'b.md', 'c.md'])
          .withMissing({'a.md'})
          .withMissing({'b.md'});
      expect(w.tabs.map((t) => t.missing), [true, true, false]);
      expect(w.withMissing({}), w, reason: 'no paths, no change');
    });

    test('only a note found again loses its mark', () {
      final w = _opened(['a.md', 'b.md'])
          .withMissing({'a.md', 'b.md'})
          .withPresent({'b.md'});
      expect(w.tabs.map((t) => t.missing), [true, false]);
    });

    test('a folder gone from disk marks every tab under it', () {
      final w = _opened([
        'x.md',
        'Notes/a.md',
        'Notes/deep/b.md',
        'Notes2/c.md',
      ]).withMissing({'Notes'});
      expect(w.tabs.map((t) => t.missing), [
        false,
        true,
        true,
        // A sibling that only shares the prefix is not under it.
        false,
      ]);
      // A renamed folder takes its marks along, as it takes its paths.
      expect(w.renamed('Notes', 'Archive').tabs.map((t) => t.missing), [
        false,
        true,
        true,
        false,
      ]);
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
