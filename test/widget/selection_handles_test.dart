import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/editor/virtualized_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _text = 'hello world';

/// Selects the word 'hello' (offsets 0-5) the way the on-device round
/// drives selections: a long press on row 0.
Future<void> _longPressFirstWord(WidgetTester tester) async {
  // x 14 = the left padding (12) + 2 px, i.e. column 0 of row 0.
  await tester.longPressAt(const Offset(14, 10));
  await tester.pump();
  // The show is deferred to a post-frame, and the overlay entries build
  // on the frame after that.
  await tester.pump();
  await tester.pump();
}

Widget _harness(ComposingInput input, FocusNode focus) {
  return MaterialApp(
    home: Scaffold(
      body: NoteEditor(
        initialText: _text,
        input: input,
        focusNode: focus,
        onTextChanged: (_) {},
      ),
    ),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late String? clipboardText;

  setUp(() {
    clipboardText = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboardText = (call.arguments as Map)['text'] as String?;
            return null;
          case 'Clipboard.getData':
            return clipboardText == null
                ? null
                : <String, dynamic>{'text': clipboardText};
          case 'Clipboard.hasStrings':
            return <String, dynamic>{
              'value':
                  clipboardText != null && clipboardText!.isNotEmpty,
            };
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('a long-press selection shows the standard toolbar',
      (tester) async {
    final input = ComposingInput(_text);
    final focus = FocusNode();
    await tester.pumpWidget(_harness(input, focus));
    focus.requestFocus();
    await tester.pump();

    await _longPressFirstWord(tester);

    expect(input.selectionText, 'hello');
    // The framework's own toolbar (the one text fields use) is up, with
    // its standard items.
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Select all'), findsOneWidget);
    focus.dispose();
  });

  testWidgets('copy from the toolbar writes the clipboard and hides',
      (tester) async {
    final input = ComposingInput(_text);
    final focus = FocusNode();
    await tester.pumpWidget(_harness(input, focus));
    focus.requestFocus();
    await tester.pump();
    await _longPressFirstWord(tester);

    await tester.tap(find.text('Copy'));
    await tester.pump();
    await tester.pump();

    expect(clipboardText, 'hello');
    // The selection persists (a copy does not edit the buffer)…
    expect(input.selectionText, 'hello');
    // …and the toolbar hid (the toolbar-cause contract).
    expect(find.text('Copy'), findsNothing);
    focus.dispose();
  });

  testWidgets('select all from the toolbar commits to the IME',
      (tester) async {
    final input = ComposingInput(_text);
    final focus = FocusNode();
    await tester.pumpWidget(_harness(input, focus));
    focus.requestFocus();
    await tester.pump();
    await _longPressFirstWord(tester);

    await tester.tap(find.text('Select all'));
    await tester.pump();

    expect(
      input.selection,
      // _text.length is 11.
      const TextSelection(baseOffset: 0, extentOffset: 11),
    );
    expect(tester.testTextInput.editingState?['selectionBase'], 0);
    expect(
      tester.testTextInput.editingState?['selectionExtent'],
      _text.length,
    );
    focus.dispose();
  });

  testWidgets('paste from the toolbar inserts the clipboard text',
      (tester) async {
    final input = ComposingInput(_text);
    final focus = FocusNode();
    // A pasteable clipboard before the first frame (the toolbar's paste
    // button follows the clipboard status).
    clipboardText = 'XY';
    await tester.pumpWidget(_harness(input, focus));
    focus.requestFocus();
    await tester.pump();
    await _longPressFirstWord(tester);

    await tester.tap(find.text('Paste'));
    await tester.pump();
    await tester.pump();

    expect(input.text, 'XY world');
    expect(tester.testTextInput.editingState?['text'], 'XY world');
    // Paste replaces the selection (the buffer is no longer 'hello…').
    expect(input.selectionText, isNot('hello'));
    focus.dispose();
  });

  testWidgets(
      'dragging the start handle moves the selection; the drag end commits',
      (tester) async {
    final input = ComposingInput(_text);
    final focus = FocusNode();
    await tester.pumpWidget(_harness(input, focus));
    focus.requestFocus();
    await tester.pump();
    await _longPressFirstWord(tester);
    expect(input.selectionText, 'hello');

    // The start endpoint is the viewport-local (leftPadding, 0); the
    // Material handle's interactive center is the endpoint + (-11, 11)
    // (a 22 px handle expanded to a 48 px hit area, anchored on its right
    // edge).
    final viewportTopLeft = tester.getTopLeft(find.byType(VirtualizedTextView));
    final charWidth = VirtualizedTextView.measureCharWidth();
    final startCenter = viewportTopLeft +
        const Offset(VirtualizedTextView.leftPadding - 11, 11);
    // The pointer's end x must land in column 2: local x in
    // [leftPadding + 2·charWidth, leftPadding + 3·charWidth).
    final dx = 2 * charWidth + VirtualizedTextView.leftPadding;

    await tester.dragFrom(startCenter, Offset(dx, 0));
    await tester.pump();
    await tester.pump();

    expect(input.selectionText, 'llo');
    // The drag end committed the selection to the IME (the lockstep the
    // next keystroke edits against).
    expect(tester.testTextInput.editingState?['selectionBase'], 2);
    expect(tester.testTextInput.editingState?['selectionExtent'], 5);
    focus.dispose();
  });
}
