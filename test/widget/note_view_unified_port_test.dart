// The legacy source editor's shell tests, on the unified surface (#245,
// phase 3's exit criterion: the surface tests that are not Quill-specific,
// ported and green). Each one is a promise the note made with re_editor
// under it — undo after open, the unsaved dot, the format keys, Escape, the
// outline, the memento, images, links, kinds, the frontmatter check, the
// toolbar's focus, the column — and holds here with the flag on.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_link_source.dart';

/// The keyboard's tests run on the desktop, where the keyboard is.
final TargetPlatformVariant _desktop = TargetPlatformVariant.only(
  TargetPlatform.linux,
);

/// A note view with the unified engine on.
NoteView _note({
  required String text,
  Key? key,
  String path = '/n/a.md',
  List<String>? writes,
  int reloadToken = 0,
  UnsavedTracker? tracker,
  bool active = true,
  bool autofocus = false,
  bool toolbarTop = false,
  NoteMemento? memento,
  void Function(String, NoteMemento)? onMemento,
  String? libraryRoot,
  FakeLinkSource? links,
  List<String>? opened,
  String? initialAnchor,
  int? initialCaret,
  bool showPreview = false,
  bool live = false,
  Future<String?> Function()? pickImagePath,
  Future<String> Function(String root, String source)? importImage,
  NoteColumn column = NoteColumn.off,
  Future<String> Function(String path)? readNote,
}) => NoteView(
  key: key,
  path: path,
  showLineNumbers: true,
  autofocusEditor: autofocus,
  toolbarTop: toolbarTop,
  unifiedMarkdown: true,
  reloadToken: reloadToken,
  unsavedTracker: tracker,
  active: active,
  initialMemento: memento,
  onMemento: onMemento,
  libraryRoot: libraryRoot,
  linkSource: links,
  onOpenNote: (path, anchor) => opened?.add('$path|$anchor'),
  initialAnchor: initialAnchor,
  initialCaretOffset: initialCaret,
  showPreview: showPreview,
  showWysiwyg: live,
  pickImagePath: pickImagePath,
  importImage: importImage,
  noteColumn: column,
  readNote: readNote ?? (_) async => text,
  writeNote: (_, content) async => writes?.add(content),
);

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

MarkdownSourceViewState _surface(WidgetTester tester) =>
    tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

