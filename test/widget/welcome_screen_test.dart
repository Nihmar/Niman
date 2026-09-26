// #266: the first-run welcome deck — the pages, the Markdown question,
// what leaves it, and the one thing it must never do (stand in front of
// an install that has already been welcomed).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/welcome/welcome_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeShortcutService shortcuts;
  late MemoryWelcomeStore store;
  late FakeFilePicker picker;

  setUp(() {
    controller = FakeLibrarySession();
    shortcuts = FakeShortcutService();
    store = MemoryWelcomeStore();
    picker = useFakeFilePicker();
  });

  Widget buildApp({bool noStore = false}) {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        shortcutServiceProvider.overrideWithValue(shortcuts),
        welcomeStoreProvider.overrideWith((ref) async {
          if (noStore) throw StateError('no database');
          return store;
        }),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> close() async {
    await controller.close();
    await controller.dispose();
    await shortcuts.dispose();
  }

  /// Pumps the app on the deck.
  Future<void> pumpDeck(WidgetTester tester, {bool noStore = false}) async {
    await tester.pumpWidget(buildApp(noStore: noStore));
    await tester.pumpAndSettle();
  }

  /// Taps Next until the question is on screen.
  Future<void> reachQuestion(WidgetTester tester) async {
    for (
      var i = 0;
      i < 10 && find.byKey(const Key('welcome-question')).evaluate().isEmpty;
      i++
    ) {
      await tester.tap(find.byKey(const Key('welcome-next')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('a first run opens on the deck, and Skip leaves it', (
    tester,
  ) async {
    await pumpDeck(tester);

    expect(find.text('Your notes are files'), findsOne);
    expect(find.byKey(const Key('welcome-skip')), findsOne);

    await tester.tap(find.byKey(const Key('welcome-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Your notes are files'), findsNothing);
    expect(
      find.text('Create new'),
      findsOne,
      reason: 'the open-library screen',
    );
    expect(store.deckSeen, isTrue);
    await close();
  });

  testWidgets('Next walks the pages, Back returns, and the last is Start', (
    tester,
  ) async {
    await pumpDeck(tester);

    await tester.tap(find.byKey(const Key('welcome-next')));
    await tester.pumpAndSettle();
    expect(find.text('Three ways to write the same note'), findsOne);

    await tester.tap(find.byKey(const Key('welcome-back')));
    await tester.pumpAndSettle();
    expect(find.text('Your notes are files'), findsOne);

    // Keys do the same.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Three ways to write the same note'), findsOne);

    await reachQuestion(tester);
    expect(find.byKey(const Key('welcome-start')), findsOne);
    expect(find.byKey(const Key('welcome-next')), findsNothing);
    await close();
  });

  testWidgets('the answer is kept as it is tapped, and Start leaves', (
    tester,
  ) async {
    await pumpDeck(tester);
    await reachQuestion(tester);

    await tester.tap(find.byKey(const Key('welcome-answer-none')));
    await tester.pumpAndSettle();
    expect(store.experience, MarkdownExperience.none);

    await tester.tap(find.byKey(const Key('welcome-answer-fluent')));
    await tester.pumpAndSettle();
    expect(store.experience, MarkdownExperience.fluent);

    await tester.tap(find.byKey(const Key('welcome-tour-offer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcome-start')));
    await tester.pumpAndSettle();

    expect(store.tourOffer, isTrue);
    expect(store.deckSeen, isTrue);
    expect(find.text('Create new'), findsOne);
    await close();
  });

  testWidgets('a stored answer comes back selected', (tester) async {
    store.experience = MarkdownExperience.some;

    await pumpDeck(tester);
    await reachQuestion(tester);

    final group = tester.widget<RadioGroup<MarkdownExperience>>(
      find.byType(RadioGroup<MarkdownExperience>),
    );
    expect(group.groupValue, MarkdownExperience.some);
    await close();
  });

  testWidgets('a welcomed install never sees the deck', (tester) async {
    store.deckSeen = true;

    await pumpDeck(tester);

    expect(find.text('Your notes are files'), findsNothing);
    expect(find.text('Create new'), findsOne);
    await close();
  });

  testWidgets('no store at all means no deck', (tester) async {
    // The test bed has no application-support folder; the app must open
    // exactly as it did before the deck existed.
    await pumpDeck(tester, noStore: true);

    expect(find.text('Your notes are files'), findsNothing);
    expect(find.text('Create new'), findsOne);
    await close();
  });

  testWidgets("the welcome's offer starts the tour once a library is open", (
    tester,
  ) async {
    store
      ..deckSeen = true
      ..tourOffer = true;
    await pumpDeck(tester);

    await openLibrary(tester, picker);
    expect(find.byKey(const Key('tour-offer')), findsOne);

    await tester.tap(find.byKey(const Key('tour-offer-yes')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tour-card')), findsOne);
    // The first step is the tree, which the wide layout is showing.
    expect(find.text('Your library'), findsOne);
    expect(
      store.tourOffer,
      isFalse,
      reason: 'the offer is spent the moment it is shown',
    );
    await close();
  });

  testWidgets('declining the offer leaves the tour to Help and the palette', (
    tester,
  ) async {
    store
      ..deckSeen = true
      ..tourOffer = true;
    await pumpDeck(tester);

    await openLibrary(tester, picker);
    await tester.tap(find.byKey(const Key('tour-offer-no')));
    await tester.pumpAndSettle();

    expect(store.tourOffer, isFalse);
    expect(find.byKey(const Key('tour-card')), findsNothing);
    await close();
  });

  testWidgets('a tour already taken is never offered again', (tester) async {
    store
      ..deckSeen = true
      ..tourOffer = true
      ..tourSeen = true;
    await pumpDeck(tester);

    await openLibrary(tester, picker);

    expect(find.byKey(const Key('tour-offer')), findsNothing);
    await close();
  });

  testWidgets('the read-only deck has the pages and no question', (
    tester,
  ) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(readOnly: true, onClose: () => closed = true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your notes are files'), findsOne);
    expect(find.byKey(const Key('welcome-skip')), findsNothing);
    expect(find.byKey(const Key('welcome-close')), findsOne);

    // Through every page: no question, and the last page closes.
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(const Key('welcome-question')), findsNothing);
      final button = find.byKey(const Key('welcome-next'));
      if (button.evaluate().isEmpty) break;
      await tester.tap(button);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('welcome-close')));
    expect(closed, isTrue);
  });
}
