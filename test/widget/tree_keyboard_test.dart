// The tree's keyboard walk (#727): a click puts the cursor on the row, the
// arrows walk it, Home/End and PgUp/PgDn jump, Enter opens and the left and
// right arrows close and open folders — the grid's own walk, in the tree's
// shape. F2 and Delete act on the cursor (through the callbacks the shell
// wires to its row actions), and a modified key is left to the app's own
// accelerators.
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

  testWidgets('a click puts the cursor on the row, and the arrows walk it', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    for (final name in ['alpha', 'bravo', 'charlie']) {
      await session.createNote(parentPath: '', name: name);
    }
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();
    expect(opened, ['alpha.md']);
    // A pointer's click leaves no ring: the ring is the keyboard's.
    expect(ringOn(tester, 'alpha.md'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'bravo.md'), isTrue);
    expect(ringOn(tester, 'alpha.md'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened, ['alpha.md', 'bravo.md']);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'charlie.md');

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'alpha.md', reason: 'up at the first row stays');
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
    await session.createNote(parentPath: '', name: 'c');
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pinned-b.md')));
    await tester.pumpAndSettle();
    expect(ringOnPinned(tester, 'b.md'), isFalse);

    // Down from the last pinned row: the tree's own rows come next, in
    // their order (a.md first), not another pinned one.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'a.md');
  });

  testWidgets('the cursor follows its row when the tree is rebuilt', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    for (final name in ['alpha', 'bravo']) {
      await session.createNote(parentPath: '', name: name);
    }
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await tester.tap(noteRow('bravo.md'));
    await tester.pumpAndSettle();
    // A note that sorts before the cursor's row arrives: the place moved,
    // the row did not.
    await session.createNote(parentPath: '', name: 'aaa');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'bravo.md');
    expect(
      ringOn(tester, 'bravo.md'),
      isTrue,
      reason: 'the keyboard put the ring back',
    );
  });

  testWidgets('F2 and Delete act on the cursor', (tester) async {
    await session.open('/lib', create: false);
    for (final name in ['alpha', 'bravo']) {
      await session.createNote(parentPath: '', name: name);
    }
    final renamed = <String>[];
    final deleted = <String>[];
    await tester.pumpWidget(treeFor(renamed: renamed, deleted: deleted));
    await tester.pumpAndSettle();

    await tester.tap(noteRow('alpha.md'));
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
    await session.open('/lib', create: false);
    for (final name in ['alpha', 'bravo']) {
      await session.createNote(parentPath: '', name: name);
    }
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(ringOn(tester, 'bravo.md'), isTrue);

    // Ctrl+Shift+PageUp is the journal's, Alt+Right the notes' history:
    // the walk must not shadow either (#23).
    await sendWithModifiers(tester, LogicalKeyboardKey.pageUp, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.shiftLeft,
    ]);
    expect(ringOn(tester, 'bravo.md'), isTrue, reason: 'the journal moves');

    await sendWithModifiers(tester, LogicalKeyboardKey.arrowRight, [
      LogicalKeyboardKey.altLeft,
    ]);
    expect(ringOn(tester, 'bravo.md'), isTrue, reason: 'the history moves');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'bravo.md');
  });

  testWidgets('hidden under the grid the tree keeps no keys', (tester) async {
    await session.open('/lib', create: false);
    for (final name in ['alpha', 'bravo']) {
      await session.createNote(parentPath: '', name: name);
    }
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();

    // The grid takes the pane: the tree is offstage, and lets go.
    await tester.pumpWidget(treeFor(active: false, opened: opened));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(opened.last, 'alpha.md', reason: 'the hidden walk moved nothing');
  });

  testWidgets('the page keys jump by a viewport', (tester) async {
    await session.open('/lib', create: false);
    for (var i = 0; i < 30; i++) {
      await session.createNote(
        parentPath: '',
        name: 'n${i.toString().padLeft(2, '0')}',
      );
    }
    final opened = <String>[];
    await tester.pumpWidget(treeFor(opened: opened));
    await tester.pumpAndSettle();

    await tester.tap(noteRow('n00.md'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // A 600 px pane of 40 px rows: fifteen rows, not one.
    expect(opened.last, 'n15.md');
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
