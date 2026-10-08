// Paste as Markdown in a note (#531): the clipboard's HTML goes in as
// Markdown linked to its page, the snackbar says so, and its Undo puts the
// clipboard's plain text in its place; with no HTML the plain text goes in
// and nothing is said. On a phone it is an entry of the editor's menu.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/paste/clipboard_html.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/capture/paste_markdown_flow.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';

/// A clipboard whose HTML is [clip].
final class FakeClipboardHtml implements ClipboardHtmlReader {
  new(this.clip);

  ClipboardHtml? clip;

  @override
  Future<ClipboardHtml?> read() async => clip;
}

final Uri _page = Uri.parse('https://app.example.com/blog/offline-first');

const String _html = '<p><b>Conflicts</b> should read as a <i>choice</i>.</p>';

const String _markdown =
    '**Conflicts** should read as a *choice*.\n'
    '\n'
    '— [app.example.com](<https://app.example.com/blog/offline-first>)';

const String _plain = 'Conflicts should read as a choice.';

void main() {
  late FakeClipboardHtml clipboard;
  late PasteServices services;

  setUp(() {
    clipboard = FakeClipboardHtml(ClipboardHtml(_html, source: _page));
    services = PasteServices(html: clipboard, plainText: () async => _plain);
  });

  Future<NoteViewHandle> open(
    WidgetTester tester,
    String note, {
    bool menu = false,
  }) async {
    final key = GlobalKey<State<NoteView>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            // The shell's keys as the registry ships them, above the note
            // as the shell installs them.
            builder: (context) => CallbackShortcuts(
              bindings: appShortcutBindings({
                AppCommand.pasteAsMarkdown: () => unawaited(
                  pasteAsMarkdown(
                    context,
                    key.currentState! as NoteViewHandle,
                    services,
                  ),
                ),
              }),
              child: NoteView(
                key: key,
                path: '/notes/sync.md',
                showLineNumbers: false,
                autofocusEditor: true,
                toolbarTop: true,
                readNote: (_) async => note,
                writeNote: (_, _) async {},
                onPasteAsMarkdown: menu
                    ? (note) => pasteAsMarkdown(context, note, services)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key.currentState! as NoteViewHandle;
  }

  MarkdownSourceViewState editor(WidgetTester tester) =>
      tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

  BuildContext noteContext(WidgetTester tester) =>
      tester.element(find.byType(NoteView));

  testWidgets('the HTML goes in as Markdown, and Undo leaves the plain text', (
    tester,
  ) async {
    final note = await open(tester, 'On conflicts: \nNext.');
    editor(tester).placeCaret('On conflicts: '.length);
    await tester.pump();

    await pasteAsMarkdown(noteContext(tester), note, services);
    await tester.pumpAndSettle();
    expect(
      editor(tester).widget.buffer.text,
      'On conflicts: $_markdown\nNext.',
    );
    expect(
      find.text(AppStrings.pastedAsMarkdownWithLink('app.example.com')),
      findsOne,
    );

    await tester.tap(find.text(AppStrings.actionUndo));
    await tester.pumpAndSettle();
    expect(editor(tester).widget.buffer.text, 'On conflicts: $_plain\nNext.');
  });

  testWidgets('Ctrl+Shift+V reaches the command from inside the editor', (
    tester,
  ) async {
    await open(tester, '');
    // The caret is in the editor: the focus sits inside it.
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      focused.findAncestorWidgetOfExactType<MarkdownSourceView>(),
      isNotNull,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(editor(tester).widget.buffer.text, _markdown);
  });

  testWidgets('with no page the snackbar names none', (tester) async {
    clipboard.clip = const ClipboardHtml('<p>Hello <b>world</b></p>');
    final note = await open(tester, '');
    await pasteAsMarkdown(noteContext(tester), note, services);
    await tester.pumpAndSettle();
    expect(editor(tester).widget.buffer.text, 'Hello **world**');
    expect(find.text(AppStrings.pastedAsMarkdown), findsOne);
  });

  testWidgets('with no HTML the plain text goes in, and nothing is said', (
    tester,
  ) async {
    clipboard.clip = null;
    final note = await open(tester, '');
    await pasteAsMarkdown(noteContext(tester), note, services);
    await tester.pumpAndSettle();
    expect(editor(tester).widget.buffer.text, _plain);
    expect(find.byKey(const Key('paste-markdown-done')), findsNothing);
  });

  testWidgets('Undo leaves alone a paste that has been written over', (
    tester,
  ) async {
    final note = await open(tester, '');
    await pasteAsMarkdown(noteContext(tester), note, services);
    await tester.pumpAndSettle();
    final state = editor(tester)..replaceText(0, 2, 'XX');
    await tester.pump();
    final written = state.widget.buffer.text;

    await tester.tap(find.text(AppStrings.actionUndo));
    await tester.pumpAndSettle();
    expect(state.widget.buffer.text, written);
  });

  testWidgets("on a phone it is in the editor's menu", (tester) async {
    await open(tester, 'hello world', menu: true);
    await tester.longPressAt(
      tester.getTopLeft(find.byType(MarkdownSurface)) + const Offset(30, 18),
    );
    await tester.pumpAndSettle();
    if (find.byKey(const Key('menu-paste-markdown')).evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('menu-paste-markdown')));
    await tester.pumpAndSettle();
    // The long press selected the first word: the paste took its place.
    expect(editor(tester).widget.buffer.text, '$_markdown world');
    expect(
      find.text(AppStrings.pastedAsMarkdownWithLink('app.example.com')),
      findsOne,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
