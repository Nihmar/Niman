// T-WYS-04: the WYSIWYG surface opens a note, edits it and reports Markdown.
import 'package:copist/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('opens a note without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            data: '# Heading\n\nA paragraph.\n',
            onChanged: (value) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(quill.QuillEditor), findsOneWidget);
  });

  testWidgets('reports an edit as Markdown after the pause', (tester) async {
    String? reported;
    final key = GlobalKey<WysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            key: key,
            data: '# Heading\n\nA paragraph.\n',
            onChanged: (value) => reported = value,
          ),
        ),
      ),
    );
    await tester.pump();
    key.currentState!.controller.document.insert(0, 'Edited ');
    await tester.pump(const Duration(milliseconds: 600));
    expect(reported, isNotNull);
    expect(reported, contains('Edited'));
  });
}
