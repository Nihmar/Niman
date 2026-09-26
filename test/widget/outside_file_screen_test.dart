// Issue #77: a Markdown file open on its own. It gets the editor and
// nothing a library adds: its frontmatter is text, there is no image
// button to copy into a library, and edits go back to the file itself.
// Several are tabs; closing the last, or going back, lands where the
// user came from. A change made on disk comes in while the editor has
// nothing of its own unsaved.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/outside_files.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_window_controller.dart';

/// A file that is not on disk: its text in memory, its changes on cue.
final class _FakeDocument extends EditorOnlyDocument {
  new(super.filePath, this.text);

  String text;
  final List<String> writes = [];
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Future<String> read() async => text;

  @override
  Future<void> write(String content) async {
    writes.add(content);
    text = content;
  }

  @override
  bool get exists => true;

  @override
  Stream<void> changes() => _changes.stream;

  /// Something else wrote [content] to it.
  void changeOnDisk(String content) {
    text = content;
    _changes.add(null);
  }
}

void main() {
  late OutsideFiles files;

  setUp(() => files = OutsideFiles());

  Future<void> pump(
    WidgetTester tester,
    EditorOnlyDocument first, {
    bool customTitleBar = false,
    bool unifiedMarkdown = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: customTitleBar),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('open'),
                  onPressed: () =>
                      unawaited(openOutsideFile(context, files, first)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  MarkdownSourceViewState surface(WidgetTester tester) =>
      tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

  String editorText(WidgetTester tester) => surface(tester).widget.buffer.text;

  testWidgets('it opens with its name and where it is, frontmatter as text '
      'and no image button', (tester) async {
    final readme = _FakeDocument(
      '/home/u/project/README.md',
      '---\ntype: list\n---\n# Project',
    );
    await pump(tester, readme);
    expect(find.text('README.md'), findsOne);
    expect(
      find.descendant(
        of: find.byKey(const Key('outside-file-where')),
        matching: find.textContaining('/home/u/project', findRichText: true),
      ),
      findsOne,
    );
    // A `type` in its frontmatter draws no list: it is not a note.
    expect(find.byType(MarkdownSourceView), findsOne);
    expect(editorText(tester), contains('type: list'));
    expect(find.byKey(const Key('insert-image')), findsNothing);
  });

  testWidgets('find and replace open from the keyboard with the focus '
      'anywhere', (tester) async {
    await pump(tester, _FakeDocument('/tmp/draft.md', 'alpha beta'));
    // No click into the editor: a file open on its own leaves the focus on
    // the screen, and the editor's own key handler never hears the chord.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('source-find-input')), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('source-replace-input')), findsOneWidget);
  });

  testWidgets('a file opened outside a library reads in the read view', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeDocument('/tmp/draft.md', '# A title\n\nA paragraph.'),
    );
    await tester.tap(find.byKey(const Key('editor-preview-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownReadView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an edit is written back to the file', (tester) async {
    final draft = _FakeDocument('/tmp/draft.md', 'one');
    await pump(tester, draft);
    surface(tester).replaceText(3, 3, ' two');
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(draft.writes.last, 'one two');
  });

  testWidgets('a change on disk comes in while nothing is unsaved', (
    tester,
  ) async {
    final draft = _FakeDocument('/tmp/draft.md', 'one');
    await pump(tester, draft);
    draft.changeOnDisk('changed elsewhere');
    await tester.pumpAndSettle();
    expect(editorText(tester), 'changed elsewhere');
  });

  testWidgets('several are tabs; closing the last lands back where it came '
      'from', (tester) async {
    final a = _FakeDocument('/tmp/a.md', 'A');
    final b = _FakeDocument('/tmp/b.md', 'B');
    await pump(tester, a);
    files.open(b);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outside-tab-a.md')), findsOne);
    expect(editorText(tester), 'B');

    await tester.tap(find.byKey(const Key('outside-tab-a.md')));
    await tester.pumpAndSettle();
    expect(editorText(tester), 'A');

    // Ctrl+W closes the one showing.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outside-tab-a.md')), findsNothing);
    expect(editorText(tester), 'B');

    files.close('/tmp/b.md');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open')), findsOne);
    expect(find.byType(MarkdownSourceView), findsNothing);
  });

  testWidgets('back closes them all', (tester) async {
    await pump(tester, _FakeDocument('/tmp/a.md', 'A'));
    files.open(_FakeDocument('/tmp/b.md', 'B'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open')), findsOne);
    expect(files.isEmpty, isTrue);
  });

  testWidgets('on the desktop it draws its own window bar', (tester) async {
    await pump(tester, _FakeDocument('/tmp/a.md', 'A'), customTitleBar: true);
    expect(find.byKey(const Key('outside-file-bar')), findsOne);
    expect(find.byKey(const Key('window-close')), findsOne);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('outside-file-bar')),
        matching: find.byType(BackButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open')), findsOne);
  });
}
