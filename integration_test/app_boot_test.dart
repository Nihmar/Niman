// The app boots to the opening screen when no library is open.
//
// With a real session it resumes the last library, so on a machine that
// has ever opened one this asked about a screen that was not there. The
// session is a fake with nothing open: the screen under test is the
// app's own, and what it does is the same.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/strings.dart';

import '../test/fakes/fake_library_session.dart';

void main() {
  testWidgets('app boots with the open-library screen', (tester) async {
    final controller = FakeLibrarySession();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appTitle), findsWidgets);
    expect(find.byKey(const Key('branding')), findsOne);
    expect(find.text(AppStrings.openLibraryExisting), findsOne);
    expect(find.text(AppStrings.openLibraryCreate), findsOne);
  });
}
