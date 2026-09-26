// The app boots to the opening screen when no library is open.
//
// With a real session it resumes the last library, so on a machine that
// has ever opened one this asked about a screen that was not there. The
// session is a fake with nothing open: the screen under test is the
// app's own, and what it does is the same.
//
// The first-run state is a fake too (#266): the real store would ask the
// app database, and a fresh one would put the welcome deck in front of
// the screen this file is about.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/strings.dart';

import '../test/fakes/fake_library_session.dart';

void main() {
  testWidgets('app boots with the open-library screen', (tester) async {
    final controller = FakeLibrarySession();
    addTearDown(controller.dispose);
    final welcome = MemoryWelcomeStore()..deckSeen = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          welcomeStoreProvider.overrideWith((ref) async => welcome),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appTitle), findsWidgets);
    expect(find.byKey(const Key('branding')), findsOne);
    expect(find.text(AppStrings.openLibraryExisting), findsOne);
    expect(find.text(AppStrings.openLibraryCreate), findsOne);
  });

  testWidgets('a fresh install is welcomed, and Skip opens the app', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    addTearDown(controller.dispose);
    final welcome = MemoryWelcomeStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          welcomeStoreProvider.overrideWith((ref) async => welcome),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The deck, in front of the open-library screen.
    expect(find.text('Your notes are files'), findsOne);
    expect(find.text(AppStrings.openLibraryExisting), findsNothing);

    await tester.tap(find.byKey(const Key('welcome-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Your notes are files'), findsNothing);
    expect(find.text(AppStrings.openLibraryCreate), findsOne);
    expect(welcome.deckSeen, isTrue);
  });
}
