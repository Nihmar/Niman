// #311: the tokens already in use are offered under the description field,
// and picking one has to land in it — on every platform. On a desktop the
// tap unfocuses the field as it lands, which used to take the list away
// before the tap could fire (the Linux report, 2026-09-27).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';

void main() {
  final field = find.byKey(const Key('todo-dialog-field'));
  const tokens = {'+garden', '@home', '@work', '#urgent'};

  /// Opens the add dialog over the known-[tokens] pool.
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTodoTaskDialog(
                context,
                today: DateTime(2026, 9, 7),
                knownTokens: tokens,
              ),
              child: const Text('open dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();
  }

  /// Starts a context token, which is what puts the pool under the field;
  /// answers the entry for `@home`.
  Future<Finder> offerContexts(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('todo-token-add-@')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('todo-complete-@home')), findsOne);
    expect(find.byKey(const Key('todo-complete-@work')), findsOne);
    return find.byKey(const Key('todo-complete-@home'));
  }

  /// What the description field holds right now.
  String description(WidgetTester tester) =>
      tester.widget<TextField>(field).controller!.text;

  testWidgets('a pick lands where the tap unfocuses the field (desktop)', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await open(tester);
      final entry = await offerContexts(tester);

      // A click is a pointer down, a frame, a pointer up: the field is
      // unfocused on the down (the platform's own `onTapOutside`), and the
      // rebuild that followed used to remove the entry before the up came.
      final gesture = await tester.startGesture(tester.getCenter(entry));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(description(tester), '@home');
      // The caret sits past the token now, so the pool has nothing to offer.
      expect(find.byKey(const Key('todo-complete-@home')), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a pick lands on a phone too', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await open(tester);
      await tester.tap(await offerContexts(tester));
      await tester.pumpAndSettle();
      expect(description(tester), '@home');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
