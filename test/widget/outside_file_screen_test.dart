// Issue #77: a Markdown file open on its own. It gets the editor and
// nothing a library adds: its frontmatter is text, there is no image
// button to copy into a library, and edits go back to the file itself.
// Several are tabs; closing the last, or going back, lands where the
// user came from. A change made on disk comes in while the editor has
// nothing of its own unsaved.
//
// The files are real ones (#1334): the editor reads and writes them as it
// does a library note — by bytes, with a byte order mark, line endings and
// an encoding kept — and sees a change made outside by the file's stamp.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/outside_files.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_window_controller.dart';

/// A file on disk whose changes are on cue: the watch the platform gives is
/// replaced by [changeOnDisk] and [heardChange].
final class _FakeDocument extends EditorOnlyDocument {
  new(super.filePath);

  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<void> changes() => _changes.stream;

  /// Something else wrote [bytes] to it.
  void changeOnDisk(List<int> bytes) {
    File(filePath).writeAsBytesSync(bytes);
    heardChange();
  }

  /// The watch reports that something happened to the file.
  void heardChange() => _changes.add(null);
}

void main() {
  late OutsideFiles files;
  late Directory dir;

  setUp(() {
    files = OutsideFiles();
    dir = Directory.systemTemp.createTempSync('niman_outside_screen');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// A document of a real file [name] holding [bytes], in [folder] of the
  /// temp directory.
  _FakeDocument doc(String name, List<int> bytes, {String folder = ''}) {
    final where = Directory(p.join(dir.path, folder))
      ..createSync(recursive: true);
    return _FakeDocument(
      (File(p.join(where.path, name))..writeAsBytesSync(bytes)).path,
    );
  }

  _FakeDocument text(String name, String content, {String folder = ''}) =>
      doc(name, utf8.encode(content), folder: folder);

  /// The real reads are isolates and a stat: real waits, and a frame each.
  Future<void> settle(WidgetTester tester) async {
    for (var turn = 0; turn < 3; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
    }
  }

  Future<void> pump(
    WidgetTester tester,
    EditorOnlyDocument first, {
    bool customTitleBar = false,
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
    await tester.pump();
    // The first read of a run spawns an isolate: it can take a while.
    for (var i = 0; i < 8; i++) {
      await settle(tester);
      if (find.byType(MarkdownSourceView).evaluate().isNotEmpty) break;
    }
    // The route slides in.
    await tester.pumpAndSettle();
  }

  MarkdownSourceViewState surface(WidgetTester tester) =>
      tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

  String editorText(WidgetTester tester) => surface(tester).widget.buffer.text;

  testWidgets('it opens with its name and where it is, frontmatter as text '
      'and no image button', (tester) async {
    final readme = text(
      'README.md',
      '---\ntype: list\n---\n# Project',
      folder: 'project',
    );
    await pump(tester, readme);
    expect(find.text('README.md'), findsOne);
    expect(
      find.descendant(
        of: find.byKey(const Key('outside-file-where')),
        matching: find.textContaining(readme.folder, findRichText: true),
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
    await pump(tester, text('draft.md', 'alpha beta'));
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
    await pump(tester, text('draft.md', '# A title\n\nA paragraph.'));
    final toggle = find.byKey(const Key('editor-preview-toggle'));
    // The toggle is off until the note has loaded.
    for (
      var i = 0;
      i < 8 && tester.widget<IconButton>(toggle).onPressed == null;
      i++
    ) {
      await settle(tester);
    }
    await tester.tap(toggle);
    for (
      var i = 0;
      i < 8 && find.byType(MarkdownReadView).evaluate().isEmpty;
      i++
    ) {
      await settle(tester);
    }
    expect(find.byType(MarkdownReadView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an edit is written back to the file', (tester) async {
    final draft = text('draft.md', 'one');
    await pump(tester, draft);
    surface(tester).replaceText(3, 3, ' two');
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(File(draft.filePath).readAsStringSync(), 'one two');
  });

  group(
    'the bytes of a file are kept as a library note keeps them (#1334)',
    () {
      /// Opens [original], types [typed] after [after], waits for the save and
      /// answers the file's bytes.
      Future<List<int>> editAndSave(
        WidgetTester tester,
        List<int> original, {
        required String after,
        required String typed,
      }) async {
        final draft = doc('draft.md', original);
        await pump(tester, draft);
        final at = editorText(tester).indexOf(after) + after.length;
        surface(tester).replaceText(at, at, typed);
        await tester.pump(const Duration(seconds: 2));
        await settle(tester);
        return File(draft.filePath).readAsBytesSync();
      }

      testWidgets('a byte order mark and CRLF line endings', (tester) async {
        const original = '\u{FEFF}# Title\r\nsome words\r\nend\r\n';
        final saved = await editAndSave(
          tester,
          utf8.encode(original),
          after: 'some',
          typed: 'X',
        );
        expect(saved.take(3), [0xEF, 0xBB, 0xBF]);
        expect(saved, utf8.encode(original.replaceFirst('some', 'someX')));
      });

      testWidgets('a Windows-1252 file opens, says so, and is saved as UTF-8', (
        tester,
      ) async {
        // `café` and `naïve`, as one byte each.
        final original = [
          ...latin1.encode('caf'),
          0xE9,
          0x0A,
          ...latin1.encode('na'),
          0xEF,
          ...latin1.encode('ve\n'),
        ];
        final draft = doc('latin.md', original);
        await pump(tester, draft);
        expect(editorText(tester), 'café\nnaïve\n');
        expect(find.text(AppStrings.noteReadAsWindows1252), findsWidgets);

        surface(tester).replaceText(4, 4, '!');
        await tester.pump(const Duration(seconds: 2));
        await settle(tester);
        expect(
          File(draft.filePath).readAsBytesSync(),
          utf8.encode('café!\nnaïve\n'),
        );
      });

      testWidgets('a UTF-8 file says nothing about its encoding', (
        tester,
      ) async {
        await pump(tester, text('utf8.md', 'café\n'));
        expect(find.text(AppStrings.noteReadAsWindows1252), findsNothing);
      });
    },
  );

  testWidgets('a change on disk comes in while nothing is unsaved', (
    tester,
  ) async {
    final draft = text('draft.md', 'one');
    await pump(tester, draft);
    draft.changeOnDisk(utf8.encode('changed elsewhere'));
    await settle(tester);
    expect(editorText(tester), 'changed elsewhere');
  });

  testWidgets('a change of the same size and modification time is seen too '
      '(#1365)', (tester) async {
    final draft = text('draft.md', 'one');
    final file = File(draft.filePath);
    // A time ahead of the stat, to the second as a coarse clock writes it: the
    // stamp is ambiguous (the clock cannot tell a second write from the first).
    final modified = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000 *
          1000,
    );
    file.setLastModifiedSync(modified);
    await pump(tester, draft);
    expect(editorText(tester), 'one');

    // Another program: the same three bytes' worth, and the time put back.
    file
      ..writeAsStringSync('two')
      ..setLastModifiedSync(modified);
    draft.heardChange();
    // Two isolates this time: the bytes are hashed, then the file is read.
    for (var i = 0; i < 8 && editorText(tester) != 'two'; i++) {
      await settle(tester);
    }
    expect(editorText(tester), 'two');
  });

  testWidgets('several are tabs; closing the last lands back where it came '
      'from', (tester) async {
    final a = text('a.md', 'A');
    final b = text('b.md', 'B');
    await pump(tester, a);
    files.open(b);
    await settle(tester);
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

    files.close(b.filePath);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open')), findsOne);
    expect(find.byType(MarkdownSourceView), findsNothing);
  });

  testWidgets('back closes them all', (tester) async {
    await pump(tester, text('a.md', 'A'));
    files.open(text('b.md', 'B'));
    await settle(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open')), findsOne);
    expect(files.isEmpty, isTrue);
  });

  testWidgets('on the desktop it draws its own window bar', (tester) async {
    await pump(tester, text('a.md', 'A'), customTitleBar: true);
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