Future<void> _ctrl(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

void main() {
  tearDown(() => AppKeyMap.current.value = KeyMap.defaults);

  group('undo after open (undo_after_open_test)', () {
    testWidgets('Ctrl+Z on a note just opened leaves it as it is', (
      tester,
    ) async {
      final writes = <String>[];
      await tester.pumpWidget(_app(_note(text: 'hello world', writes: writes)));
      await tester.pumpAndSettle();
      final surface = _surface(tester);
      surface.focusNode.requestFocus();
      await tester.pump();
      await _ctrl(tester, LogicalKeyboardKey.keyZ);
      await tester.pump(const Duration(seconds: 2));
      expect(surface.widget.buffer.text, 'hello world');
      expect(surface.canUndo, isFalse);
      expect(writes, isEmpty, reason: 'nothing to save');
    }, variant: _desktop);

    testWidgets('undo after an edit goes back to the note, no further', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_note(text: 'hello world')));
      await tester.pumpAndSettle();
      final surface = _surface(tester)..replaceText(11, 11, '!');
      await tester.pump();
      expect(surface.undo(), isTrue);
      await tester.pump();
      expect(surface.widget.buffer.text, 'hello world');
      expect(surface.canUndo, isFalse);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('text taken again from disk is where undo starts', (
      tester,
    ) async {
      var disk = 'one';
      Widget view(int token) => _app(
        _note(text: '', reloadToken: token, readNote: (_) async => disk),
      );
      await tester.pumpWidget(view(0));
      await tester.pumpAndSettle();
      disk = 'two';
      await tester.pumpWidget(view(1));
      await tester.pumpAndSettle();
      final surface = _surface(tester);
      expect(surface.widget.buffer.text, 'two');
      expect(surface.canUndo, isFalse);
    });
  });

  group('the unsaved dot (unsaved_tracking_test)', () {
    testWidgets('tracks edits and clears them when the save lands', (
      tester,
    ) async {
      final tracker = UnsavedTracker();
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          _note(
            text: 'start',
            path: '/n/b.md',
            tracker: tracker,
            writes: writes,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tracker.hasUnsaved, isFalse);
      _surface(tester).replaceText(5, 5, '!');
      await tester.pump();
      expect(tracker.unsavedPaths, <String>['/n/b.md']);
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, <String>['start!']);
      expect(tracker.hasUnsaved, isFalse);
    });

    testWidgets('the guard save writes the latest text at once', (
      tester,
    ) async {
      final tracker = UnsavedTracker();
      final writes = <String>[];
      await tester.pumpWidget(
        _app(_note(text: 'start', tracker: tracker, writes: writes)),
      );
      await tester.pumpAndSettle();
      _surface(tester).replaceText(5, 5, '!');
      await tester.pump();
      await tracker.saveAll();
      expect(writes, <String>['start!']);
      expect(tracker.hasUnsaved, isFalse);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('the format keys (format_keys_test)', () {
    Future<MarkdownSourceViewState> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(_note(text: 'hello world', autofocus: true)),
      );
      await tester.pumpAndSettle();
      final surface = _surface(tester);
      surface.focusNode.requestFocus();
      await tester.pump();
      surface.select(const SelectionModel(anchor: 0, extent: 5));
      await tester.pump();
      return surface;
    }

    testWidgets('Ctrl+B bolds the selection', (tester) async {
      final surface = await pump(tester);
      await _ctrl(tester, LogicalKeyboardKey.keyB);
      expect(surface.widget.buffer.text, startsWith('**hello**'));
      await tester.pump(const Duration(seconds: 1));
    }, variant: _desktop);

    testWidgets('Ctrl+Shift+L makes the line a list', (tester) async {
      final surface = await pump(tester);
      await _ctrl(tester, LogicalKeyboardKey.keyL, shift: true);
      expect(surface.widget.buffer.text, '- hello world');
      await tester.pump(const Duration(seconds: 1));
    }, variant: _desktop);
  });

  testWidgets('Esc takes a selection first, then reaches the app '
      '(editor_escape_test)', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      _app(
        Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) => dismissed++,
            ),
          },
          child: _note(text: 'Some text.', toolbarTop: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = _surface(tester);
    surface.focusNode.requestFocus();
    await tester.pump();
    surface.select(const SelectionModel(anchor: 0, extent: 4));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(surface.selection.isCollapsed, isTrue);
    expect(dismissed, 0, reason: 'the selection took the first press');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(dismissed, 1);
  }, variant: _desktop);

  testWidgets('an outline jump lands the caret on the heading '
      '(outline_jump_test)', (tester) async {
    final key = GlobalKey<State<NoteView>>();
    final text = StringBuffer('# Top\n');
    for (var line = 0; line < 60; line++) {
      text.write('line $line\n');
    }
    text.write('## Deep\nbody\n');
    await tester.pumpWidget(_app(_note(key: key, text: text.toString())));
    await tester.pumpAndSettle();
    (key.currentState! as NoteViewHandle).jumpToHeading(61);
    await tester.pumpAndSettle();
    final surface = _surface(tester);
    expect(surface.widget.buffer.lineOf(surface.selection.extent), 61);
    expect(find.text('## Deep', findRichText: true), findsOneWidget);
  });

  group('the memento (note_view_memento_test)', () {
    const text = 'first line\nsecond line\nthird line';

    testWidgets('going behind another tab hands in the selection', (
      tester,
    ) async {
      NoteMemento? handed;
      void keep(String _, NoteMemento memento) => handed = memento;
      await tester.pumpWidget(_app(_note(text: text, onMemento: keep)));
      await tester.pumpAndSettle();
      _surface(tester).select(const SelectionModel(anchor: 11, extent: 17));
      await tester.pump();
      await tester.pumpWidget(
        _app(_note(text: text, active: false, onMemento: keep)),
      );
      expect(handed?.selectionBase, 11);
      expect(handed?.selectionExtent, 17);
      expect(handed?.editorKind, 'source');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a memento puts the selection back, clamped', (tester) async {
      await tester.pumpWidget(
        _app(
          _note(
            text: text,
            memento: const NoteMemento(
              selectionBase: 23,
              selectionExtent: 999,
              editorKind: 'source',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _surface(tester).selection,
        const SelectionModel(anchor: 23, extent: text.length),
      );
    });
  });

  testWidgets('the image button links the image at the caret '
      '(image_insert_test)', (tester) async {
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('niman_ins_'),
    ))!;
    addTearDown(() => dir.deleteSync(recursive: true));
    final source = File(p.join(dir.path, 'pic.png'));
    await tester.runAsync(() => source.writeAsBytes(<int>[1, 2, 3]));
    final writes = <String>[];
    await tester.pumpWidget(
      _app(
        _note(
          text: 'hello',
          path: p.join(dir.path, 'note.md'),
          autofocus: true,
          libraryRoot: dir.path,
          writes: writes,
          pickImagePath: () async => source.path,
          importImage: (root, src) => Future.value('assets/xx.png'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = _surface(tester)..placeCaret(5);
    await tester.pump();
    await tester.tap(find.byKey(const Key('insert-image')));
    await tester.pump();
    await tester.pump();
    expect(surface.widget.buffer.text, contains('xx.png'));
    expect(surface.widget.buffer.text, startsWith('hello'));
    await tester.pump(const Duration(seconds: 1));
    expect(writes.last, contains('xx.png'));
  });

  testWidgets('Ctrl+click on a wikilink opens it (link_navigation_test)', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _app(
        _note(
          text: 'text [[Target]] more\nline two\n',
          path: '/notes/current.md',
          libraryRoot: '/notes',
          links: FakeLinkSource(notes: <String>['Target.md', 'current.md']),
          opened: opened,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = find.text('text [[Target]] more', findRichText: true);
    // Inside `[[Target]]`, where the line's own layout draws offset 8.
    final line = tester.renderObject<RenderParagraph>(paragraph);
    final at = line.localToGlobal(
      line.getOffsetForCaret(const TextPosition(offset: 8), Rect.zero) +
          const Offset(2, 8),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tapAt(at, kind: PointerDeviceKind.mouse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(opened, <String>['Target.md|null']);
  }, variant: _desktop);

  testWidgets('an anchor to open on lands on its heading '
      '(link_navigation_test)', (tester) async {
    await tester.pumpWidget(
      _app(
        _note(
          text: 'intro\n## My Heading\nbody\n',
          path: '/notes/current.md',
          libraryRoot: '/notes',
          links: FakeLinkSource(notes: <String>['current.md']),
          initialAnchor: 'My Heading',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_surface(tester).selection, const SelectionModel.at(6));
  });

  group('a template’s {{cursor}} (#53)', () {
    testWidgets('lands the caret, with the focus', (tester) async {
      await tester.pumpWidget(
        _app(_note(text: '# Titolo\n\ncorpo\n', initialCaret: 10)),
      );
      await tester.pumpAndSettle();
      final surface = _surface(tester);
      expect(surface.selection, const SelectionModel.at(10));
      expect(surface.focusNode.hasFocus, isTrue);
    });

    testWidgets('wins over a memento', (tester) async {
      await tester.pumpWidget(
        _app(
          _note(
            text: '# Titolo\n\ncorpo\n',
            initialCaret: 10,
            memento: const NoteMemento(
              selectionBase: 2,
              selectionExtent: 2,
              editorKind: 'source',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_surface(tester).selection, const SelectionModel.at(10));
    });
  });

  testWidgets('the preview shows what the editor holds, from its own lines', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_note(text: 'uno')));
    await tester.pumpAndSettle();
    final surface = _surface(tester)..replaceText(3, 3, ' due');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_app(_note(text: 'uno', showPreview: true)));
    await tester.pumpAndSettle();
    final read = tester.widget<MarkdownReadView>(find.byType(MarkdownReadView));
    expect(read.buffer.text, 'uno due');
    // A snapshot of the editor's buffer, not the buffer itself: the editor
    // goes on editing its own.
    expect(identical(read.buffer, surface.widget.buffer), isFalse);
    expect(find.textContaining('uno due', findRichText: true), findsWidgets);

    // Back to the editor, another edit, and the preview again follows it.
    await tester.pumpWidget(_app(_note(text: 'uno')));
    await tester.pumpAndSettle();
    _surface(tester).replaceText(7, 7, ' tre');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_app(_note(text: 'uno', showPreview: true)));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MarkdownReadView>(find.byType(MarkdownReadView))
          .buffer
          .text,
      'uno due tre',
    );
  });

  testWidgets('the flip to the read pane gives it the keyboard', (
    tester,
  ) async {
    final text = List<String>.generate(300, (i) => 'riga $i').join('\n\n');
    await tester.pumpWidget(_app(_note(text: text, autofocus: true)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(_note(text: text, showPreview: true)));
    await tester.pumpAndSettle();
    final scroll = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(MarkdownReadView),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(scroll.pixels, 0);
    // No click first: the page keys work at once.
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(scroll.pixels, greaterThan(0));
  });

  testWidgets('source, live and the read view keep the line at the top', (
    tester,
  ) async {
    // Headings among the paragraphs: taller in live and in the read view
    // than in source, so an offset in pixels would land elsewhere.
    final text = List<String>.generate(
      400,
      (i) => i % 10 == 0 ? '# Title $i' : 'Paragraph $i with a few words.',
    ).join('\n\n');
    await tester.pumpWidget(_app(_note(text: text, autofocus: true)));
    await tester.pumpAndSettle();
    final source = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    )..showAnchor((line: 401, fraction: 0.0));
    await tester.pumpAndSettle();
    expect(source.topAnchor?.line, 401);

    Future<int?> topAfter({bool read = false, bool live = false}) async {
      await tester.pumpWidget(
        _app(_note(text: text, showPreview: read, live: live, autofocus: true)),
      );
      await tester.pumpAndSettle();
      return read
          ? tester
                .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
                .topAnchor
                ?.line
          : tester
                .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
                .topAnchor
                ?.line;
    }

    expect(await topAfter(read: true), 401, reason: 'source to read');
    expect(await topAfter(), 401, reason: 'read to source');
    expect(await topAfter(live: true), 401, reason: 'source to live');
    expect(await topAfter(read: true, live: true), 401, reason: 'live to read');
    expect(await topAfter(live: true), 401, reason: 'read to live');
  });

  testWidgets('a key the user chose wins over the note’s own '
      '(chosen_keys_test)', (tester) async {
    AppKeyMap.current.value = KeyMap.defaults.withBinding(
      AppCommand.toggleDock,
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true),
    );
    var ran = 0;
    final keys = ChosenKeys(
      handlers: () => {AppCommand.toggleDock: () => ran++},
      active: () => true,
    )..attach();
    addTearDown(keys.detach);
    await tester.pumpWidget(_app(_note(text: 'hello', autofocus: true)));
    await tester.pumpAndSettle();
    final surface = _surface(tester)..replaceText(0, 0, '!');
    await tester.pump();
    await _ctrl(tester, LogicalKeyboardKey.keyZ);
    expect(ran, 1);
    expect(surface.widget.buffer.text, '!hello', reason: 'no undo heard it');
    await tester.pump(const Duration(seconds: 1));
  }, variant: _desktop);

  testWidgets('Ctrl+A then Ctrl+C copies the whole note '
      '(editor_copy_paths_test)', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(_app(_note(text: 'uno\ndue\n', autofocus: true)));
    await tester.pumpAndSettle();
    await _ctrl(tester, LogicalKeyboardKey.keyA);
    await _ctrl(tester, LogicalKeyboardKey.keyC);
    expect(copied, 'uno\ndue\n');
  }, variant: _desktop);

  testWidgets('a kind note goes back to its GUI and its edits save '
      '(note_kind_view_test)', (tester) async {
    final writes = <String>[];
    await tester.pumpWidget(
      _app(_note(text: '---\ntype: list\n---\n- [ ] one\n', writes: writes)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.pump();
    expect(writes, <String>['---\ntype: list\n---\n- [x] one\n']);
  });

  testWidgets('fixing a broken frontmatter as you type clears the warning '
      '(frontmatter_warning_test)', (tester) async {
    await tester.pumpWidget(_app(_note(text: '---\ntitle: [un\n---\nbody\n')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('frontmatter-error')), findsOneWidget);
    // `[un` → `un`: the block parses.
    final surface = _surface(tester)..replaceText(11, 12, '');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(surface.widget.buffer.text, '---\ntitle: un\n---\nbody\n');
    expect(find.byKey(const Key('frontmatter-error')), findsNothing);
  });

  testWidgets('a toolbar tap keeps the note focused (toolbar_test)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_note(text: 'hello', autofocus: true, toolbarTop: true)),
    );
    await tester.pumpAndSettle();
    final surface = _surface(tester);
    surface.focusNode.requestFocus();
    await tester.pump();
    surface.selectAll();
    await tester.pump();
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pumpAndSettle();
    expect(surface.focusNode.hasFocus, isTrue);
    expect(surface.widget.buffer.text, '**hello**');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the text sits in the note column (note_column_test)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(_note(text: 'hello', column: const NoteColumn())),
    );
    await tester.pumpAndSettle();
    final left = tester.getTopLeft(find.text('hello', findRichText: true)).dx;
    expect(left, closeTo(234 + NoteColumn.textInset, 1));
  });
}
