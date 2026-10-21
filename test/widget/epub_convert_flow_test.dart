// What a conversion does when it ends (#1138): the new folder is shown and
// its note opened without the library being walked again, and only when the
// library it wrote into is still the one open.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/ui/epub_convert_flow.dart';

import '../fakes/fake_library_session.dart';

const EpubConverted _folder = (
  made: 'Books/Dune',
  open: 'Books/Dune/index.md',
  notes: 12,
  pictures: 2,
);

void main() {
  late FakeLibrarySession session;
  late List<String> revealed;
  late List<String> opened;

  // Built inside the test, in the zone it runs in: the fake's streams and
  // notifiers belong to it.
  Future<void> openLibrary() async {
    session = FakeLibrarySession();
    revealed = [];
    opened = [];
    await session.open('/library', create: true);
  }

  /// The conversion of a share ends with [result] (or fails with [error]),
  /// [meanwhile] having happened to the screen or the library by then.
  Future<void> ends(
    WidgetTester tester, {
    EpubConverted? result,
    Object? error,
    Future<void> Function()? meanwhile,
  }) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final done = Completer<EpubConverted>();
    final settling =
        EpubConvertFlow(
          session: session,
          reveal: revealed.add,
          open: opened.add,
        ).settle(
          context,
          done: done.future,
          source: '/cache/1-Dune.epub',
          name: 'Dune.epub',
          root: '/library',
          messenger: ScaffoldMessenger.maybeOf(context),
        );
    await meanwhile?.call();
    if (error != null) {
      done.completeError(error);
    } else {
      done.complete(result);
    }
    await settling;
    await tester.pump();
  }

  testWidgets('shows the folder and opens its index, without a rescan', (
    tester,
  ) async {
    await openLibrary();
    await ends(tester, result: _folder);
    expect(revealed, ['Books/Dune']);
    expect(opened, ['Books/Dune/index.md']);
    expect(session.rescans, 0, reason: 'the watcher finds what moved in');
    expect(find.textContaining('Books/Dune'), findsOneWidget);
  });

  testWidgets('one note is shown by the folder it landed in', (tester) async {
    await openLibrary();
    await ends(
      tester,
      result: (
        made: 'Books/Dune.md',
        open: 'Books/Dune.md',
        notes: 1,
        pictures: 0,
      ),
    );
    expect(revealed, ['Books']);
    expect(opened, ['Books/Dune.md']);
  });

  testWidgets('a library closed meanwhile is not shown, nor does it throw', (
    tester,
  ) async {
    await openLibrary();
    await ends(tester, result: _folder, meanwhile: session.close);
    expect(revealed, isEmpty);
    expect(opened, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a library switched meanwhile is not shown in the new one', (
    tester,
  ) async {
    await openLibrary();
    await ends(
      tester,
      result: _folder,
      meanwhile: () => session.switchTo('/other'),
    );
    expect(revealed, isEmpty);
    expect(opened, isEmpty);
    expect(session.rescans, 0);
  });

  testWidgets('a screen that is gone shows nothing', (tester) async {
    await openLibrary();
    await ends(
      tester,
      result: _folder,
      // Another screen in its place, under the same app.
      meanwhile: () => tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('elsewhere'))),
      ),
    );
    expect(revealed, isEmpty);
    expect(opened, isEmpty);
  });

  testWidgets('a refused book says so, by the name it came with', (
    tester,
  ) async {
    await openLibrary();
    await ends(tester, error: const EpubRefused(EpubRefusal.notABook, 'no'));
    expect(revealed, isEmpty);
    expect(find.textContaining('Dune.epub'), findsOneWidget);
  });
}
