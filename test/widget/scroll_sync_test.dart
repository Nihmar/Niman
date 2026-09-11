// T-M2-06 M-06-3 (AC): scrolling either pane moves the other, verified on
// a long fixture in both directions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/preview/editor_lines.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/preview/scroll_map.dart';
import 'package:niman/src/preview/scroll_sync.dart';
import 'package:re_editor/re_editor.dart';

String _longFixture() {
  final buffer = StringBuffer();
  for (var i = 0; i < 300; i++) {
    buffer.write('Paragraph number $i with enough text to fill a line.\n\n');
  }
  return buffer.toString();
}

/// Paragraphs written as one long source line each, the way prose is
/// actually written: every line wraps over several rows in the editor.
String _wrappedFixture() {
  final buffer = StringBuffer();
  for (var i = 0; i < 120; i++) {
    buffer
      ..write('Paragraph number $i ')
      ..write('with a great deal more text on the very same source line, ')
      ..write('long enough that the editor has to wrap it over several ')
      ..write('rows before the next one starts.\n\n');
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

  // 2026-09-10 device report: on a note of wrapped prose the two panes did
  // not line up. The editor's scroll extent counts every line below the
  // viewport as one unwrapped row, so it grows as the wrapped ones scroll
  // in: the same fraction of it means a later line the further down you
  // are, and the preview ran ahead. The sync reads the editor's top line
  // instead.
  testWidgets('the preview follows the editor line, not its pixel fraction', (
    tester,
  ) async {
    final text = _wrappedFixture();
    final editorController = CodeLineEditingController.fromText(text);
    final focus = FocusNode();
    final editorScroll = CodeScrollController();
    final previewScroll = ScrollController();
    final map = ScrollMap();
    final lines = EditorLineView();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditorPreviewScrollSync(
            editorScroll: editorScroll.verticalScroller,
            previewScroll: previewScroll,
            map: map,
            lines: lines,
            child: Row(
              children: [
                Expanded(
                  child: NoteEditor(
                    controller: editorController,
                    focusNode: focus,
                    scrollController: editorScroll,
                    showLineNumbers: false,
                    onIndicator: lines.attach,
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
    expect(lines.hasLines, isTrue);

    // A third of the way down by pixels — far enough in that the wrapped
    // rows above have made the editor's extent estimate stale.
    editorScroll.verticalScroller.jumpTo(
      editorScroll.verticalScroller.position.maxScrollExtent / 3,
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }

    final top = lines.topLine();
    expect(top, isNotNull);
    // Source line 2n is paragraph n (each is followed by a blank line).
    final paragraph = find.textContaining(
      'Paragraph number ${top! ~/ 2} ',
      findRichText: true,
    );
    expect(
      paragraph,
      findsOneWidget,
      reason: 'the editor is on paragraph ${top ~/ 2}; the preview is not',
    );
    // And it is at the top of the preview, not somewhere down the pane.
    final previewTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    expect(
      tester.getTopLeft(paragraph).dy - previewTop,
      lessThan(80),
      reason: 'the paragraph is on screen but not where the editor is',
    );

    // The other way: the editor only measures the lines it has laid out,
    // so a line further down is reached by estimate and then corrected
    // over the next few layouts.
    final previewPos = previewScroll.position;
    previewScroll.jumpTo(previewPos.maxScrollExtent * 0.6);
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
    final shown = map.lineForPreviewOffset(
      previewPos.pixels,
      maxExtent: previewPos.maxScrollExtent,
    );
    expect(shown, isNotNull);
    expect(
      lines.topLine(),
      closeTo(shown!, 2),
      reason: 'the preview is on line $shown; the editor is not',
    );

    editorController.dispose();
    focus.dispose();
    editorScroll.verticalScroller.dispose();
    editorScroll.horizontalScroller.dispose();
    previewScroll.dispose();
    lines.dispose();
  });
}
