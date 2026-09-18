// Issue #23: the tab row — the note's name, the unsaved dot that gives
// way to the close under the pointer, a middle click that closes, and
// the ▾ list of every tab.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/workspace/workspace_tab.dart';

void main() {
  final activated = <int>[];
  final closed = <int>[];

  setUp(() {
    activated.clear();
    closed.clear();
  });

  Future<void> pump(WidgetTester tester, {Set<String> unsaved = const {}}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 38,
              child: NoteTabBar(
                tabs: const [
                  WorkspaceTab('Notes/alpha.md'),
                  WorkspaceTab('todo.txt'),
                ],
                active: 0,
                unsaved: unsaved,
                onActivate: activated.add,
                onClose: closed.add,
                onNew: () {},
              ),
            ),
          ),
        ),
      );

  test('a tab reads the name the tree reads', () {
    expect(noteTabLabel('Notes/alpha.md'), 'alpha');
    expect(noteTabLabel('todo.txt'), 'todo.txt');
  });

  testWidgets('a tab is its name; a click shows it', (tester) async {
    await pump(tester);
    expect(find.text('alpha'), findsOne);
    expect(find.text('todo.txt'), findsOne);
    await tester.tap(find.text('todo.txt'));
    expect(activated, [1]);
  });

  testWidgets('the showing tab has its close; the others on hover', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const Key('note-tab-close-0')), findsOne);
    expect(find.byKey(const Key('note-tab-close-1')), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('todo.txt')));
    await tester.pump();
    expect(find.byKey(const Key('note-tab-close-1')), findsOne);
    await tester.tap(find.byKey(const Key('note-tab-close-1')));
    expect(closed, [1]);
    await mouse.removePointer();
  });

  testWidgets('unsaved, the dot stands where the close would', (tester) async {
    await pump(tester, unsaved: {'Notes/alpha.md'});
    expect(find.byKey(const Key('note-tab-dot-0')), findsOne);
    expect(find.byKey(const Key('note-tab-close-0')), findsNothing);
    // Under the pointer, the close comes back.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('alpha')));
    await tester.pump();
    expect(find.byKey(const Key('note-tab-dot-0')), findsNothing);
    expect(find.byKey(const Key('note-tab-close-0')), findsOne);
    await mouse.removePointer();
  });

  testWidgets('a middle click closes', (tester) async {
    await pump(tester);
    await tester.tap(find.text('todo.txt'), buttons: kMiddleMouseButton);
    expect(closed, [1]);
  });

  testWidgets('the ▾ list shows every tab and picks one', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('tab-list')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-list-0')), findsOne);
    // The folder rides under the name, so two notes called alike differ.
    expect(find.text('Notes'), findsOne);
    await tester.tap(find.byKey(const Key('tab-list-1')));
    await tester.pumpAndSettle();
    expect(activated, [1]);
  });
}
