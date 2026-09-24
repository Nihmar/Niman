// A long note's save hands the index the tags and links the editor keeps
// block by block, so its reindex does not read the note for them.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

void main() {
  setUp(() => MarkdownSourceViewState.backgroundLines = 2);
  tearDown(() => MarkdownSourceViewState.backgroundLines = 50000);

  testWidgets('a long note saves with its references', (tester) async {
    final saves = <(String, NoteReferences?)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/notes/long.md',
            showLineNumbers: false,
            autofocusEditor: false,
            readNote: (_) async => 'One #first line.\n\nA [[Link]] here.\n',
            writeNote: (_, _) async {},
            saveNoteStream:
                (path, content, {required editSession, references}) async {
                  final text = StringBuffer();
                  for (var index = 0; ; index++) {
                    final slice = await content(index);
                    if (slice == null) break;
                    text.write(utf8.decode(slice));
                  }
                  saves.add((text.toString(), references));
                },
          ),
        ),
      ),
    );
    MarkdownSourceViewState view() =>
        tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
    bool ready() =>
        find.byType(MarkdownSourceView).evaluate().isNotEmpty &&
        view().references() != null;
    // The note is read on an isolate, its references with it.
    for (var round = 0; round < 50 && !ready(); round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(view().references(), isNotNull);

    view().replaceText(0, 0, 'Now #added. ');
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(saves, isNotEmpty);
    final (text, references) = saves.last;
    expect(text, startsWith('Now #added. One #first line.'));
    expect(references?.tags, ['added', 'first']);
    expect(references?.links, hasLength(1));
  });
}
