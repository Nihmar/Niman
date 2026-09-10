// T-M2-06 M-06-3 (AC): scrolling either pane moves the other, verified on
// a long fixture in both directions.
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/preview/markdown_preview.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:copist/src/preview/scroll_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

String _longFixture() {
  final buffer = StringBuffer();
  for (var i = 0; i < 300; i++) {
    buffer.write('Paragraph number $i with enough text to fill a line.\n\n');
  }
  return buffer.toString();
}

void main() {
  testWidgets('scrolling the editor moves the preview, and back (both ways)', (
    tester,
  ) async {
    final text = _longFixture();
    final editorController = CodeLineEditingController.fromText(text);
    final focus = FocusNode();
    final editorScroll = CodeScrollController();
    final previewScroll = ScrollController();
    final map = ScrollMap();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorPreviewScrollSync(
            editorScroll: editorScroll.verticalScroller,
            previewScroll: previewScroll,
            map: map,
            child: Row(
              children: [
                Expanded(
                  child: NoteEditor(
                    controller: editorController,
                    focusNode: focus,
                    scrollController: editorScroll,
                    showLineNumbers: false,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: MarkdownPreview(
                    data: text,
                    controller: previewScroll,
                    scrollMap: map,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(editorScroll.verticalScroller.hasClients, isTrue);
    expect(previewScroll.hasClients, isTrue);

    final editorPos = editorScroll.verticalScroller.position;
    final previewPos = previewScroll.position;
    expect(editorPos.maxScrollExtent, greaterThan(0));
    expect(previewPos.maxScrollExtent, greaterThan(0));

    // Editor → preview: jump the editor to ~40% and expect the preview to
    // follow. The mapping is block-quantized (300 blocks), so the tolerance
    // is one block's worth of the preview's extent.
    final editorTarget = editorPos.maxScrollExtent * 0.4;
    editorScroll.verticalScroller.jumpTo(editorTarget);
    await tester.pump();
    await tester.pump();
    expect(
      previewPos.pixels,
      closeTo(
        previewPos.maxScrollExtent * 0.4,
        previewPos.maxScrollExtent / 60,
      ),
    );

    // Preview → editor: jump the preview to ~70% and expect the editor to
    // follow.
    final previewTarget = previewPos.maxScrollExtent * 0.7;
    previewScroll.jumpTo(previewTarget);
    await tester.pump();
    await tester.pump();
    // The mapping anchors the source line at the *top* of the viewport
    // (T-PP-22), so the editor lands half a viewport of lines before the
    // raw 70% fraction would — hence the wider tolerance here.
    expect(
      editorPos.pixels,
      closeTo(editorPos.maxScrollExtent * 0.7, editorPos.maxScrollExtent / 30),
    );

    editorController.dispose();
    focus.dispose();
    editorScroll.verticalScroller.dispose();
    editorScroll.horizontalScroller.dispose();
    previewScroll.dispose();
  });
}
