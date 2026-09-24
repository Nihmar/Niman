import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

NoteView _view({
  required String path,
  Future<String> Function(String)? readNote,
  Future<void> Function(String, String)? writeNote,
  bool showLineNumbers = true,
  bool autofocusEditor = false,
  bool showPreview = false,
  ValueChanged<EditorKind>? onEditorKindChanged,
  int? initialCaretOffset,
}) => NoteView(
  showLineNumbers: showLineNumbers,
  autofocusEditor: autofocusEditor,
  showPreview: showPreview,
  onEditorKindChanged: onEditorKindChanged,
  path: path,
  readNote: readNote,
  writeNote: writeNote,
  initialCaretOffset: initialCaretOffset,
);

/// The note's source pane.
MarkdownSourceViewState _surface(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

String _editorText(WidgetTester tester) => _surface(tester).widget.buffer.text;

/// The note made to say [text], as typing would: one edit to the pane.
void _setText(WidgetTester tester, String text) {
  final surface = _surface(tester);
  surface.replaceText(0, surface.widget.buffer.length, text);
}

void main() {
  group('NoteView', () {
    testWidgets('loads the note file into the editor', (tester) async {
      String? readPath;
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (p) async {
              readPath = p;
              return '# Hello\r\nworld';
            },
          ),
        ),
      );
      await tester.pump(); // let the async load land.
      expect(readPath, '/notes/a.md');
      expect(find.byType(MarkdownSourceView), findsOneWidget);
      // CRLF is normalized to LF on load.
      expect(_editorText(tester), '# Hello\nworld');
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('the preview takes the pane and the editor steps aside', (
      tester,
    ) async {
      // One pane, one of the two in it: the eye is the whole layout now,
      // and the pane it leaves stays mounted offstage.
      var preview = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  IconButton(
                    key: const Key('editor-preview-toggle'),
                    icon: const Icon(Icons.visibility),
                    onPressed: () => setState(() => preview = !preview),
                  ),
                  Expanded(
                    child: _view(
                      path: '/notes/a.md',
                      showPreview: preview,
                      readNote: (_) async => '# Head\n\nbody text',
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
      expect(find.byType(MarkdownSourceView), findsOneWidget);
      expect(find.byType(MarkdownReadView), findsNothing);
      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await tester.pump();
      expect(find.byType(MarkdownReadView), findsOneWidget);
      expect(find.byType(MarkdownSourceView), findsNothing);
      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await tester.pump();
      expect(find.byType(MarkdownSourceView), findsOneWidget);
      expect(find.byType(MarkdownReadView), findsNothing);
    });

    testWidgets('autosaves ~500 ms after the last edit', (tester) async {
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
          ),
        ),
      );
      await tester.pump();
      _setText(tester, 'start!');
      await tester.pump();
      expect(writes, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, ['start!']);
      expect(find.text('Saved'), findsOneWidget);
    });

    testWidgets('saves go through saveNote with one session per opening', (
      tester,
    ) async {
      final saves = <(String, String, int)>[];
      var seamWrites = 0;
      Widget view(String path) => _app(
        NoteView(
          showLineNumbers: true,
          autofocusEditor: false,
          path: path,
          readNote: (_) async => 'start',
          writeNote: (_, _) async => seamWrites++,
          saveNote: (path, content, {required editSession}) async =>
              saves.add((path, content, editSession)),
        ),
      );
      await tester.pumpWidget(view('/notes/a.md'));
      await tester.pump();
      _setText(tester, 'one');
      await tester.pump(const Duration(milliseconds: 600));
      _setText(tester, 'two');
      await tester.pump(const Duration(milliseconds: 600));

      expect(saves.map((s) => s.$2), ['one', 'two']);
      expect(saves[0].$1, '/notes/a.md');
      // Two autosaves of one opening share the session.
      expect(saves[1].$3, saves[0].$3);
      // saveNote wins over the writeNote seam.
      expect(seamWrites, 0);

      await tester.pumpWidget(view('/notes/b.md'));
      await tester.pump();
      _setText(tester, 'three');
      await tester.pump(const Duration(milliseconds: 600));
      expect(saves.last.$1, '/notes/b.md');
      expect(saves.last.$3, isNot(saves[0].$3));
    });

    testWidgets('a selection-only change does not schedule a save', (
      tester,
    ) async {
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
          ),
        ),
      );
      await tester.pump();
      _surface(tester).placeCaret(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, isEmpty);
    });

    testWidgets('the line-numbers toggle reaches the editor', (tester) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            showLineNumbers: false,
          ),
        ),
      );
      await tester.pump();
      final editor = tester.widget<MarkdownSurface>(
        find.byType(MarkdownSurface),
      );
      expect(editor.showLineNumbers, isFalse);
    });

    testWidgets('the keyboard-on-open toggle reaches the editor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            autofocusEditor: true,
          ),
        ),
      );
      await tester.pump(); // let the load land; autofocus takes effect.
      final editor = tester.widget<MarkdownSurface>(
        find.byType(MarkdownSurface),
      );
      expect(editor.autofocus, isTrue);
      // Let the focus-driven cursor-blink timer lapse (re_editor schedules
      // a 100 ms one-shot on Android) so none is pending at teardown.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
    });

    testWidgets('saves on dispose when the debounce has not fired', (
      tester,
    ) async {
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
          ),
        ),
      );
      await tester.pump();
      _setText(tester, 'start!');
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      expect(writes, ['start!']);
    });

    // Issue #156: an attachment opened from the tree used to show the
    // worker's exception as the note's text, and report it saved.
    testWidgets('a file that is not text says so, and is never saved', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/photo.jpg',
            readNote: (_) async =>
                throw const NoteReadFailure('bad utf-8', notText: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(AppStrings.noteNotText), findsOneWidget);
      expect(find.textContaining('bad utf-8'), findsNothing);
      expect(find.byType(MarkdownSourceView), findsNothing);
      expect(find.text(AppStrings.noteStatusSaved), findsNothing);
    });

    testWidgets('any other load failure is a message, not the exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => throw StateError('disk on fire'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(AppStrings.noteLoadFailed), findsOneWidget);
      expect(find.textContaining('disk on fire'), findsNothing);
    });

    // The outgoing note's edits leave with its own path; nothing left in
    // the buffer may land on a file that did not load — here, a picture.
    testWidgets('edits never land on a file that did not load', (tester) async {
      final writes = <(String, String)>[];
      Future<String> read(String path) async => path.endsWith('.md')
          ? 'start'
          : throw const NoteReadFailure('bad utf-8', notText: true);
      Future<void> write(String path, String content) async =>
          writes.add((path, content));
      await tester.pumpWidget(
        _app(_view(path: '/notes/a.md', readNote: read, writeNote: write)),
      );
      await tester.pump();
      _setText(tester, 'start!');
      await tester.pump();
      await tester.pumpWidget(
        _app(_view(path: '/notes/photo.jpg', readNote: read, writeNote: write)),
      );
      await tester.pump();
      expect(find.text(AppStrings.noteNotText), findsOneWidget);
      // Leaving the pane is what used to flush the buffer to widget.path.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(writes, [('/notes/a.md', 'start!')]);
    });

    // The preview has no editable: flipping the switch must dismiss the
    // keyboard instead of leaving it up over a read-only pane.
    testWidgets('flipping to preview dismisses the keyboard', (tester) async {
      var showPreview = false;
      late StateSetter flip;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                flip = setState;
                return NoteView(
                  path: '/notes/a.md',
                  showLineNumbers: false,
                  autofocusEditor: true,
                  showPreview: showPreview,
                  readNote: (_) async => 'hello',
                );
              },
            ),
          ),
        ),
      );
      await tester.pump(); // load lands, the editor mounts and autofocuses.
      await tester.pump();
      final editorFocus = tester
          .widget<MarkdownSurface>(find.byType(MarkdownSurface))
          .focusNode!;
      expect(editorFocus.hasPrimaryFocus, isTrue);
      // Let the focus-driven blink one-shot lapse while the editor is
      // still mounted (re_editor never cancels it, so disposing the
      // editor first would fire it use-after-dispose).
      await tester.pump(const Duration(milliseconds: 200));
      expect(editorFocus.hasPrimaryFocus, isTrue);

      // Straight after the flip (the fade has not advanced, so the editor
      // is still mounted): the IME target is already gone.
      flip(() => showPreview = true);
      await tester.pump();
      expect(editorFocus.hasPrimaryFocus, isFalse);
      // Step past the fade in small frames: the fade disposes the editor
      // at 180 ms, leaving no timer pending at teardown.
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    });

    // Opening straight into the preview must dismiss an existing focus
    // once the load lands (e.g. the search field behind the new note).
    testWidgets('opening in preview dismisses an existing focus', (
      tester,
    ) async {
      final gate = Completer<String>();
      final fieldFocus = FocusNode();
      addTearDown(fieldFocus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: fieldFocus),
                Expanded(
                  child: NoteView(
                    path: '/notes/a.md',
                    showLineNumbers: false,
                    autofocusEditor: false,
                    showPreview: true,
                    readNote: (_) => gate.future,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(); // load pending behind the gate.
      fieldFocus.requestFocus();
      await tester.pump();
      expect(fieldFocus.hasFocus, isTrue);

      gate.complete('hello');
      await tester.pump();
      await tester.pump();
      expect(fieldFocus.hasFocus, isFalse);
    });

    testWidgets('the status icons breathe on desktop', (tester) async {
      // The test host is a desktop platform: each status icon stands off
      // its neighbours (user, 2026-09-11). The phone keeps the row
      // tight.
      await tester.pumpWidget(
        _app(_view(path: '/notes/a.md', readNote: (_) async => 'hello')),
      );
      await tester.pump();
      await tester.pump();
      final outline = find.byKey(const Key('outline-toggle'));
      final findButton = find.byKey(const Key('editor-find-open'));
      expect(outline, findsOneWidget);
      expect(findButton, findsOneWidget);
      expect(tester.getRect(outline).width, 40);
      final between =
          tester.getTopLeft(findButton).dx - tester.getTopRight(outline).dx;
      expect(between, 6);
    });

    // The controls are on the left and what the note reads as is on the
    // right: the word count sits with the saved status, past the
    // Spacer, not among the buttons.
    testWidgets('the word count sits with the status, not with the icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_view(path: '/notes/a.md', readNote: (_) async => 'hello')),
      );
      await tester.pump();
      await tester.pump();
      final words = find.text('1 word');
      final status = find.text(AppStrings.noteStatusSaved);
      final findButton = find.byKey(const Key('editor-find-open'));
      expect(words, findsOneWidget);
      expect(status, findsOneWidget);
      expect(
        tester.getTopLeft(words).dx,
        greaterThan(tester.getTopRight(findButton).dx + 100),
      );
      expect(
        tester.getTopRight(words).dx,
        lessThanOrEqualTo(tester.getTopLeft(status).dx),
      );
    });

    testWidgets('the status icons keep their places across a preview switch', (
      tester,
    ) async {
      // Find has nothing to search once the preview has the pane to
      // itself, but dropping it out of the row slid everything after it
      // leftwards — under the thumb that had just tapped the eye.
      Widget view({required bool preview}) => _app(
        _view(
          path: '/notes/a.md',
          readNote: (_) async => 'one two three',
          showPreview: preview,
        ),
      );
      await tester.pumpWidget(view(preview: false));
      await tester.pump();
      await tester.pump();
      final spellCheck = find.byKey(const Key('spell-check-open'));
      final words = find.text('3 words');
      expect(words, findsOneWidget);
      final editing = tester.getTopLeft(words);
      final spellAt = spellCheck.evaluate().isEmpty
          ? null
          : tester.getTopLeft(spellCheck);

      await tester.pumpWidget(view(preview: true));
      await tester.pump();
      expect(tester.getTopLeft(words), editing);
      if (spellAt != null) {
        expect(tester.getTopLeft(spellCheck), spellAt);
      }
    });

    testWidgets('the editor switch goes when there is no editor on screen', (
      tester,
    ) async {
      // Preview-only has no editor showing, so there are not two of
      // them to be between (device report, 2026-09-18).
      Widget view({required bool preview}) => _app(
        _view(
          path: '/notes/a.md',
          readNote: (_) async => 'one two three',
          showPreview: preview,
          onEditorKindChanged: (_) {},
        ),
      );
      final toggle = find.byKey(const Key('editor-kind-toggle'));

      await tester.pumpWidget(view(preview: false));
      await tester.pump();
      await tester.pump();
      expect(toggle, findsOneWidget);
      // Nothing moves when it goes, in either direction: it is the last
      // thing before the Spacer so nothing slides sideways, and the row
      // keeps the height it has with the button in it (user,
      // 2026-09-18) so nothing slides up or down either.
      final findButton = find.byKey(const Key('editor-find-open'));
      final findAt = tester.getTopLeft(findButton);
      final row = tester.getSize(find.byKey(const Key('status-row')));

      await tester.pumpWidget(view(preview: true));
      await tester.pump();
      expect(toggle, findsNothing);
      expect(tester.getTopLeft(findButton), findAt);
      expect(tester.getSize(find.byKey(const Key('status-row'))), row);
    });

    testWidgets('the preview keeps its scroll offset across the switch', (
      tester,
    ) async {
      // Device report, 2026-09-11: every return to the preview restarted
      // from the top. Both panes stay mounted (Offstage) so the preview
      // keeps its parse, map and scroll position.
      final text = List.generate(
        200,
        (i) => 'Paragraph $i with enough words to wrap.',
      ).join('\n\n');
      Widget view({required bool preview}) => _app(
        _view(
          path: '/notes/a.md',
          readNote: (_) async => text,
          showPreview: preview,
        ),
      );
      await tester.pumpWidget(view(preview: true));
      await tester.pump();
      await tester.pump();
      final scrollable = find.descendant(
        of: find.byType(MarkdownReadView),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      tester.state<ScrollableState>(scrollable).position.jumpTo(2000);
      await tester.pump();
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offset, greaterThan(0));
      await tester.pumpWidget(view(preview: false));
      await tester.pump();
      await tester.pumpWidget(view(preview: true));
      await tester.pump();
      expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    });

    testWidgets('an initial caret offset lands the caret after load', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => '# Hi\n\nbody here\n',
            initialCaretOffset: 6,
          ),
        ),
      );
      await tester.pump();
      final selection = _surface(tester).selection;
      expect(selection.anchor, 6);
      expect(selection.extent, 6, reason: 'line 2, column 0');
      // The caret blinks on timers while focused (periodic tick plus a
      // one-shot on Android): let them fire, then unfocus before
      // teardown, or the test invariant fails on a live timer.
      await tester.pump(const Duration(milliseconds: 200));
      tester
          .widget<MarkdownSurface>(find.byType(MarkdownSurface))
          .focusNode!
          .unfocus();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a template caret takes focus even with autofocus off', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _view(
            path: '/notes/a.md',
            readNote: (_) async => '# Hi\n\nbody\n',
            initialCaretOffset: 6,
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<MarkdownSurface>(find.byType(MarkdownSurface))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      // Same blink-timer teardown as above.
      await tester.pump(const Duration(milliseconds: 200));
      tester
          .widget<MarkdownSurface>(find.byType(MarkdownSurface))
          .focusNode!
          .unfocus();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a caret landing the editor takes no focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_view(path: '/notes/b.md', readNote: (_) async => 'plain\n')),
      );
      await tester.pump();
      expect(
        tester
            .widget<MarkdownSurface>(find.byType(MarkdownSurface))
            .focusNode!
            .hasFocus,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
