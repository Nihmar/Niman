// Looking up a selection of a book (#1383): the menu's first entry, in the
// book's language; the panel's Annotate with the definition, which hands the
// passage over with the definition as its comment, and is greyed where the
// book is in no library; and the key.
//
// XHTML is written in pieces, and a space between two would be a word of
// the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';
import '../fakes/fake_library_session.dart';
import '../fakes/fake_read_aloud_engine.dart';
import '../unit/dictionary/fixture_packs.dart';

void main() {
  late Directory dir;
  late DictionaryService service;
  late DictionaryInstallation installation;
  late FakeLibrarySession library;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('niman_epub_look');
    final packs = Directory(p.join(dir.path, 'dictionary'));
    service = DictionaryService(directory: packs.path);
    await writeFixturePacks(packs.path);
    await service.prepare('it');
    installation = DictionaryInstallation(
      directory: () async => packs.path,
      service: () async => service,
      catalog: const [],
    );
    await installation.load();
    library = FakeLibrarySession();
    await library.open('/fake/library', create: true);
  });

  tearDown(() async {
    installation.dispose();
    await service.dispose();
    EpubLooks.reset();
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  String book({String metadata = '<dc:language>it-IT</dc:language>'}) =>
      writeTestEpub(
        p.join(dir.path, 'novel.epub'),
        metadata: metadata,
        chapters: [
          (path: 'one.xhtml', body: '<h1>Uno</h1><p>caminetti sono belli.</p>'),
        ],
      ).path;

  Future<void> pump(
    WidgetTester tester,
    String path, {
    bool pointer = false,
    ReadingPositions? positions,
    void Function(Annotation annotation)? onAnnotate,
    FakeReadAloudEngine? readAloud,
  }) async {
    tester.view
      ..physicalSize = const Size(500, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dictionaryServiceProvider.overrideWith((ref) async => service),
            dictionaryInstallationProvider.overrideWithValue(installation),
            librarySessionProvider.overrideWithValue(library),
          ],
          child: MaterialApp(
            theme: ThemeData(
              visualDensity: pointer
                  ? VisualDensity.compact
                  : VisualDensity.standard,
            ),
            home: Scaffold(
              body: EpubPane(
                path: path,
                cacheDir: () async => p.join(dir.path, 'cache'),
                positions: positions,
                onAnnotate: onAnnotate,
                readAloud: readAloud,
              ),
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

  /// Selects the book's first word, as a long press does.
  Future<void> selectFirstWord(WidgetTester tester) async {
    await tester.longPressAt(
      tester.getTopLeft(find.textContaining('caminetti')) + const Offset(4, 8),
    );
    await tester.pumpAndSettle();
  }

  /// Lets the real engine answer.
  Future<void> answered(WidgetTester tester) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      if (find.byKey(const Key('lookup-entries')).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
  }

  List<String> labels(WidgetTester tester) => [
    for (final action
        in tester
            .widget<MarkdownReadView>(find.byType(MarkdownReadView))
            .selectionActions!)
      action.label,
  ];

  testWidgets('Look up is the book\'s first action, Read aloud the second, '
      'then what a library adds (#1383)', (tester) async {
    await pump(
      tester,
      book(),
      positions: ReadingPositions(dir.path),
      onAnnotate: (_) {},
      readAloud: FakeReadAloudEngine(),
    );
    expect(labels(tester), [
      AppStrings.lookUpAction,
      AppStrings.readAloudFromHere,
      AppStrings.annotateAction,
      AppStrings.copyPlaceLink,
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with no library there is still Look up, first, and nothing '
      'else', (tester) async {
    await pump(tester, book());
    expect(labels(tester), [AppStrings.lookUpAction]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a word selected is looked up in the book\'s language: a '
      'sheet at half the height on a phone', (tester) async {
    // The library spells English: the book's own language wins.
    await library.setSpellDictionaries(['en_US']);
    await pump(tester, book());
    await selectFirstWord(tester);
    await tester.tap(find.text(AppStrings.lookUpAction));
    await tester.pump();
    await answered(tester);

    expect(find.byKey(const Key('lookup-sheet')), findsOne);
    expect(
      tester.widget<Text>(find.byKey(const Key('lookup-title'))).data,
      'caminetto',
    );
    expect(find.text('Italiano'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Annotate with the definition hands the passage over, the '
      'definition its comment', (tester) async {
    final annotated = <Annotation>[];
    await pump(
      tester,
      book(),
      positions: ReadingPositions(dir.path),
      onAnnotate: annotated.add,
    );
    await selectFirstWord(tester);
    await tester.tap(find.text(AppStrings.lookUpAction));
    await tester.pump();
    await answered(tester);

    await tester.tap(find.byKey(const Key('lookup-annotate')));
    await tester.pumpAndSettle();
    final annotation = annotated.single;
    expect(annotation.path, 'novel.epub');
    expect(annotation.quote, 'caminetti');
    expect((annotation.place as EpubLocation).chars, (start: 0, end: 9));
    expect(annotation.comment, startsWith('caminetto\n\n'));
    expect(annotation.comment, contains('1. A small fireplace.'));
    expect(find.byKey(const Key('lookup-sheet')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    // The place the pane wrote on its way out lands before the folder goes.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  });

  testWidgets('a book in no library can be looked up, not annotated', (
    tester,
  ) async {
    await pump(tester, book(), onAnnotate: (_) {});
    await selectFirstWord(tester);
    await tester.tap(find.text(AppStrings.lookUpAction));
    await tester.pump();
    await answered(tester);

    expect(
      tester.widget<IconButton>(find.byKey(const Key('lookup-copy'))).onPressed,
      isNotNull,
    );
    final annotate = find.byKey(const Key('lookup-annotate'));
    expect(annotate, findsOne);
    expect(tester.widget<IconButton>(annotate).onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Ctrl+D looks the selection up where there is a pointer, in a '
      'panel under it', (tester) async {
    await pump(tester, book(), pointer: true);
    await selectFirstWord(tester);
    final word = tester.getRect(find.textContaining('caminetti')).top;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await answered(tester);

    final popup = find.byKey(const Key('lookup-popup'));
    expect(popup, findsOne);
    expect(tester.getRect(popup).top, greaterThan(word));
    expect(
      tester.widget<Text>(find.byKey(const Key('lookup-title'))).data,
      'caminetto',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(popup, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Ctrl+D with nothing selected does nothing', (tester) async {
    await pump(tester, book(), pointer: true);
    await tester.tap(find.textContaining('caminetti'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lookup-popup')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
