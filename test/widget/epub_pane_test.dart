// An EPUB picked in the tree is read in the note pane (#280): drawn by the
// note's read view in the books' own look, its contents a sheet from the
// row below that jumps to the chapter picked.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:niman/src/ui/file_marks.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('niman_epub_pane_'));
  tearDown(() {
    dir.deleteSync(recursive: true);
    EpubLooks.reset();
  });

  Widget pane(
    String path, {
    VoidCallback? onEditLook,
    ReadingPositions? positions,
    String? anchor,
    int reloadToken = 0,
    void Function(Annotation annotation)? onAnnotate,
    AnnotationMarkSource? marks,
  }) => MaterialApp(
    home: Scaffold(
      body: EpubPane(
        path: path,
        cacheDir: () async => p.join(dir.path, 'cache'),
        onEditLook: onEditLook,
        positions: positions,
        anchor: anchor,
        reloadToken: reloadToken,
        onAnnotate: onAnnotate,
        marks: marks,
      ),
    ),
  );

  Future<void> pump(
    WidgetTester tester,
    String path, {
    VoidCallback? onEditLook,
    ReadingPositions? positions,
    String? anchor,
    void Function(Annotation annotation)? onAnnotate,
    AnnotationMarkSource? marks,
  }) async {
    // Real time: the book is read on an isolate, which fake time never
    // lets finish.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        pane(
          path,
          onEditLook: onEditLook,
          positions: positions,
          anchor: anchor,
          onAnnotate: onAnnotate,
          marks: marks,
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

  group('the place a link names (#282)', () {
    late String path;
    late EpubChapter two;
    setUp(() {
      path = twoChapters();
      two = readEpub(path, p.join(dir.path, 'probe')).chapters[1];
    });

    String at(int line) =>
        EpubLocation(chapter: two.file, line: line).toFragment();

    int? top(WidgetTester tester) => tester
        .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
        .topAnchor
        ?.line;

    testWidgets('opens the book there, over where it was left', (tester) async {
      final positions = ReadingPositions(dir.path);
      await tester.runAsync(
        () => positions.write(
          'novel.epub',
          EpubLocation(chapter: two.file, line: 60),
        ),
      );
      await pump(tester, path, positions: positions, anchor: at(20));
      expect(top(tester), two.line + 20);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a chapter the book lacks opens it where it was left', (
      tester,
    ) async {
      final positions = ReadingPositions(dir.path);
      await tester.runAsync(
        () => positions.write(
          'novel.epub',
          EpubLocation(chapter: two.file, line: 60),
        ),
      );
      await pump(
        tester,
        path,
        positions: positions,
        anchor: 'chapter=gone.xhtml&line=3',
      );
      expect(top(tester), two.line + 60);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('its row copies a link to the place being read', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        anchor: at(20),
      );
      await tester.tap(find.byKey(const Key('place-link-button')));
      await tester.pump();
      // Labelled with the contents entry being read: this book's has
      // none for its second chapter.
      expect(copied, '[[novel.epub#${at(20)}|novel, One]]');
      expect(find.text(AppStrings.placeLinkCopied), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a book outside a library has no place to link to', (
      tester,
    ) async {
      await pump(tester, path);
      final button = tester.widget<IconButton>(
        find.byKey(const Key('place-link-button')),
      );
      expect(button.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a new link moves the open book; the same one, handed '
        'again, does not', (tester) async {
      await pump(tester, path, anchor: at(20));
      expect(top(tester), two.line + 20);
      tester
          .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
          .jumpToLine(100);
      await tester.pumpAndSettle();
      final read = top(tester);
      // A tab coming back hands the same link again.
      await tester.pumpWidget(pane(path, anchor: at(20)));
      await tester.pumpAndSettle();
      expect(top(tester), read);
      // The same link followed again.
      await tester.pumpWidget(pane(path, anchor: at(20), reloadToken: 1));
      await tester.pumpAndSettle();
      expect(top(tester), two.line + 20);
      await tester.pumpWidget(pane(path, anchor: at(40), reloadToken: 1));
      await tester.pumpAndSettle();
      expect(top(tester), two.line + 40);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('annotating a paragraph (#284)', () {
    late String path;
    setUp(() => path = twoChapters());

    testWidgets('a word selected offers its annotation and link (#283)', (
      tester,
    ) async {
      final annotated = <Annotation>[];
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        onAnnotate: annotated.add,
      );
      // A long press selects the word under it: "It", at the text's start.
      await tester.longPressAt(
        tester.getTopLeft(find.text('It begins.')) + const Offset(4, 8),
      );
      await tester.pumpAndSettle();
      // The link to it, folded away on a phone.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.copyPlaceLink), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.annotateAction));
      await tester.pumpAndSettle();
      final annotation = annotated.single;
      expect(annotation.path, 'novel.epub');
      expect(annotation.quote, 'It');
      expect(annotation.label, 'novel, One');
      final place = annotation.place as EpubLocation;
      expect(place.chapter, endsWith('one.xhtml'));
      expect(place.line, 2);
      expect(place.chars, (start: 0, end: 2));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("the row's button annotates the paragraph being read", (
      tester,
    ) async {
      final annotated = <Annotation>[];
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        onAnnotate: annotated.add,
      );
      tester
          .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
          .jumpToLine(100);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('annotate-button')));
      expect(annotated.single.quote, 'A long paragraph of the book.');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("the row's button annotates the passage selected", (
      tester,
    ) async {
      final annotated = <Annotation>[];
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        onAnnotate: annotated.add,
      );
      await tester.longPressAt(
        tester.getTopLeft(find.text('It begins.')) + const Offset(4, 8),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('annotate-button')));
      await tester.pumpAndSettle();
      expect(annotated.single.quote, 'It');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a book outside a library offers neither', (tester) async {
      final annotated = <Annotation>[];
      await pump(tester, path, onAnnotate: annotated.add);
      await tester.longPressAt(
        tester.getTopLeft(find.text('It begins.')) + const Offset(4, 8),
      );
      await tester.pumpAndSettle();
      // Its text is still selectable, to copy.
      expect(find.text(AppStrings.annotateAction), findsNothing);
      final button = tester.widget<IconButton>(
        find.byKey(const Key('annotate-button')),
      );
      expect(button.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('where the book was annotated (#285)', () {
    late String path;
    late EpubChapter one;
    late _FakeMarks marks;
    setUp(() {
      path = twoChapters();
      one = readEpub(path, p.join(dir.path, 'probe')).chapters.first;
      marks = _FakeMarks();
    });
    tearDown(() => marks.dispose());

    AnnotationMark on(int line, [String note = 'Novel - Annotation.md']) =>
        AnnotationMark(
          note: note,
          offset: 40,
          place: EpubLocation(chapter: one.file, line: line),
          title: 'novel, One',
        );

    // "It begins." is line 2 of the first chapter.
    Finder marked(int line) =>
        find.byKey(ValueKey('marked-block-${one.line + line}'));

    testWidgets('an annotated paragraph is marked, and opens its note', (
      tester,
    ) async {
      marks.marks = [on(2)];
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        marks: marks,
      );
      expect(marked(2), findsOneWidget);
      expect(marked(0), findsNothing);
      await tester.tap(find.text('It begins.'));
      await tester.pumpAndSettle();
      expect(marks.opened, [on(2)]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('an annotated passage is marked, not its paragraph (#283)', (
      tester,
    ) async {
      marks.marks = [
        AnnotationMark(
          note: 'Novel - Annotation.md',
          offset: 40,
          place: EpubLocation(
            chapter: one.file,
            line: 2,
            chars: (start: 3, end: 9),
          ),
        ),
      ];
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        marks: marks,
      );
      final block = marked(2);
      expect(block, findsOneWidget);
      final highlight = tester.widget<RangeHighlight>(
        find.descendant(of: block, matching: find.byType(RangeHighlight)),
      );
      expect(highlight.ranges, [(start: 3, end: 9)]);
      expect(
        find.descendant(of: block, matching: find.byType(DecoratedBox)),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('two annotations of a paragraph ask which', (tester) async {
      marks.marks = [on(2), on(2, 'Other.md')];
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        marks: marks,
      );
      await tester.tap(find.text('It begins.'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('annotation-marks')), findsOneWidget);
      await tester.tap(find.byKey(const Key('annotation-mark-1')));
      await tester.pumpAndSettle();
      expect(marks.opened.single.note, 'Other.md');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a note changing marks the book again', (tester) async {
      await pump(
        tester,
        path,
        positions: ReadingPositions(dir.path),
        marks: marks,
      );
      expect(marked(2), findsNothing);
      marks
        ..marks = [on(2)]
        ..changed();
      // The pane follows the marks from where it opened the book: in real
      // time.
      await tester.runAsync(
        () => Future<void>.delayed(
          FileMarks.settleDelay + const Duration(milliseconds: 100),
        ),
      );
      await tester.pump();
      expect(marked(2), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
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

/// Marks set by the test, a change fired by it, the marks opened recorded.
final class _FakeMarks implements AnnotationMarkSource {
  List<AnnotationMark> marks = const [];
  final List<AnnotationMark> opened = [];
  final StreamController<Object?> _changes = StreamController.broadcast();

  void changed() => _changes.add(null);

  void dispose() => unawaited(_changes.close());

  @override
  Future<List<AnnotationMark>> marksOf(String path) async => marks;

  @override
  Stream<Object?> get changes => _changes.stream;

  @override
  void open(AnnotationMark mark) => opened.add(mark);
}
