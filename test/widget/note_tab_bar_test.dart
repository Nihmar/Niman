// Issue #23: the tab row — the note's name, the unsaved dot that gives
// way to the close under the pointer, a middle click that closes, and
// the ▾ list of every tab.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/deferred_listenable.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/workspace_tab.dart';

/// A note with a settable dirty bit, as the editor's is while it is typed
/// into.
final class _Note implements UnsavedNote {
  new(this.path);

  @override
  final String path;

  @override
  bool unsaved = false;

  @override
  Future<void> save() async => unsaved = false;
}

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

  testWidgets('ten keystrokes rebuild the row once (#362)', (tester) async {
    // The shell's own wiring for the row: the workspace and the unsaved
    // tracker merged into a listenable the row redraws on
    // (`Shell._tabsListenable`), the labels laid out per build.
    final tracker = UnsavedTracker();
    final note = _Note('Notes/alpha.md');
    tracker.register(note);
    final tabs = DeferredListenable(Listenable.merge([tracker]));
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 38,
            child: ListenableBuilder(
              listenable: tabs,
              builder: (context, _) {
                builds++;
                return NoteTabBar(
                  tabs: const [WorkspaceTab('Notes/alpha.md')],
                  active: 0,
                  unsaved: tracker.unsavedPaths.toSet(),
                  onActivate: (_) {},
                  onClose: (_) {},
                  onNew: () {},
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(builds, 1);

    // Ten characters typed into the note, each in the frame a keystroke
    // gets: the first one gives the note its dot, and the other nine
    // change nothing the row draws.
    for (var at = 0; at < 10; at++) {
      note.unsaved = true;
      tracker.noteChanged();
      await tester.pump();
    }

    expect(find.byKey(const Key('note-tab-dot-0')), findsOne);
    expect(builds, 2);
  });
}
