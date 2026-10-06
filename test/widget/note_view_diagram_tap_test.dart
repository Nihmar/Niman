// A diagram tapped in the read pane opens the note's source again (#530):
// the owner flips the pane to the editor, and the caret lands in the block —
// on the line a parse error names, when there is one.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

/// A host that owns the preview switch, as the shell does.
final class _Host extends StatefulWidget {
  const new({required this.note});

  final String note;

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  bool preview = true;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: NoteView(
        path: '/tmp/niman-diagram-tap-test.md',
        showLineNumbers: true,
        autofocusEditor: false,
        showPreview: preview,
        onShowSource: () => setState(() => preview = false),
        readNote: (_) async => widget.note,
        writeNote: (_, _) async {},
      ),
    ),
  );
}

/// The offset line [line] of [note] starts at.
int _lineStart(String note, int line) =>
    note.split('\n').take(line).fold(0, (sum, text) => sum + text.length + 1);

Future<MarkdownSourceViewState> _tapAndOpen(
  WidgetTester tester,
  String note,
  Finder target,
) async {
  await tester.pumpWidget(_Host(note: note));
  await tester.pumpAndSettle();
  final host = tester.state<_HostState>(find.byType(_Host));
  expect(host.preview, isTrue);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(host.preview, isFalse, reason: 'the tap asked for the source');
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

void main() {
  testWidgets('a tap on a diagram puts the caret in its block', (tester) async {
    const note = 'Intro\n\n```mermaid\nflowchart TD\nA --> B\n```\n\nEnd\n';
    final editor = await _tapAndOpen(
      tester,
      note,
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is DiagramPainter,
      ),
    );
    expect(editor.selection.caret, _lineStart(note, 3));
  });

  testWidgets("a tap on a parse error puts the caret on the error's line", (
    tester,
  ) async {
    const note = 'Intro\n\n```mermaid\nflowchart TD\nA -- B\n```\n\nEnd\n';
    final editor = await _tapAndOpen(
      tester,
      note,
      find.textContaining('Line 2:'),
    );
    expect(editor.selection.caret, _lineStart(note, 4));
  });
}
