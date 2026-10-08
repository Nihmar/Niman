// Annotating a PDF or a book from its pane (#284): the comment asked over
// the file, the companion written, the reader told and offered the note,
// and nothing written when they cancel. A passage highlighted (#626) in
// the colour last chosen, recoloured and removed.
//
// A link is written in pieces, which run on without spaces.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/ui/shell_annotation_flow.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;
  late UnsavedTracker unsaved;
  var written = 0;
  final opened = <(String, int)>[];

  setUp(() async {
    session = FakeLibrarySession();
    await session.open('/library', create: true);
    unsaved = UnsavedTracker();
    written = 0;
    opened.clear();
  });
  tearDown(() => unsaved.dispose());

  const annotation = Annotation(
    path: 'Books/Dune.pdf',
    place: PdfLocation(page: 34, chars: (start: 5, end: 25)),
    label: 'Dune, p. 34',
    quote: 'The spice must flow.',
  );

  Future<void> start(WidgetTester tester) async {
    final flow = ShellAnnotationFlow(
      controller: session,
      unsaved: unsaved,
      linkType: () => LinkType.wikilink,
      onWritten: () => written++,
      onOpen: (path, offset) => opened.add((path, offset)),
    );
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => flow.annotate(context, annotation),
              child: const Text('annotate'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('annotate'));
    await tester.pumpAndSettle();
  }

  const note = 'Annotations/Dune - Annotation.md';

  testWidgets('the companion is written, and the note offered', (tester) async {
    await start(tester);
    await tester.enterText(
      find.byKey(const Key('annotation-comment')),
      'Remember this.',
    );
    await tester.tap(find.byKey(const Key('annotation-save')));
    await tester.pumpAndSettle();
    final text = session.contentOf(note);
    expect(text, startsWith('---\nannotates: "[[Books/Dune.pdf]]"\n---\n'));
    expect(
      text,
      contains(
        '> — [[Books/Dune.pdf#page=34&chars=5-25|Dune, p. 34]]\n'
        '\nRemember this.\n',
      ),
    );
    expect(written, 1);
    expect(find.text(AppStrings.annotationSaved), findsOneWidget);
    await tester.tap(find.text(AppStrings.annotationOpenNote));
    await tester.pumpAndSettle();
    expect(opened.single.$1, note);
    expect(text!.substring(opened.single.$2), startsWith('## Dune, p. 34'));
  });

  testWidgets('cancelled, nothing is written', (tester) async {
    await start(tester);
    await tester.tap(find.byKey(const Key('annotation-cancel')));
    await tester.pumpAndSettle();
    expect(session.contentOf(note), isNull);
    expect(written, 0);
    expect(find.text(AppStrings.annotationSaved), findsNothing);
  });

  group('highlights (#626)', () {
    ShellAnnotationFlow flow() => ShellAnnotationFlow(
      controller: session,
      unsaved: unsaved,
      linkType: () => LinkType.wikilink,
      onWritten: () => written++,
      onOpen: (path, offset) => opened.add((path, offset)),
    );

    test('a passage is highlighted in the colour last chosen', () async {
      session.highlightColourId = 'blue';
      await flow().highlight(annotation);
      expect(
        session.contentOf(note),
        endsWith(
          '> The spice must flow.\n'
          '> — [[Books/Dune.pdf#page=34&chars=5-25&highlight=blue'
          '|Dune, p. 34]]\n',
        ),
      );
      expect(written, 1);
    });

    test('a colour chosen is the one the next highlight takes', () async {
      // The highlight as its note holds it: the mark `marksOf` gives, read
      // here from the text, the fake keeping no index of frontmatter.
      AnnotationMark highlighted() {
        final link = annotationLinksIn(session.contentOf(note)!).single;
        return AnnotationMark(
          note: note,
          offset: link.offset,
          place: link.place,
          highlight: link.highlight,
          end: link.end,
          quote: link.quote,
          label: link.label,
        );
      }

      final shell = flow();
      await shell.highlight(annotation);
      expect(highlighted().highlight, HighlightColour.yellow);
      await shell.recolour(highlighted(), HighlightColour.pink);
      expect(session.highlightColourId, 'pink');
      expect(highlighted().highlight, HighlightColour.pink);
      await shell.removeHighlight(highlighted());
      expect(session.contentOf(note), isNot(contains('The spice')));
      expect(written, 3);
    });
  });
}
