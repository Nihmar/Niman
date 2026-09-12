// The first index of a library is a long silent wait behind a progress
// bar. Naming the note being read turns it into something to watch, and
// says the app is working rather than stuck (user, 2026-09-09).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() {
    session = FakeLibrarySession();
  });

  tearDown(() async {
    session.openGate?.complete();
    await session.dispose();
  });

  /// Pumps the app on the open screen, then starts an open that stays in
  /// its opening phase until the gate is completed.
  Future<void> pumpOpening(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(session)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    session.openGate = Completer<void>();
    unawaited(session.open(p.join('/fake', 'library'), create: false));
    // Two frames: one to deliver the session's event, one to rebuild the
    // screen on the opening phase it announced.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the note being read is named under the progress bar', (
    tester,
  ) async {
    session.indexing = const IndexProgress(
      file: 'Projects/Deep/note.md',
      done: 12,
      of: 400,
    );
    await pumpOpening(tester);

    expect(find.byType(LinearProgressIndicator), findsOne);
    expect(find.text('Projects/Deep/note.md'), findsOne);
    expect(find.text(AppStrings.indexingCount(12, 400)), findsOne);
  });

  testWidgets('the name changes as the scan moves on', (tester) async {
    session.indexing = const IndexProgress(file: 'a.md', done: 1, of: 3);
    await pumpOpening(tester);
    expect(find.text('a.md'), findsOne);

    session
      ..indexing = const IndexProgress(file: 'b.md', done: 2, of: 3)
      ..notify();
    await tester.pump();
    expect(find.text('a.md'), findsNothing);
    expect(find.text('b.md'), findsOne);
  });

  testWidgets('a long path is kept to one line', (tester) async {
    // The names change many times a second; a line that wrapped would
    // make the whole screen jump with them.
    session.indexing = const IndexProgress(
      file: 'A very deep folder/inside another one/with a long note name.md',
      done: 7,
      of: 9,
    );
    await pumpOpening(tester);

    final text = tester.widget<Text>(find.byKey(const Key('indexing-file')));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('nothing is shown when there is no scan running', (tester) async {
    await pumpOpening(tester);
    expect(find.byType(LinearProgressIndicator), findsOne);
    expect(find.byKey(const Key('indexing-file')), findsNothing);
  });

  testWidgets('the line goes when the library is open', (tester) async {
    session.indexing = const IndexProgress(file: 'a.md', done: 1, of: 3);
    await pumpOpening(tester);
    expect(find.byKey(const Key('indexing-file')), findsOne);

    session.indexing = null;
    session.openGate!.complete();
    session.openGate = null;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('indexing-file')), findsNothing);
  });
}
