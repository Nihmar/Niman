import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';

import '../fakes/fake_library_session.dart';

void main() {
  testWidgets('app boots and shows the open-library screen', (tester) async {
    final session = FakeLibrarySession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(session)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Niman'), findsWidgets);
    expect(find.byKey(const Key('branding')), findsOne);
    expect(find.text('Open existing'), findsOne);
    expect(find.text('Create new'), findsOne);
    expect(tester.takeException(), isNull);
  });
}
