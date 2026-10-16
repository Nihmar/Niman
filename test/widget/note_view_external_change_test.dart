// An open note and the file changing under it (#1055): a clean buffer adopts
// the change, background tabs included; a buffer with edits keeps them, and
// its next save tells the writer which file it last saw, so the writer can
// keep the other version in the history before overwriting it.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/note_save_result.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  late UnsavedTracker tracker;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_external_view');
    tracker = UnsavedTracker();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  String write(String name, String text) {
    final path = p.join(dir.path, name);
    File(path).writeAsStringSync(text);
    return path;
  }

  /// The real reads are isolates and a stat: real waits, and a frame each.
  Future<void> settle(WidgetTester tester) async {
    for (var turn = 0; turn < 3; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
    }
  }

  List<String> texts(WidgetTester tester) => [
    for (final state in tester.stateList<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    ))
      state.widget.buffer.text,
  ];

  NoteView view(String path, {bool active = true, NoteSaver? saveNote}) =>
      NoteView(
        key: ValueKey(path),
        path: path,
        active: active,
        showLineNumbers: false,
        autofocusEditor: false,
        unsavedTracker: tracker,
        saveNote: saveNote,
      );

  Widget app(List<NoteView> views) => MaterialApp(
    home: Scaffold(
      body: Column(children: [for (final v in views) Expanded(child: v)]),
    ),
  );

  testWidgets('a tab behind the one on screen adopts the change too', (
    tester,
  ) async {
    final a = write('a.md', 'first note');
    final b = write('b.md', 'second note');
    await tester.pumpWidget(app([view(a), view(b, active: false)]));
    await settle(tester);
    expect(texts(tester), ['first note', 'second note']);

    // Another program rewrites the file of the tab nobody is looking at.
    File(b).writeAsStringSync('second note, rewritten elsewhere');
    tracker.notifyDiskChanged({b});
    await settle(tester);

    expect(texts(tester), ['first note', 'second note, rewritten elsewhere']);
  });

  testWidgets('a note with edits keeps them, and its save expects the file it '
      'last saw', (tester) async {
    final path = write('a.md', 'first note');
    final told = <DiskStamp?>[];
    Future<NoteSaveResult?> saver(
      String path,
      String content, {
      required int editSession,
      DiskStamp? expected,
    }) async {
      told.add(expected);
      return const NoteSaveResult(keptExternal: true);
    }

    await tester.pumpWidget(app([view(path, saveNote: saver)]));
    await settle(tester);
    final seen = DiskStamp.of(path)!;

    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .replaceText(0, 0, 'typed ');
    await tester.pump();
    File(path).writeAsStringSync('rewritten elsewhere, and much longer');
    tracker.notifyDiskChanged({path});
    await settle(tester);
    expect(texts(tester), ['typed first note'], reason: 'edits win');

    await tester.pump(const Duration(seconds: 2));
    expect(told, hasLength(1));
    expect(told.single!.sameAs(seen), isTrue);
    expect(
      told.single!.sameAs(DiskStamp.of(path)),
      isFalse,
      reason: 'the file is no longer the one the editor saw',
    );
    // The writer said it kept the other version: the user is told.
    expect(find.text(AppStrings.noteChangedOnDisk), findsOneWidget);
  });
}
