// T-M4-01: a frontmatter block that does not parse is indexed as if it
// were not there, so the editor says so while the note is open.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view(String content, {CodeLineEditingController? controller}) =>
    NoteView(
      showLineNumbers: true,
      autofocusEditor: false,
      path: '/notes/a.md',
      readNote: (_) async => content,
      writeNote: (_, _) async {},
      controller: controller,
    );

Finder warning() => find.byKey(const Key('frontmatter-error'));

void main() {
  testWidgets('a broken block is called out, with the reason', (tester) async {
    await tester.pumpWidget(_app(_view('---\ntitle: [unclosed\n---\nbody')));
    await tester.pump();

    expect(warning(), findsOneWidget);
    expect(find.textContaining('Frontmatter not read:'), findsOneWidget);
  });

  testWidgets('a good block, an empty one and no block say nothing', (
    tester,
  ) async {
    for (final content in [
      '---\ntitle: Fine\n---\nbody',
      '---\n---\nbody',
      'no frontmatter at all',
      '---\nnever closed, so it is a rule',
    ]) {
      await tester.pumpWidget(_app(_view(content)));
      await tester.pump();
      expect(warning(), findsNothing, reason: 'for: $content');
    }
  });

  testWidgets('fixing the block clears the warning as you type', (
    tester,
  ) async {
    final controller = CodeLineEditingController.fromText(
      '---\ntitle: [unclosed\n---\nbody',
    );
    await tester.pumpWidget(
      _app(_view('---\ntitle: [unclosed\n---\nbody', controller: controller)),
    );
    await tester.pump();
    expect(warning(), findsOneWidget);

    controller.text = '---\ntitle: fixed\n---\nbody';
    // The check rides the stats debounce (350 ms), not the keystroke.
    await tester.pump();
    expect(warning(), findsOneWidget, reason: 'not on the keystroke path');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(warning(), findsNothing);
  });

  testWidgets('breaking a good block raises the warning', (tester) async {
    final controller = CodeLineEditingController.fromText(
      '---\ntitle: Fine\n---\nbody',
    );
    await tester.pumpWidget(
      _app(_view('---\ntitle: Fine\n---\nbody', controller: controller)),
    );
    await tester.pump();
    expect(warning(), findsNothing);

    controller.text = '---\ntitle: Fine\nsame: 1\nsame: 2\n---\nbody';
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(warning(), findsOneWidget);
  });
}
