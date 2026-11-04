// The shell's selection as one owned model (#1256): each transition between
// screens says what is selected, what shows, which request is pending, and
// what it did to the note on screen.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/ui/expanded_folders.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_selection.dart';

void main() {
  late ShellNavigationState nav;
  late ExpandedFolders expanded;
  late ShellSelection selection;
  late List<NoteShift> shifts;

  setUp(() {
    nav = ShellNavigationState(features: () => const Features());
    expanded = ExpandedFolders();
    selection = ShellSelection(nav: nav, expanded: expanded);
    shifts = [];
    selection.addListener(() => shifts.add(selection.shift));
  });
  tearDown(() {
    selection.dispose();
    nav.dispose();
    expanded.dispose();
  });

  group('open', () {
    test('a note takes the screen, the tab it came from kept for back', () {
      nav.tab = ShellTab.search;
      selection.open(
        'notes/a.md',
        request: const OpenRequest(anchor: 'Intro', find: ['word']),
      );

      expect(selection.path, 'notes/a.md');
      expect(selection.isDir, isFalse);
      expect(selection.treeVisible, isFalse);
      expect(selection.noteOnScreen, 'notes/a.md');
      expect(nav.noteFrom, ShellTab.search);
      expect(selection.request.anchor, 'Intro');
      expect(selection.request.find, ['word']);
      expect(shifts, [NoteShift.opened]);
      expect(selection.shift, NoteShift.none, reason: 'only while notified');
    });

    test('the note already open is asked to re-read its file', () {
      selection.open('a.md');
      final before = selection.reloadToken;
      selection.open('b.md');
      expect(selection.reloadToken, before);
      selection.open('b.md');
      expect(selection.reloadToken, before + 1);
    });

    test('a wide window whose panes are out of sight visits Files', () {
      nav.tab = ShellTab.todo;
      selection.open('a.md', bringFiles: true);
      expect(nav.visited, contains(ShellTab.files));
      expect(nav.tab, ShellTab.files);
      expect(nav.noteFrom, ShellTab.todo);
    });

    test('a link followed is counted; a plain open is not', () {
      selection.open('a.md');
      expect(selection.linksFollowed, 0);
      selection.open('b.md', followsLink: true);
      expect(selection.linksFollowed, 1);
    });

    test('a preview asked for is taken once, by the build', () {
      selection.open('a.md', preview: true);
      shifts.clear();
      expect(selection.takePreview(), 'a.md');
      expect(selection.takePreview(), isNull);
      expect(shifts, isEmpty, reason: 'read in a build, it notifies nobody');
    });
  });

  group('pick', () {
    test('a note picked clears the request a link left', () {
      selection
        ..open('a.md', request: const OpenRequest(anchor: 'Intro', caret: 3))
        ..pick('b.md', isDir: false);
      expect(selection.path, 'b.md');
      expect(selection.request.anchor, isNull);
      expect(selection.request.caret, isNull);
      expect(selection.treeVisible, isFalse);
      expect(shifts.last, NoteShift.opened);
    });

    test('a folder picked closes the note and opens in the tree', () {
      selection
        ..open('a.md')
        ..pick('notes', isDir: true);
      expect(selection.path, 'notes');
      expect(selection.isDir, isTrue);
      expect(selection.note, isNull);
      expect(selection.treeVisible, isTrue);
      expect(expanded.contains('notes'), isTrue);
      expect(shifts.last, NoteShift.closed);
    });
  });

  test('close gives the tree back on the tab the note came from', () {
    nav.tab = ShellTab.home;
    selection.open('a.md', bringFiles: true);
    expect(nav.tab, ShellTab.files);

    selection.close();
    expect(nav.tab, ShellTab.home);
    expect(selection.treeVisible, isTrue);
    expect(selection.path, 'a.md', reason: 'the note stays highlighted');
    expect(selection.noteOnScreen, isNull);
    expect(shifts.last, NoteShift.closed);
  });

  test('the quick note opens in its tab, back to where it was asked', () {
    nav.tab = ShellTab.todo;
    selection.openQuickNote('quick.md', from: ShellTab.home, reload: true);
    expect(nav.tab, ShellTab.quickNote);
    expect(nav.noteFrom, ShellTab.home);
    expect(selection.noteOnScreen, 'quick.md');
    expect(selection.reloadToken, 1);
    expect(shifts, [NoteShift.opened]);
  });

  group('folders', () {
    test('a folder selected leaves the note on screen alone', () {
      selection
        ..open('a.md')
        ..selectFolder('notes');
      expect(selection.path, 'notes');
      expect(selection.isDir, isTrue);
      expect(selection.treeVisible, isFalse);
      expect(expanded.contains('notes'), isTrue);
      expect(shifts.last, NoteShift.none);
    });

    test('the root selects nothing', () {
      selection.selectFolder('');
      expect(selection.path, isNull);
      expect(selection.isDir, isFalse);
      expect(selection.folder, '');
    });

    test('a folder made is selected without opening', () {
      selection.selectFolder('new', expand: false);
      expect(selection.path, 'new');
      expect(expanded.contains('new'), isFalse);
    });

    test('a folder revealed shows Files, the tree pane, its ancestors', () {
      selection
        ..toggleSidebar()
        ..revealFolder('a/b/c');
      expect(nav.tab, ShellTab.files);
      expect(selection.sidebarVisible, isTrue);
      expect(expanded.folders, containsAll(['a', 'a/b', 'a/b/c']));
      expect(selection.path, 'a/b/c');
      expect(selection.isDir, isTrue);
      expect(selection.treeVisible, isTrue);
    });

    test('a note revealed is the selected row, its folder open', () {
      selection
        ..open('a/b/n.md')
        ..revealNote('a/b/n.md');
      expect(selection.path, 'a/b/n.md');
      expect(selection.isDir, isFalse);
      expect(selection.treeVisible, isTrue);
      expect(expanded.folders, containsAll(['a', 'a/b']));
      expect(selection.folder, 'a/b');
    });

    test('a folder toggles open and closed', () {
      selection.toggleFolder('x');
      expect(expanded.contains('x'), isTrue);
      selection.toggleFolder('x');
      expect(expanded.contains('x'), isFalse);
    });
  });

  group('follow', () {
    test('the tree follows the showing tab', () {
      selection
        ..selectFolder('notes')
        ..follow('b.md');
      expect(selection.path, 'b.md');
      expect(selection.isDir, isFalse);
    });

    test('with no tab showing, only a selected folder stays', () {
      selection
        ..open('a.md')
        ..follow(null);
      expect(selection.path, isNull);

      selection
        ..selectFolder('notes')
        ..follow(null);
      expect(selection.path, 'notes');
    });

    test('nothing changed, nobody is told', () {
      selection.open('a.md');
      shifts.clear();
      selection.follow('a.md');
      expect(shifts, isEmpty);
    });
  });

  group('rename and delete', () {
    test('the selection follows a rename that is about it', () {
      selection
        ..open('old/n.md')
        ..moved('old', 'new');
      expect(selection.path, 'new/n.md');
    });

    test('a rename of another row leaves the selection alone', () {
      selection
        ..open('keep/n.md')
        ..moved('other', 'renamed');
      expect(selection.path, 'keep/n.md');
    });

    test('folders open under a moved folder stay open', () {
      expanded.add('old/sub');
      selection.moved('old', 'new');
      expect(expanded.contains('new/sub'), isTrue);
    });

    test('on a phone, a delete lets go of the selection', () {
      selection
        ..open('a.md')
        ..deleted('other.md', wide: false);
      expect(selection.path, isNull);
    });

    test('on a wide window, only a selected folder it took goes', () {
      selection
        ..open('a.md')
        ..deleted('a.md', wide: true);
      expect(selection.path, 'a.md', reason: 'the workspace moves the tab');

      selection
        ..selectFolder('dir/sub')
        ..deleted('dir', wide: true);
      expect(selection.path, isNull);
    });

    test('clearIf lets go only of the path given', () {
      selection
        ..open('a.md')
        ..clearIf('b.md');
      expect(selection.path, 'a.md');
      selection.clearIf('a.md');
      expect(selection.path, isNull);
    });
  });

  group('reload', () {
    test('only a selected note is asked, and only when it changed', () {
      selection
        ..selectFolder('notes')
        ..reloadOpen();
      expect(selection.reloadToken, 0);

      selection
        ..open('a.md')
        ..reloadOpen({'b.md'});
      expect(selection.reloadToken, 0);
      selection.reloadOpen({'a.md'});
      expect(selection.reloadToken, 1);
      selection.reloadOpen();
      expect(selection.reloadToken, 2);
    });
  });

  test('the caret is asked of the note the Files pane opened', () {
    selection.requestCaret('a.md');
    expect(selection.caretPath, 'a.md');
    expect(selection.caretRequest, 1);
    selection.requestCaret('a.md');
    expect(selection.caretRequest, 2);
  });

  test('the tree pane shows, hides, and shows again', () {
    expect(selection.sidebarVisible, isTrue);
    selection.toggleSidebar();
    expect(selection.sidebarVisible, isFalse);
    selection.showSidebar();
    expect(selection.sidebarVisible, isTrue);
  });

  test('a tab switch brings the phone tree back', () {
    selection
      ..open('a.md')
      ..showTree();
    expect(selection.treeVisible, isTrue);
    expect(shifts.last, NoteShift.none);
  });
}
