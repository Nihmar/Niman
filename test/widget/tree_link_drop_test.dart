// #704: a file dragged from the tree and let go on an open note writes a
// link to it where the pointer let it go — one edit — while a folder
// dragged there writes nothing, and the tree's own drops still move.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late Directory dir;

  setUp(() {
    controller = FakeLibrarySession();
    dir = Directory.systemTemp.createTempSync('niman_link_drop');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  Future<void> pumpShell(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await controller.open(dir.path, create: true);
    // The editor reads its note off the disk.
    File(p.join(dir.path, 'alpha.md')).writeAsStringSync('one two three\n');
    await controller.createFolder(parentPath: '', name: 'docs');
    await controller.createNote(
      parentPath: '',
      name: 'alpha',
      content: 'one two three\n',
    );
    await controller.createNote(parentPath: '', name: 'beta');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    // The note is read off disk on an isolate: give the real event loop its
    // turns while pumping, until the editor has the note.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.byType(MarkdownSourceView).evaluate().isNotEmpty) break;
    }
    await settle(tester);
    expect(find.byType(MarkdownSourceView), findsOne);
  }

  MarkdownSourceViewState view(WidgetTester tester) =>
      tester.state(find.byType(MarkdownSourceView));

  Future<void> dragMouse(WidgetTester tester, Finder from, Offset to) async {
    final start = tester.getCenter(from);
    final mouse = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      await mouse.moveTo(Offset.lerp(start, to, step / 10)!);
      await tester.pump();
    }
    await mouse.up();
    await settle(tester);
  }

  testWidgets('a note dropped on the note is linked where it was let go', (
    tester,
  ) async {
    await pumpShell(tester);
    final editor = tester.getTopLeft(find.byType(MarkdownSourceView));
    // Over the first line, between its words.
    final point = editor + const Offset(80, 12);
    final at = view(tester).offsetAt(point);
    expect(at, isNotNull);
    final before = view(tester).widget.buffer.text;

    await dragMouse(tester, noteRow('beta.md'), point);

    expect(
      view(tester).widget.buffer.text,
      '${before.substring(0, at)}[[beta]]${before.substring(at!)}',
    );
    expect(view(tester).selection.extent, at + '[[beta]]'.length);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('a folder dropped on the note writes nothing', (tester) async {
    await pumpShell(tester);
    final before = view(tester).widget.buffer.text;
    final point =
        tester.getTopLeft(find.byType(MarkdownSourceView)) +
        const Offset(80, 12);

    await dragMouse(tester, noteRow('docs'), point);

    expect(view(tester).widget.buffer.text, before);
    expect(await controller.ops!.find('docs'), isNotNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
