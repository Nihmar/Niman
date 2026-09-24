// The find bar over the unified source pane (#245, phase 3), in the note as
// the app shows it: the legacy editor's keys open it, the matches are painted
// in the note, and closing it gives the note the keyboard back.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

/// The runs painted with a background other than the selection's: the
/// matches.
List<String> _painted(WidgetTester tester) => <String>[
  for (final text in tester.widgetList<RichText>(
    find.descendant(
      of: find.byType(MarkdownSourceView),
      matching: find.byType(RichText),
    ),
  ))
    ..._withBackground(text.text),
];

Iterable<String> _withBackground(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  final color = span.style?.background?.color;
  if (color != null && color.toARGB32() != 0x553B82F6 && span.text != null) {
    yield span.text!;
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _withBackground(child);
  }
}

Future<MarkdownSourceViewState> _open(
  WidgetTester tester,
  String note, {
  void Function(String text)? onSave,
  bool live = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/n/find.md',
          showLineNumbers: false,
          autofocusEditor: true,
          // The same tests in both unified modes: `source` is the pane as
          // written, `live` the pane with the markers hidden and the caret's
          // own shown. The shell around them does not change.
          showWysiwyg: live,
          readNote: (_) async => note,
          writeNote: (_, text) async => onSave?.call(text),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

void main() {
  // Both unified modes (#246): the find bar is the shell's, over a surface that
  // is one widget in `source` and in `live`, and the criterion is that it
  // behaves identically in both — so the bar's own tests run in both rather
  // than being described twice.
  void both(
    String name,
    Future<void> Function(WidgetTester tester, _Mode mode) body,
  ) {
    for (final mode in _Mode.values) {
      testWidgets('$name (${mode.name})', (tester) => body(tester, mode));
    }
  }

  both('Ctrl+F opens the bar, and the matches are painted', (
    tester,
    mode,
  ) async {
    final state = await _open(
      tester,
      'uno gatto\ndue gatto\ntre\n',
      live: mode == _Mode.live,
    );
    state.focusNode.requestFocus();
    await tester.pump();
    await _ctrl(tester, LogicalKeyboardKey.keyF);
    final input = find.byKey(const Key('source-find-input'));
    expect(input, findsOneWidget);

    await tester.enterText(input, 'gatto');
    await tester.pump();
    expect(find.text('1/2'), findsOneWidget);
    expect(_painted(tester), <String>['gatto', 'gatto']);
    expect(state.selectedText, 'gatto');
    expect(state.selection.start, 4);

    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);
    expect(state.selection.start, 14);
    // The page keys walk them too, from the bar.
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pump();
    expect(find.text('1/2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(input, findsNothing);
    expect(_painted(tester), isEmpty);
    expect(state.focusNode.hasFocus, isTrue, reason: 'the note has it back');
  });

  both('Ctrl+H replaces them all, and the note is saved', (tester, mode) async {
    String? saved;
    final state = await _open(
      tester,
      'uno gatto\ndue gatto\n',
      onSave: (text) => saved = text,
      live: mode == _Mode.live,
    );
    state.focusNode.requestFocus();
    await tester.pump();
    await _ctrl(tester, LogicalKeyboardKey.keyH);
    await tester.enterText(find.byKey(const Key('source-find-input')), 'gatto');
    // Tab goes from the query to the replacement, and back, and never out.
    EditableText field(String key) => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(field('source-replace-input').focusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(field('source-find-input').focusNode.hasFocus, isTrue);
    expect(state.widget.buffer.text, 'uno gatto\ndue gatto\n');
    await tester.enterText(
      find.byKey(const Key('source-replace-input')),
      'cane',
    );
    await tester.tap(find.byKey(const Key('source-replace-all')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(state.widget.buffer.text, 'uno cane\ndue cane\n');
    expect(saved, 'uno cane\ndue cane\n');
    expect(find.text('0'), findsOneWidget, reason: 'nothing left to find');
  });

  both('Escape in the note with the bar closed is not taken', (
    tester,
    mode,
  ) async {
    final state = await _open(tester, 'testo\n', live: mode == _Mode.live);
    state.focusNode.requestFocus();
    await tester.pump();
    final result = await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(result, isFalse, reason: 'the shell gets to answer it');
  });
}
