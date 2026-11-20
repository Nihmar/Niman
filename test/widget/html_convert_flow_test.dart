// What a web page's conversion does when it ends (#1293): the note's folder
// is shown and the note opened without the library being walked again, and
// only when the library it wrote into is still the one open; a refusal says
// why in the interface's language; a cancel says nothing.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/html/html_conversion.dart';
import 'package:niman/src/ui/html_convert_flow.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

const HtmlConverted _note = (
  made: 'Web/Dune.md',
  open: 'Web/Dune.md',
  notes: 1,
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
  /// Answers whether the pages after it would be converted.
  Future<bool> ends(
    WidgetTester tester, {
    HtmlConverted? result,
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
    final done = Completer<HtmlConverted>();
    final settling =
        HtmlConvertFlow(
          session: session,
          reveal: revealed.add,
          open: opened.add,
        ).settle(
          context,
          done: done.future,
          source: '/cache/1-Dune.html',
          name: 'Dune.html',
          root: '/library',
          messenger: ScaffoldMessenger.maybeOf(context),
        );
    await meanwhile?.call();
    if (error != null) {
      done.completeError(error);
    } else {
      done.complete(result);
    }
    final goOn = await settling;
    await tester.pump();
    return goOn;
  }

  testWidgets('shows the note by its folder and opens it, without a rescan', (
    tester,
  ) async {
    await openLibrary();
    expect(await ends(tester, result: _note), isTrue);
    expect(revealed, ['Web']);
    expect(opened, ['Web/Dune.md']);
    expect(session.rescans, 0, reason: 'the watcher finds what moved in');
    expect(find.textContaining('Web/Dune.md'), findsOneWidget);
  });

  testWidgets('a book made a folder shows the folder and opens its index', (
    tester,
  ) async {
    await openLibrary();
    expect(
      await ends(
        tester,
        result: (
          made: 'Web/The Novel',
          open: 'Web/The Novel/index.md',
          notes: 24,
          pictures: 0,
        ),
      ),
      isTrue,
    );
    expect(revealed, ['Web/The Novel']);
    expect(opened, ['Web/The Novel/index.md']);
    expect(find.textContaining('Web/The Novel'), findsOneWidget);
  });

  testWidgets('a note at the top shows the top', (tester) async {
    await openLibrary();
    await ends(
      tester,
      result: (made: 'Dune.md', open: 'Dune.md', notes: 1, pictures: 0),
    );
    expect(revealed, ['']);
    expect(opened, ['Dune.md']);
  });

  testWidgets('a library closed meanwhile is not shown, nor does it throw', (
    tester,
  ) async {
    await openLibrary();
    await ends(tester, result: _note, meanwhile: session.close);
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
      result: _note,
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
      result: _note,
      // Another screen in its place, under the same app.
      meanwhile: () => tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('elsewhere'))),
      ),
    );
    expect(revealed, isEmpty);
    expect(opened, isEmpty);
  });

  testWidgets('a cancel says nothing and stops the pages after it', (
    tester,
  ) async {
    await openLibrary();
    final goOn = await ends(tester, error: const HtmlConvertCancelled());
    expect(goOn, isFalse);
    expect(revealed, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  group('a refusal says why, by the name it came with', () {
    for (final (refusal, expected) in <(HtmlRefusal, String Function())>[
      (
        HtmlRefusal.notAFile,
        () => AppStrings.htmlConvertUnreadable('Dune.html'),
      ),
      (
        HtmlRefusal.unreadable,
        () => AppStrings.htmlConvertUnreadable('Dune.html'),
      ),
      (HtmlRefusal.tooLarge, () => AppStrings.htmlConvertTooLarge),
      (HtmlRefusal.unsupportedCharset, () => AppStrings.htmlConvertCharset),
    ]) {
      testWidgets(refusal.name, (tester) async {
        await openLibrary();
        final goOn = await ends(tester, error: HtmlRefused(refusal, 'no'));
        expect(goOn, isTrue, reason: 'the next page is another one');
        expect(revealed, isEmpty);
        expect(find.text(expected()), findsOneWidget);
      });
    }
  });

  testWidgets('any other failure is told plainly', (tester) async {
    await openLibrary();
    await ends(tester, error: const HtmlConvertFailed('boom'));
    expect(find.text(AppStrings.htmlConvertFailed), findsOneWidget);
    expect(find.textContaining('boom'), findsNothing);
  });
}
