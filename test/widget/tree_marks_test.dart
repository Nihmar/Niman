// #712: several tree rows at once, and the tree's last keys — Shift+click
// and Shift+the arrows mark rows, Space marks one, Esc lets go; a right
// click on a marked row opens the rows' menu, Delete deletes them all;
// Ctrl+Enter opens a note in a new tab, and letters jump by name.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession session;
  late _Calls calls;

  setUp(() {
    session = FakeLibrarySession();
    calls = _Calls();
  });
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await session.open('/lib', create: false);
    await session.createFolder(parentPath: '', name: 'Zulu');
    for (final name in ['alpha', 'bravo', 'charlie', 'delta']) {
      await session.createNote(parentPath: '', name: name);
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _Host(session: session, calls: calls),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A folder's click gives the tree the keys.
    await tester.tap(noteRow('Zulu'));
    await tester.pumpAndSettle();
  }

  Future<void> shiftTap(WidgetTester tester, String name) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(noteRow(name));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('Shift+click marks a range; a right click on it opens the '
      "rows' menu, Delete deletes them all", (tester) async {
    await pump(tester);
    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();
    await shiftTap(tester, 'charlie.md');
    expect(calls.opened, ['Zulu', 'alpha.md'], reason: 'a mark opens none');

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(calls.deleted.single, {'alpha.md', 'bravo.md', 'charlie.md'});

    // The marks went with the delete: a right click is a row's again.
    await tester.tap(noteRow('bravo.md'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.rowMenus, ['bravo.md']);

    // Marked again, a right click on them opens their menu.
    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();
    await shiftTap(tester, 'charlie.md');
    await tester.tap(noteRow('bravo.md'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.menus.single, {'alpha.md', 'bravo.md', 'charlie.md'});
    expect(calls.rowMenus, ['bravo.md']);
  });

  testWidgets('Shift+arrows and Space mark from the keyboard, Esc lets go', (
    tester,
  ) async {
    await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    // Space marks or unmarks the cursor's row: bravo goes.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.tap(noteRow('alpha.md'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.menus.single, {'Zulu', 'alpha.md'});

    // The menu acted: the marks went with it (#979), so a right click on
    // a row that was marked is that row's again.
    await tester.tap(noteRow('alpha.md'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.rowMenus, ['alpha.md']);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.tap(noteRow('charlie.md'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.menus.last.length, greaterThan(1));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.tap(noteRow('charlie.md'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.rowMenus, ['alpha.md', 'charlie.md']);
  });

  testWidgets('marks outlive neither the marked menu nor a plain move of the '
      'cursor: Delete then goes to the cursor row (#979)', (tester) async {
    await pump(tester);
    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();
    await shiftTap(tester, 'charlie.md');
    await tester.tap(noteRow('bravo.md'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(calls.menus, hasLength(1));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(calls.deleted, isEmpty, reason: 'the menu let the marks go');
    expect(calls.deletedOne, ['delta.md']);

    // Shift+arrows mark; a plain arrow elsewhere lets them go.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(calls.deleted, isEmpty);
    expect(calls.deletedOne.last, 'alpha.md');
  });

  testWidgets('marks of rows that left the tree are dropped, so Delete does '
      'not go to paths that are gone (#979)', (tester) async {
    await pump(tester);
    await tester.tap(noteRow('alpha.md'));
    await tester.pumpAndSettle();
    await shiftTap(tester, 'charlie.md');
    await session.delete('alpha.md');
    await session.delete('bravo.md');
    await tester.pumpAndSettle();
    expect(noteRow('alpha.md'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(calls.deleted, isEmpty);
    expect(calls.deletedOne, ['charlie.md']);
  });

  testWidgets('Ctrl+Enter opens in a new tab; letters jump by name', (
    tester,
  ) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(calls.newTabs, ['charlie.md']);

    await tester.pump(const Duration(seconds: 2));
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls.opened.last, 'bravo.md');
  });
}

final class _Calls {
  final opened = <String>[];
  final newTabs = <String>[];
  final rowMenus = <String>[];
  final menus = <Set<String>>[];
  final deleted = <Set<String>>[];
  final deletedOne = <String>[];
}

final class _Host extends StatefulWidget {
  const new({required this.session, required this.calls});

  final FakeLibrarySession session;
  final _Calls calls;

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  final Set<String> _expanded = <String>{};
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final calls = widget.calls;
    return NoteTree(
      controller: widget.session,
      selectedPath: _selected,
      expanded: _expanded,
      onToggle: (path) => setState(() {
        if (!_expanded.remove(path)) _expanded.add(path);
      }),
      onSelect: (note) {
        setState(() => _selected = note.path);
        calls.opened.add(note.path);
      },
      onOpenInNewTab: (note) => calls.newTabs.add(note.path),
      onSecondaryTapDown: (note, _) => calls.rowMenus.add(note.path),
      onMarkedMenu: (paths, _) => calls.menus.add(paths.toSet()),
      onDeleteMarked: (paths) => calls.deleted.add(paths.toSet()),
      onDelete: calls.deletedOne.add,
    );
  }
}
