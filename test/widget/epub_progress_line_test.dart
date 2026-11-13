// A book's progress line (#1275): the chapter's percentage, the book's and
// the time left, a tap moving to the next view and keeping it; over the
// book's row on a narrow pane, in it on a wide one.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/epub/epub_progress.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:niman/src/ui/epub_progress_line.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

void main() {
  late Directory dir;
  late List<EpubProgressView> kept;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_epub_progress_');
    kept = [];
  });
  tearDown(() {
    dir.deleteSync(recursive: true);
    EpubLooks.reset();
  });

  String twoChapters() => writeTestEpub(
    p.join(dir.path, 'novel.epub'),
    chapters: [
      (path: 'one.xhtml', body: '<h1>Chapter one</h1><p>It begins.</p>'),
      (
        path: 'two.xhtml',
        body:
            '<h1>Chapter two</h1>'
            '${List.filled(80, '<p>A long paragraph of the book.</p>').join()}'
            '<p id="end">The end.</p>',
      ),
    ],
    nav:
        '<ol><li><a href="one.xhtml">One</a></li>'
        '<li><a href="two.xhtml#end">The end</a></li></ol>',
  ).path;

  Future<void> pump(WidgetTester tester, String path) async {
    // Real time: the book is read on an isolate, which fake time never
    // lets finish.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpubPane(
              path: path,
              cacheDir: () async => p.join(dir.path, 'cache'),
              onProgressView: kept.add,
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

  Finder line() => find.byKey(const Key('epub-progress'));

  /// What the line says now.
  String said(WidgetTester tester) => tester
      .widget<Text>(find.descendant(of: line(), matching: find.byType(Text)))
      .data!;

  testWidgets('the line opens on the chapter, at its start', (tester) async {
    await pump(tester, twoChapters());
    expect(line(), findsOneWidget);
    expect(said(tester), 'One · 0%');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a tap moves to the next view, shown at once and kept', (
    tester,
  ) async {
    await pump(tester, twoChapters());
    await tester.tap(line());
    await tester.pumpAndSettle();
    expect(said(tester), startsWith('0% of the book · chapter 1 of 2'));
    expect(kept, [EpubProgressView.book]);
    expect(EpubLooks.look.progress, EpubProgressView.book);
    await tester.tap(line());
    await tester.pumpAndSettle();
    expect(said(tester), startsWith('Chapter ≈ 1 min · Book ≈ 2 min'));
    await tester.tap(line());
    await tester.pumpAndSettle();
    expect(said(tester), 'One · 0%');
    expect(kept, [
      EpubProgressView.book,
      EpubProgressView.time,
      EpubProgressView.chapter,
    ]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a book opens on the view last kept', (tester) async {
    EpubLooks.apply(const EpubLook(progress: EpubProgressView.book));
    await pump(tester, twoChapters());
    expect(said(tester), startsWith('0% of the book'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a jump moves it at once', (tester) async {
    await pump(tester, twoChapters());
    final state = tester.state<EpubPaneState>(find.byType(EpubPane));
    tester
        .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
        .jumpToLine(state.document!.contents.last.line);
    await tester.pumpAndSettle();
    expect(said(tester), startsWith('The end · '));
    expect(said(tester), isNot('The end · 0%'));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('one button, saying what it shows and what a tap shows next', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, twoChapters());
    expect(
      tester.getSemantics(line()),
      isSemantics(
        label: 'One · 0%',
        hint: 'Show progress in the book',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  group('its place', () {
    Future<void> sized(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, twoChapters());
    }

    testWidgets("over the book's row on a narrow pane", (tester) async {
      await sized(tester, const Size(400, 800));
      final rect = tester.getRect(line());
      expect(rect.height, EpubProgressLine.height);
      expect(rect.width, 400);
      expect(
        rect.bottom,
        lessThanOrEqualTo(tester.getRect(find.text('novel.epub')).top),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("in the book's row, beside its name, on a wide one", (
      tester,
    ) async {
      await sized(tester, const Size(1000, 700));
      final rect = tester.getRect(line());
      final name = tester.getRect(find.text('novel.epub'));
      expect(rect.left, greaterThan(name.right - 1));
      expect((rect.center.dy - name.center.dy).abs(), lessThan(4));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
