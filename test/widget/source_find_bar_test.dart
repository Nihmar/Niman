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
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/n/find.md',
          showLineNumbers: false,
          autofocusEditor: true,
          unifiedMarkdown: true,
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

void main() {
  testWidgets('Ctrl+F opens the bar, and the matches are painted', (
    tester,
  ) async {
    final state = await _open(tester, 'uno gatto\ndue gatto\ntre\n');
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

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(input, findsNothing);
    expect(_painted(tester), isEmpty);
    expect(state.focusNode.hasFocus, isTrue, reason: 'the note has it back');
  });

  testWidgets('Ctrl+H replaces them all, and the note is saved', (
    tester,
  ) async {
    String? saved;
    final state = await _open(
      tester,
      'uno gatto\ndue gatto\n',
      onSave: (text) => saved = text,
    );
    state.focusNode.requestFocus();
    await tester.pump();
    await _ctrl(tester, LogicalKeyboardKey.keyH);
    await tester.enterText(find.byKey(const Key('source-find-input')), 'gatto');
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

  testWidgets('Escape in the note with the bar closed is not taken', (
    tester,
  ) async {
    final state = await _open(tester, 'testo\n');
    state.focusNode.requestFocus();
    await tester.pump();
    final result = await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(result, isFalse, reason: 'the shell gets to answer it');
  });
}
