// T-M3-07 AC: preview wikilink tap, markdown link tap (in-app vs external),
// editor desktop Ctrl+click, heading anchors, unresolved links → snackbar.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

import '../fakes/fake_link_source.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view({
  required String content,
  required FakeLinkSource source,
  List<String>? opened,
  CodeLineEditingController? controller,
  String? initialAnchor,
  bool showPreview = false,
}) => NoteView(
  showLineNumbers: true,
  autofocusEditor: false,
  path: '/notes/current.md',
  libraryRoot: '/notes',
  linkSource: source,
  onOpenNote: (path, anchor) => opened?.add('$path|$anchor'),
  initialAnchor: initialAnchor,
  showPreview: showPreview,
  readNote: (_) async => content,
  writeNote: (_, _) async {},
  controller: controller,
);

/// Taps the [RichText] paragraph [paragraph] at the center of the span
/// covering offsets [start]..[end] — the preview merges a whole paragraph
/// into one [RichText], so the tap has to land on the exact span's box.
Future<void> _tapParagraphAt(
  WidgetTester tester,
  String paragraph,
  int start,
  int end,
) async {
  final finder = find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText() == paragraph,
  );
  expect(finder, findsOneWidget);
  final render = tester.renderObject<RenderParagraph>(finder);
  final boxes = render.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  expect(boxes, isNotEmpty);
  final topLeft = render.localToGlobal(Offset.zero);
  final gesture = await tester.startGesture(
    topLeft + boxes.first.toRect().center,
  );
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('preview wikilink tap resolves and opens the note', (
    tester,
  ) async {
    final source = FakeLinkSource(notes: ['Other.md', 'current.md']);
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        _view(
          content: 'See [[Other]] here.\n',
          source: source,
          opened: opened,
          showPreview: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // 'Other' spans offsets 4..9 inside 'See Other here.'.
    await _tapParagraphAt(tester, 'See Other here.', 4, 9);
    expect(source.queries, contains('wiki:Other'));
    expect(opened, ['Other.md|null']);
  });

  testWidgets('a wikilink with an alias opens the target, not the alias', (
    tester,
  ) async {
    final source = FakeLinkSource(notes: ['filename.md', 'current.md']);
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        _view(
          content: 'See [[filename|a label]] here.\n',
          source: source,
          opened: opened,
          showPreview: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // The preview renders the alias ('a label' spans 4..11).
    await _tapParagraphAt(tester, 'See a label here.', 4, 11);
    expect(source.queries, contains('wiki:filename'));
    expect(opened, ['filename.md|null']);
  });

  testWidgets('a label-first wikilink [[display text|file]] opens the file', (
    tester,
  ) async {
    // Notes written with the display text first (the Markdown-link
    // ordering) parse as target='display text': the click falls back to
    // the aliased part when the first part resolves to nothing.
    final source = FakeLinkSource(notes: ['filename.md', 'current.md']);
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        _view(
          content: 'See [[a label|filename]] here.\n',
          source: source,
          opened: opened,
          showPreview: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await _tapParagraphAt(tester, 'See filename here.', 4, 12);
    expect(source.queries, contains('wiki:a label'));
    expect(source.queries, contains('wiki:filename'));
    expect(opened, ['filename.md|null']);
  });

  testWidgets('a label-first link stays unresolved when both parts fail', (
    tester,
  ) async {
    final source = FakeLinkSource(notes: ['current.md']);
    await tester.pumpWidget(
      _app(
        _view(
          content: 'See [[gone|missing]] here.\n',
          source: source,
          showPreview: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await _tapParagraphAt(tester, 'See missing here.', 4, 11);
    expect(find.text('Link not found'), findsOne);
  });

  testWidgets('a local-anchor tap scrolls a long note in preview-only mode', (
    tester,
  ) async {
    // T-M3-09 device report: anchor links tapped in the phone preview
    // never moved — the windowed preview's scroll map is incomplete right
    // after open, and the jump bailed on it. The heading sits far below
    // the initial viewport (its block is not even built yet); the tap
    // must land close enough for the windowed list to build it.
    final source = FakeLinkSource(notes: ['current.md']);
    final buffer = StringBuffer('Go [[#Target Heading|target]] here.\n\n')
      ..writeAll([
        for (var i = 0; i < 240; i++)
          'Filler paragraph $i with some ordinary words.\n\n',
        '## Target Heading\n\n',
        'The section body the jump must reveal.\n',
      ]);
    await tester.pumpWidget(
      _app(
        _view(content: buffer.toString(), source: source, showPreview: true),
      ),
    );
    await tester.pump();
    await tester.pump();
    // Not built yet: the windowed list never laid the heading out.
    expect(find.text('Target Heading', findRichText: true), findsNothing);

    await _tapParagraphAt(tester, 'Go target here.', 3, 9);
    // The jump + its post-frame refinements. The test binding only draws
    // a frame when one is scheduled, so each pass forces one.
    for (var i = 0; i < 14; i++) {
      tester.binding.scheduleFrame();
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Target Heading', findRichText: true), findsOneWidget);
    expect(find.text('Link not found'), findsNothing);
    expect(find.text('Heading not found'), findsNothing);
  });

  testWidgets('a wikilink with an anchor opens the note with the anchor', (
    tester,
  ) async {
    final source = FakeLinkSource(notes: ['Other.md', 'current.md']);
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        _view(
          content: 'Go [[Other#My Heading]] now.\n',
          source: source,
          opened: opened,
          showPreview: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await _tapParagraphAt(tester, 'Go My Heading now.', 3, 13);
    expect(opened, ['Other.md|My Heading']);
  });

  testWidgets('markdown http link is external; #anchor stays local', (
    tester,
  ) async {
    final source = FakeLinkSource(notes: ['current.md']);
    await tester.pumpWidget(
      _app(
        _view(
          content: '[site](https://example.com) and [#here](#My)\n',
          source: source,
          showPreview: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await _tapParagraphAt(tester, 'site and #here', 0, 4);
    expect(source.queries, contains('md:https://example.com'));

    await _tapParagraphAt(tester, 'site and #here', 9, 14);
    expect(source.queries, contains('md:#My'));
  });

  testWidgets('an unresolved link shows the snackbar', (tester) async {
    final source = FakeLinkSource(notes: ['current.md']);
    await tester.pumpWidget(
      _app(
        _view(
          content: 'See [[Missing]] here.\n',
          source: source,
          showPreview: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await _tapParagraphAt(tester, 'See Missing here.', 4, 11);
    expect(find.text('Link not found'), findsOne);
  });

  testWidgets('editor Ctrl+click on a wikilink opens it', (tester) async {
    final source = FakeLinkSource(notes: ['Target.md', 'current.md']);
    final opened = <String>[];
    final controller = CodeLineEditingController.fromText(
      'text [[Target]] more\nline two\n',
    );
    await tester.pumpWidget(
      _app(
        _view(
          content: 'text [[Target]] more\nline two\n',
          source: source,
          opened: opened,
          controller: controller,
        ),
      ),
    );
    await tester.pump();

    // Ctrl is held; a mouse click lands the caret under the pointer (the
    // package's own tap handling), inside the `[[Target]]` token. The
    // Listener reads the caret after the frame.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    // Calibrated against the editor's glyph metrics: at y=12 (line 0),
    // x=150 lands the caret at offset ~6 — inside `[[Target]]` (5..14).
    await gesture.down(const Offset(150, 12));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    // The caret check retries a few frames until the package's tap handler
    // has placed the caret under the pointer.
    await tester.pump();
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(opened, ['Target.md|null']);
    controller.dispose();
    // Let any debounced save timer fire before teardown.
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('initialAnchor lands on the matching heading', (tester) async {
    final source = FakeLinkSource(notes: ['current.md']);
    final controller = CodeLineEditingController.fromText(
      'intro\n## My Heading\nbody\n',
    );
    await tester.pumpWidget(
      _app(
        _view(
          content: 'intro\n## My Heading\nbody\n',
          source: source,
          initialAnchor: 'My Heading',
          controller: controller,
        ),
      ),
    );
    await tester.pump();

    final selection = controller.selection;
    // The caret lands on the heading line (line 1, offset 0).
    expect(selection.extentIndex, 1);
    expect(selection.extentOffset, 0);
    controller.dispose();
  });
}
