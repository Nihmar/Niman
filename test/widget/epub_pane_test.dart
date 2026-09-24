// An EPUB picked in the tree is read in the note pane (#280): drawn by the
// note's read view, its contents a sheet from the row below that jumps to
// the chapter picked.
//
// XHTML is written in pieces, and a space between two would be a word
// of the book: its literals run on without one.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('niman_epub_pane_'));
  tearDown(() => dir.deleteSync(recursive: true));

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

  testWidgets('a file that is not a book says so', (tester) async {
    final file = File(p.join(dir.path, 'broken.epub'))
      ..writeAsStringSync('not a zip');
    await pump(tester, file.path);
    expect(find.byKey(const Key('attachment-unreadable')), findsOneWidget);
    expect(find.byType(MarkdownReadView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
