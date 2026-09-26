// #266: the tour's entry points — resuming where it stopped, starting
// over when it is done, and the offer raised exactly once.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/tour/tour_host.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late MemoryWelcomeStore store;
  late FakeLibrarySession controller;

  setUp(() {
    store = MemoryWelcomeStore();
    controller = FakeLibrarySession();
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  /// A page with every tour target laid out, and the entry points: the
  /// tour needs a control to point at for every step, or the step is
  /// skipped and the counters move.
  Widget buildHarness({
    Future<void> Function(BuildContext context, WidgetRef ref)? start,
  }) {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        welcomeStoreProvider.overrideWith((ref) async => store),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final id in TourTargets.all)
                TourTarget(
                  id: id,
                  child: SizedBox(
                    key: Key('target-$id'),
                    width: 160,
                    height: 40,
                  ),
                ),
              Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    TextButton(
                      key: const Key('start-tour'),
                      onPressed: () => (start ?? resumeTour)(context, ref),
                      child: const Text('start'),
                    ),
                    TextButton(
                      key: const Key('offer-tour'),
                      onPressed: () => offerTour(context, ref),
                      child: const Text('offer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pumpHarness(
    WidgetTester tester, {
    Future<void> Function(BuildContext context, WidgetRef ref)? start,
  }) async {
    await tester.pumpWidget(buildHarness(start: start));
    await tester.pumpAndSettle();
  }

  testWidgets('an unfinished tour resumes where it stopped', (tester) async {
    store
      ..tourSeen = false
      ..tourStep = 3;
    await pumpHarness(tester);

    await tester.tap(find.byKey(const Key('start-tour')));
    await tester.pumpAndSettle();

    // Step 4 of 8: the wide window's steps, the modes switch fourth.
    expect(find.text('4 of 8'), findsOne);
    expect(find.text('Three ways to write'), findsOne);
  });

  testWidgets('a finished tour starts over', (tester) async {
    store
      ..tourSeen = true
      ..tourStep = 5;
    await pumpHarness(tester);

    await tester.tap(find.byKey(const Key('start-tour')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 8'), findsOne);
    expect(find.text('Your library'), findsOne);
  });

  testWidgets('the cheatsheet hand-over marks the tour seen and resets it', (
    tester,
  ) async {
    var opened = false;
    await pumpHarness(
      tester,
      start: (context, ref) =>
          startTour(context, ref, openCheatsheet: (_) async => opened = true),
    );

    await tester.tap(find.byKey(const Key('start-tour')));
    await tester.pumpAndSettle();

    // Next to the last step, whose button hands over to the cheatsheet.
    for (
      var i = 0;
      i < 8 && find.byKey(const Key('tour-action')).evaluate().isEmpty;
      i++
    ) {
      await tester.tap(find.byKey(const Key('tour-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('tour-action')), findsOne);
    await tester.tap(find.byKey(const Key('tour-action')));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(store.tourSeen, isTrue);
    expect(store.tourStep, 0, reason: 'the next run starts from the top');
  });

  testWidgets('the offer is raised once, and spent by accepting', (
    tester,
  ) async {
    store.tourOffer = true;
    await pumpHarness(tester);

    await tester.tap(find.byKey(const Key('offer-tour')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tour-offer')), findsOne);
    expect(
      store.tourOffer,
      isFalse,
      reason: 'the offer is spent the moment it is shown',
    );

    await tester.tap(find.byKey(const Key('tour-offer-yes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tour-card')), findsOne);

    // Skipping the tour and asking again raises nothing: the offer was
    // already spent, even though the tour was never finished.
    await tester.tap(find.byKey(const Key('tour-skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('offer-tour')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tour-offer')), findsNothing);
  });

  testWidgets('a library that offers one editor has no modes step', (
    tester,
  ) async {
    await controller.setEnabledEditors({EditorKind.wysiwyg});
    await pumpHarness(tester);

    await tester.tap(find.byKey(const Key('start-tour')));
    await tester.pumpAndSettle();

    // Seven steps, none of them the modes switch.
    expect(find.text('1 of 7'), findsOne);
    for (
      var i = 0;
      i < 7 && find.byKey(const Key('tour-action')).evaluate().isEmpty;
      i++
    ) {
      expect(find.text('Three ways to write'), findsNothing);
      await tester.tap(find.byKey(const Key('tour-next')));
      await tester.pumpAndSettle();
    }
  });
}
