// A book read aloud in its pane (#1276), over an engine that speaks
// nothing: the button on the book's row where the platform reads aloud
// and nowhere else, the player in the row's place, the dialog for a
// language with no voice, and Back to the voice after a scroll by hand.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:niman/src/ui/epub_read_aloud.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';
import '../fakes/fake_read_aloud_engine.dart';

void main() {
  late Directory dir;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_epub_aloud_');
    EpubReadAloud.lastRate = 1;
  });
  tearDown(() {
    dir.deleteSync(recursive: true);
    EpubLooks.reset();
  });

  String book({String metadata = ''}) => writeTestEpub(
    p.join(dir.path, 'novel.epub'),
    metadata: metadata,
    chapters: [
      (
        path: 'one.xhtml',
        body: '<h1>Chapter one</h1><p>It begins. It goes on.</p>',
      ),
      (
        path: 'two.xhtml',
        body:
            '<h1>Chapter two</h1>'
            '${List.filled(80, '<p>A long paragraph of the book.</p>').join()}',
      ),
    ],
  ).path;

  Future<void> pump(
    WidgetTester tester,
    String path, {
    FakeReadAloudEngine? engine,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpubPane(
              path: path,
              cacheDir: () async => p.join(dir.path, 'cache'),
              readAloud: engine,
            ),
          ),
        ),
      );
      final state = tester.state<EpubPaneState>(find.byType(EpubPane));
      for (var i = 0; i < 250 && state.document == null && !state.failed; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
  }

  final button = find.byKey(const Key('read-aloud-button'));
  final player = find.byKey(const Key('read-aloud-play'));
  final row = find.byKey(const Key('epub-look-button'));

  testWidgets('no engine, no button: the other platforms do not read aloud', (
    tester,
  ) async {
    await pump(tester, book());
    expect(button, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the button reads from the top; the player takes the row', (
    tester,
  ) async {
    final engine = FakeReadAloudEngine();
    await pump(tester, book(), engine: engine);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(player, findsOneWidget);
    expect(row, findsNothing);
    expect(engine.spoken.first.text, 'Chapter one');
    expect(engine.shown?.title, 'A Test Book');
    expect(find.textContaining('paragraph 1 of 2'), findsOneWidget);

    await tester.tap(player);
    await tester.pumpAndSettle();
    expect(engine.stops, 1, reason: 'paused');
    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.byKey(const Key('read-aloud-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('paragraph 2 of 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('read-aloud-speed')));
    await tester.pumpAndSettle();
    expect(find.text('1.25×'), findsOneWidget);

    await tester.tap(find.byKey(const Key('read-aloud-stop')));
    await tester.pumpAndSettle();
    expect(player, findsNothing);
    expect(row, findsOneWidget);
    expect(engine.hides, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no voice for the language: it says so, and leads to one', (
    tester,
  ) async {
    final engine = FakeReadAloudEngine(available: false);
    await pump(
      tester,
      book(metadata: '<dc:language>en</dc:language>'),
      engine: engine,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('read-aloud-no-voice')), findsOneWidget);
    expect(find.text('No voice in English'), findsOneWidget);
    await tester.tap(find.text('Install a voice'));
    await tester.pumpAndSettle();
    expect(engine.settings, 1);
    expect(player, findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use the default voice'));
    await tester.pumpAndSettle();
    expect(player, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a scroll by hand stops following; Back to the voice returns', (
    tester,
  ) async {
    final engine = FakeReadAloudEngine();
    await pump(tester, book(), engine: engine);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final back = find.byKey(const Key('read-aloud-back'));
    expect(back, findsNothing);
    await tester.drag(
      find.text('It begins. It goes on.'),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(back, findsOneWidget);
    expect(player, findsOneWidget, reason: 'the voice goes on');
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(back, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('closing the book ends the reading and its notification', (
    tester,
  ) async {
    final engine = FakeReadAloudEngine();
    await pump(tester, book(), engine: engine);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    expect(engine.hides, 1);
  });
}
