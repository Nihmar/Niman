// #266: the tour on screen — the card beside the control it talks about,
// the walk, the skip, and a step whose control is not there.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tour/tour_overlay.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';

void main() {
  /// Pumps a page with one target on it ('here') and a button that starts
  /// [steps]; answers what the run reported.
  Future<({List<int> steps, List<TourAction> actions, bool Function() done})>
  pumpTour(
    WidgetTester tester,
    List<TourStep> steps, {
    int from = 0,
    List<String> targets = const ['here'],
  }) async {
    final visited = <int>[];
    final actions = <TourAction>[];
    var finished = false;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  for (final id in targets)
                    TourTarget(
                      id: id,
                      child: SizedBox(
                        key: Key('target-$id'),
                        width: 160,
                        height: 48,
                      ),
                    ),
                  TextButton(
                    onPressed: () => unawaited(
                      showTour(
                        context,
                        TourRun(
                          steps: steps,
                          initialStep: from,
                          onStep: visited.add,
                          onDone: () => finished = true,
                          onAction: (action) async => actions.add(action),
                        ),
                      ),
                    ),
                    child: const Text('start'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    return (steps: visited, actions: actions, done: () => finished);
  }

  const one = TourStep(target: 'here', title: 'One', body: 'The first');
  const two = TourStep(target: null, title: 'Two', body: 'The last');

  testWidgets('the card points at the control it talks about', (tester) async {
    await pumpTour(tester, const [one, two]);

    expect(find.byKey(const Key('tour-card')), findsOne);
    expect(find.text('One'), findsOne);
    expect(find.text('1 of 2'), findsOne);

    // Below the control, not over it: the control is the thing to look at.
    final target = tester.getRect(find.byKey(const Key('target-here')));
    final card = tester.getRect(find.byKey(const Key('tour-card')));
    expect(card.top, greaterThanOrEqualTo(target.bottom));
    expect(card.left, lessThan(target.right));
  });

  testWidgets('Next, Back and Done walk the steps', (tester) async {
    final run = await pumpTour(tester, const [one, two]);

    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOne);
    expect(find.byKey(const Key('tour-next')), findsNothing);
    expect(find.byKey(const Key('tour-done')), findsOne);

    await tester.tap(find.byKey(const Key('tour-back')));
    await tester.pumpAndSettle();
    expect(find.text('One'), findsOne);

    await tester.tap(find.byKey(const Key('tour-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tour-done')));
    await tester.pumpAndSettle();

    expect(run.done(), isTrue);
    expect(find.byKey(const Key('tour-card')), findsNothing);
    expect(run.steps, [1, 0, 1]);
  });

  testWidgets('a control that is not on screen is skipped', (tester) async {
    const missing = TourStep(target: 'nope', title: 'Gone', body: '—');
    await pumpTour(tester, const [missing, two]);

    // Straight to the step that has something to show.
    expect(find.text('Two'), findsOne);
    expect(find.text('Gone'), findsNothing);
  });

  testWidgets('the card keeps its margins on a 430 px window', (tester) async {
    // 430 is a phone's width, and the range a fixed 420-wide card left
    // the left clamp no room for.
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpTour(tester, const [one]);

    expect(tester.takeException(), isNull);
    final card = tester.getRect(find.byKey(const Key('tour-card')));
    expect(card.left, greaterThanOrEqualTo(0));
    expect(card.right, lessThanOrEqualTo(430));
  });

  testWidgets('Skip leaves, and the tour says where it was', (tester) async {
    final run = await pumpTour(tester, const [one, two], from: 1);
    expect(find.text('Two'), findsOne);

    await tester.tap(find.byKey(const Key('tour-skip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tour-card')), findsNothing);
    expect(run.done(), isFalse, reason: 'skipped, not finished');
  });

  testWidgets('a step with an action runs it and leaves', (tester) async {
    const handover = TourStep(
      target: 'here',
      title: 'Every construct',
      body: 'The cheatsheet',
      action: TourAction.cheatsheet,
    );
    final run = await pumpTour(tester, const [handover]);

    expect(find.byKey(const Key('tour-action')), findsOne);
    await tester.tap(find.byKey(const Key('tour-action')));
    await tester.pumpAndSettle();

    expect(run.actions, [TourAction.cheatsheet]);
    expect(find.byKey(const Key('tour-card')), findsNothing);
  });
}
