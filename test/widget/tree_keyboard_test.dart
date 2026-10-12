// The tree's keyboard walk (#727): a click on a folder takes the keys and
// the arrows walk the rows, Home/End and PgUp/PgDn jump, Enter opens and
// the left and right arrows close and open folders — the grid's own walk,
// in the tree's shape. A click on a note opens it for writing and leaves
// the keys where they are, F2 and Delete act on the cursor (through the
// callbacks the shell wires to its row actions), and a modified key is left
// to the app's own accelerators.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  /// A tree the test drives the way the shell does: a folder selected is a
  /// folder opened, the rows the callbacks ask for are the ones drawn, and
  /// what the keyboard asks for is recorded.
  Widget treeFor({
    bool active = true,
    List<String>? opened,
    List<String>? renamed,
    List<String>? deleted,
  }) => MaterialApp(
    home: Scaffold(
      body: _Host(
        session: session,
        active: active,
        opened: opened,
        renamed: renamed,
        deleted: deleted,
      ),
    ),
  );

  /// Whether the ring of [container] is drawn: the keyboard's cursor.
  bool ringOf(WidgetTester tester, Finder container) {
    final decoration = tester.widget<Container>(container).foregroundDecoration;
    return decoration is BoxDecoration && decoration.border != null;
  }

  /// Whether the keyboard's ring is drawn on the tree row showing [name].
  bool ringOn(WidgetTester tester, String name) => ringOf(
    tester,
    find.ancestor(of: noteRow(name), matching: find.byType(Container)).first,
  );

  /// Whether the keyboard's ring is drawn on the pinned row at [path].
  bool ringOnPinned(WidgetTester tester, String path) => ringOf(
    tester,
    find
        .descendant(
          of: find.byKey(Key('pinned-$path')),
          matching: find.byType(Container),
        )
        .first,
  );

  /// Sends [key] with [modifiers] held down, as the accelerators are
  /// pressed.
  Future<void> sendWith(
    WidgetTester tester,
    LogicalKeyboardKey key,
    List<LogicalKeyboardKey> modifiers,
  ) async {
    for (final modifier in modifiers) {
      await tester.sendKeyDownEvent(modifier);
    }
    await tester.sendKeyEvent(key);
    for (final modifier in modifiers.reversed) {
      await tester.sendKeyUpEvent(modifier);
    }
    await tester.pump();
  }

  /// Opens the tree over a folder — `Zulu`, which leads the rows — and the
  /// notes given.
  Future<void> openWith(
    WidgetTester tester, {
    List<String> notes = const ['alpha', 'bravo', 'charlie'],
  }) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Zulu');
    for (final name in notes) {
      await session.createNote(parentPath: '', name: name);
    }
  }

  /// Takes the keys the way a person does with the pointer: a click on a
  /// folder's row, which is a place rather than a note to write in.
  Future<void> takeKeys(WidgetTester tester) async {
    await tester.tap(noteRow('Zulu'));
    await tester.pumpAndSettle();
  }

  testWidgets('a folder takes the keys, and the arrows walk the rows', (
    tester,
  ) async {
    await openWith(tester);
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await takeKeys(tester);
    expect(opened, ['Zulu']);
    // A pointer's click leaves no ring: the ring is the keyboard's.
    expect(ringOn(tester, 'Zulu'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'alpha.md'), isTrue);
    expect(ringOn(tester, 'Zulu'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, ['Zulu', 'alpha.md']);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'charlie.md');

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'Zulu'), isTrue, reason: 'up at the first row stays');
  });

  testWidgets('a click on a note leaves the keyboard where it is', (
    tester,
  ) async {
    await openWith(tester, notes: const ['alpha', 'bravo']);
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    // A note opens for writing: the pane must not hold the keys it takes
    // for the walk, or the note could not be typed into (#727). The shell
    // gives the caret to the note itself.
    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();
    expect(opened, ['alpha.md']);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'bravo.md'), isFalse, reason: 'no cursor to move');
    expect(ringOn(tester, 'alpha.md'), isFalse);
  });

  testWidgets('the left and right arrows close and open folders', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Projects');
    await session.createNote(parentPath: 'Projects', name: 'Roadmap');
    await tester.pumpWidget(treeFor());
    await tester.pumpAndSettle();

    // A folder selected is a folder opened, as the shell has it.
    await tester.tap(noteRow('Projects'));
    await tester.pumpAndSettle();
    expect(noteRow('Roadmap.md'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(noteRow('Roadmap.md'), findsNothing, reason: 'the folder closed');
    expect(ringOn(tester, 'Projects'), isTrue);

    // Out of the root there is no parent row: the cursor stays.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'Projects'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(noteRow('Roadmap.md'), findsOneWidget, reason: 'open again');

    // Open already: the right arrow steps into the rows drawn under it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'Roadmap.md'), isTrue);

    // Under a note nothing is drawn.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'Roadmap.md'), isTrue);

    // And the left arrow steps back out to the folder that holds it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'Projects'), isTrue);
  });

  testWidgets('the pinned block is walked before the tree', (tester) async {
    await session.open('/lib', create: false);
    for (final name in ['a', 'b']) {
      await session.createNote(
        parentPath: '',
        name: name,
        content: '---\npinned: true\n---\nbody',
      );
    }
    await session.createFolder(parentPath: '', name: 'Zulu');
    await tester.pumpWidget(treeFor());
    await tester.pumpAndSettle();

    await takeKeys(tester);
    // Up from the first row of the tree: the pinned block, last pinned
    // note first, as the list draws it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(ringOnPinned(tester, 'b.md'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(ringOnPinned(tester, 'a.md'), isTrue);

    // And down from the last pinned note: the tree's own rows, not another
    // pinned one.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOnPinned(tester, 'b.md'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'Zulu'), isTrue);
  });

  testWidgets('the cursor follows its row when the tree is rebuilt', (
    tester,
  ) async {
    await openWith(tester, notes: const ['alpha', 'bravo']);
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await takeKeys(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'bravo.md'), isTrue);

    // A note that sorts before the cursor's row arrives: the place moved,
    // the row did not.
    await session.createNote(parentPath: '', name: 'aaa');
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'bravo.md'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'bravo.md');
  });

  testWidgets('F2 and Delete act on the cursor', (tester) async {
    await openWith(tester, notes: const ['alpha', 'bravo']);
    final renamed = <String>[];
    final deleted = <String>[];
    await tester.pumpWidget(treeFor(renamed: renamed, deleted: deleted));
    await tester.pumpAndSettle();

    await takeKeys(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    expect(renamed, ['bravo.md'], reason: 'the cursor, not the selection');

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(deleted, ['bravo.md']);
  });

  testWidgets('a modified key is left to the app accelerators', (tester) async {
    await openWith(tester, notes: const ['alpha', 'bravo']);
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await takeKeys(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'bravo.md'), isTrue);

    // Ctrl+Shift+PageUp is the journal's, Alt+Right the notes' history:
    // the walk must not shadow either (#23).
    await sendWith(tester, LogicalKeyboardKey.pageUp, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
    ]);
    expect(ringOn(tester, 'bravo.md'), isTrue, reason: 'the journal moves');

    await sendWith(tester, LogicalKeyboardKey.arrowRight, [
      LogicalKeyboardKey.altLeft,
    ]);
    expect(ringOn(tester, 'bravo.md'), isTrue, reason: 'the history moves');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'bravo.md');
  });

  testWidgets('hidden under the grid the tree keeps no keys', (tester) async {
    await openWith(tester, notes: const ['alpha', 'bravo']);
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await takeKeys(tester);

    // The grid takes the pane: the tree is offstage, and lets go.
    await tester.pumpWidget(treeFor(active: false, opened: opened));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'alpha.md'), isFalse, reason: 'the hidden walk ran');
    expect(ringOn(tester, 'Zulu'), isFalse);
  });

  testWidgets('the page keys jump by a viewport', (tester) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Zulu');
    for (var i = 0; i < 30; i++) {
      await session.createNote(
        parentPath: '',
        name: 'n${i.toString().padLeft(2, '0')}',
      );
    }
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await takeKeys(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // A 600 px pane of 40 px rows: fifteen rows, not one — from the
    // folder's own row (0) to the fifteenth (n14).
    expect(opened.last, 'n14.md');
  });
}

final class _Host extends StatefulWidget {
  const new({
    required this.session,
    required this.active,
    this.opened,
    this.renamed,
    this.deleted,
  });

  final FakeLibrarySession session;
  final bool active;
  final List<String>? opened;
  final List<String>? renamed;
  final List<String>? deleted;

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  final Set<String> _expanded = <String>{};
  String? _selected;

  @override
  Widget build(BuildContext context) => NoteTree(
    controller: widget.session,
    selectedPath: _selected,
    expanded: _expanded,
    active: widget.active,
    onToggle: (path) => setState(() {
      if (!_expanded.remove(path)) _expanded.add(path);
    }),
    onSelect: (note) {
      setState(() {
        _selected = note.path;
        if (note.isDir) _expanded.add(note.path);
      });
      widget.opened?.add(note.path);
    },
    onRename: widget.renamed?.add,
    onDelete: widget.deleted?.add,
  );
}
