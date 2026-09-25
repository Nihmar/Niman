// An EPUB picked in the tree is read in the note pane (#280): drawn by the
// note's read view in the books' own look, its contents a sheet from the
// row below that jumps to the chapter picked.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('niman_epub_pane_'));
  tearDown(() {
    dir.deleteSync(recursive: true);
    EpubLooks.reset();
  });

  Future<void> pump(
    WidgetTester tester,
    String path, {
    VoidCallback? onEditLook,
    ReadingPositions? positions,
  }) async {
    // Real time: the book is read on an isolate, which fake time never
    // lets finish.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpubPane(
              path: path,
              cacheDir: () async => p.join(dir.path, 'cache'),
              onEditLook: onEditLook,
              positions: positions,
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

  testWidgets('the attachment view hands a book to the pane', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentView(path: p.join(dir.path, 'missing.epub')),
        ),
      ),
    );
    expect(find.byType(EpubPane), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a book is read like a note, its name on the row below', (
    tester,
  ) async {
    await pump(tester, twoChapters());
    expect(find.byType(MarkdownReadView), findsOneWidget);
    expect(find.text('Chapter one'), findsOneWidget);
    expect(find.text('It begins.'), findsOneWidget);
    expect(find.text('novel.epub'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the contents sheet jumps to the entry picked', (tester) async {
    await pump(tester, twoChapters());
    await tester.tap(find.byKey(const Key('epub-contents-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('epub-contents')), findsOneWidget);
    // The chapter being read is the one marked.
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('epub-contents-0')))
          .selected,
      isTrue,
    );
    expect(find.text('The end.'), findsNothing);
    await tester.tap(find.byKey(const Key('epub-contents-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('epub-contents')), findsNothing);
    expect(find.text('The end.'), findsOneWidget);
    expect(find.text('Chapter one'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a book with no contents keeps the button, disabled', (
    tester,
  ) async {
    final path = writeTestEpub(
      p.join(dir.path, 'plain.epub'),
      chapters: [(path: 'a.xhtml', body: '<p>Only words.</p>')],
    ).path;
    await pump(tester, path);
    expect(find.text('Only words.'), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.byKey(const Key('epub-contents-button')),
    );
    expect(button.onPressed, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("the book wears the books' look, and follows it", (tester) async {
    EpubLooks.apply(
      const EpubLook(
        brightness: AppBrightness.night,
        font: EpubFont.mono,
        textScale: 1.5,
      ),
    );
    await pump(tester, twoChapters());
    BuildContext book() => tester.element(find.byType(MarkdownReadView));
    expect(Theme.of(book()).brightness, Brightness.dark);
    expect(Theme.of(book()).textTheme.bodyMedium?.fontFamily, 'monospace');
    expect(MediaQuery.textScalerOf(book()).scale(10), closeTo(15, 0.001));

    EpubLooks.apply(const EpubLook(brightness: AppBrightness.day));
    await tester.pump();
    expect(Theme.of(book()).brightness, Brightness.light);
    expect(Theme.of(book()).textTheme.bodyMedium?.fontFamily, 'Literata');
    expect(MediaQuery.textScalerOf(book()).scale(10), closeTo(10, 0.001));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('its Aa button opens the look', (tester) async {
    var opened = 0;
    await pump(tester, twoChapters(), onEditLook: () => opened++);
    await tester.tap(find.byKey(const Key('epub-look-button')));
    expect(opened, 1);
    await tester.pumpWidget(const SizedBox());
  });

  group('where the book was left (#281)', () {
    late ReadingPositions positions;
    setUp(() => positions = ReadingPositions(dir.path));

    /// The file the positions are kept in.
    File kept() => File(p.join(dir.path, ReadingPositions.filePath));

    /// Lets a write the pane started reach the disk: it runs in the
    /// test's fake time, its file operations in real time.
    Future<BookLocation?> settled(WidgetTester tester) async {
      for (var i = 0; i < 50; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
        if (kept().existsSync()) break;
      }
      return await tester.runAsync<BookLocation?>(
        () => positions.read('novel.epub'),
      );
    }

    testWidgets('a book opens where it was left', (tester) async {
      final path = twoChapters();
      final two = readEpub(path, p.join(dir.path, 'probe')).chapters[1];
      await tester.runAsync(
        () => positions.write(
          'novel.epub',
          EpubLocation(chapter: two.file, line: 60),
        ),
      );
      await pump(tester, path, positions: positions);
      final view = tester.state<MarkdownReadViewState>(
        find.byType(MarkdownReadView),
      );
      expect(view.topAnchor?.line, two.line + 60);
      expect(find.text('Chapter one'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a place in a chapter the book lost opens it at its start', (
      tester,
    ) async {
      await tester.runAsync(
        () => positions.write(
          'novel.epub',
          const EpubLocation(chapter: 'OEBPS/gone.xhtml', line: 40),
        ),
      );
      await pump(tester, twoChapters(), positions: positions);
      expect(find.text('Chapter one'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the place is written down once the reader rests', (
      tester,
    ) async {
      final path = twoChapters();
      await pump(tester, path, positions: positions);
      tester
          .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
          .jumpToLine(100);
      await tester.pump();
      expect(kept().existsSync(), isFalse);
      await tester.pump(const Duration(seconds: 2));
      final left = await settled(tester);
      final document = readEpub(path, p.join(dir.path, 'probe'));
      // The view lands on the paragraph's top, give or take a rounding
      // that reads as the very end of the blank line above it.
      expect(
        left is EpubLocation ? document.lineOfLocation(left) : left,
        inInclusiveRange(99, 100),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a book opened and not moved writes nothing', (tester) async {
      await tester.runAsync(
        () => positions.write(
          'novel.epub',
          const EpubLocation(chapter: 'OEBPS/two.xhtml', line: 30),
          at: DateTime.utc(2026),
        ),
      );
      await pump(tester, twoChapters(), positions: positions);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
      await settled(tester);
      expect(kept().readAsStringSync(), contains('2026-01-01T00:00:00.000Z'));
    });

    testWidgets('a pane closed before the rest writes the place anyway', (
      tester,
    ) async {
      await pump(tester, twoChapters(), positions: positions);
      tester
          .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
          .jumpToLine(100);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(await settled(tester), isA<EpubLocation>());
    });
  });

  testWidgets('a file that is not a book says so', (tester) async {
    final file = File(p.join(dir.path, 'broken.epub'))
      ..writeAsStringSync('not a zip');
    await pump(tester, file.path);
    expect(find.byKey(const Key('attachment-unreadable')), findsOneWidget);
    expect(find.byType(MarkdownReadView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
