// Annotating a PDF or a book from its pane (#284): the comment asked over
// the file, the companion written, the reader told and offered the note,
// and nothing written when they cancel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/core/settings/library_settings.dart';
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
}
