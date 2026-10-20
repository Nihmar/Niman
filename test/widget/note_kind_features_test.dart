// #1109: a note of a kind whose feature is off opens in the plain editor,
// its `type:` kept and its file untouched; turning the kind back on brings
// its view back.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/kinds/list_note.dart';
import 'package:niman/src/ui/kinds/slides/slides_view.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

Features _off(LibraryFeature feature) =>
    const Features().withSwitch(feature, on: false);

void main() {
  late FakeLibrarySession controller;
  late Directory dir;

  setUp(() async {
    controller = FakeLibrarySession();
    // A real directory: the open note is read off disk, so the file has to
    // exist for the body to build.
    dir = await Directory.systemTemp.createTemp('niman_kind_features_');
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await dir.delete(recursive: true);
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        windowControllerProvider.overrideWithValue(
          FakeWindowController(customTitleBar: true),
        ),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> openNote(WidgetTester tester, String content) async {
    setSurfaceSize(tester, const Size(1200, 900));
    await controller.open(dir.path, create: true);
    File(p.join(dir.path, 'Spesa.md')).writeAsStringSync(content);
    await controller.createNote(
      parentPath: '',
      name: 'Spesa',
      content: content,
    );
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await settle(tester);
    await tester.tap(noteRow('Spesa.md'));
    // The note is read off disk on an isolate: give the real event loop
    // its turns while pumping, until the body has the note.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (find.byType(ListNoteView).evaluate().isNotEmpty ||
          find.byType(SlidesNoteView).evaluate().isNotEmpty ||
          find.byType(MarkdownSourceView).evaluate().isNotEmpty) {
        break;
      }
    }
    await settle(tester);
  }

  String onDisk() => File(p.join(dir.path, 'Spesa.md')).readAsStringSync();

  testWidgets('a list with Lists off opens as Markdown, bytes unchanged', (
    tester,
  ) async {
    const list = '---\ntype: list\n---\n- [ ] Pane\n';
    await openNote(tester, list);
    expect(find.byType(ListNoteView), findsOneWidget);
    expect(find.byKey(const Key('kind-edit-raw')), findsOneWidget);

    controller.features.value = _off(LibraryFeature.kindList);
    await settle(tester);
    expect(find.byType(ListNoteView), findsNothing);
    expect(find.byKey(const Key('kind-edit-raw')), findsNothing);
    expect(find.byType(MarkdownSourceView), findsOneWidget, reason: 'plain');
    expect(onDisk(), list, reason: 'the file was not touched');
    expect(controller.contentOf('Spesa.md'), list);

    controller.features.value = const Features();
    await settle(tester);
    expect(
      find.byType(ListNoteView),
      findsOneWidget,
      reason: 'the view is back',
    );
    expect(onDisk(), list);
  });

  testWidgets('a note opened with its kind off is plain from the start', (
    tester,
  ) async {
    const list = '---\ntype: list\n---\n- [ ] Pane\n';
    controller.features.value = _off(LibraryFeature.kindList);
    await openNote(tester, list);
    expect(find.byType(ListNoteView), findsNothing);
    expect(find.byType(MarkdownSourceView), findsOneWidget);
    expect(onDisk(), list);
  });

  testWidgets('a shopping list with shopping off opens as Markdown', (
    tester,
  ) async {
    const shopping = '---\ntype: shopping-list\n---\n- [ ] Pane\n';
    await openNote(tester, shopping);
    expect(find.byKey(const Key('list-quantity-pill')), findsOneWidget);

    controller.features.value = _off(LibraryFeature.kindShopping);
    await settle(tester);
    expect(find.byType(ListNoteView), findsNothing);
    expect(find.byType(MarkdownSourceView), findsOneWidget);
    expect(onDisk(), shopping);

    controller.features.value = const Features();
    await settle(tester);
    expect(find.byKey(const Key('list-quantity-pill')), findsOneWidget);
  });

  testWidgets('with Lists off, a shopping list is plain whatever its switch', (
    tester,
  ) async {
    const shopping = '---\ntype: shopping-list\n---\n- [ ] Pane\n';
    await openNote(tester, shopping);
    controller.features.value = _off(LibraryFeature.kindList);
    await settle(tester);
    expect(find.byType(ListNoteView), findsNothing);
    expect(find.byType(MarkdownSourceView), findsOneWidget);
    expect(onDisk(), shopping);
  });

  testWidgets('with shopping off a list has no shopping view to swap to', (
    tester,
  ) async {
    const list = '---\ntype: list\n---\n- [ ] Pane\n';
    await openNote(tester, list);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.byKey(const Key('note-menu-kindSwitch')), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await settle(tester);

    controller.features.value = _off(LibraryFeature.kindShopping);
    await settle(tester);
    expect(find.byType(ListNoteView), findsOneWidget, reason: 'still a list');
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    expect(find.byKey(const Key('note-menu-kindSwitch')), findsNothing);
  });

  testWidgets('slides with Slides off open as Markdown, bytes unchanged', (
    tester,
  ) async {
    const slides = '---\ntype: slides\n---\n\n# One\n\n---\n\n## Two\n';
    await openNote(tester, slides);
    expect(find.byType(SlidesNoteView), findsOneWidget);

    controller.features.value = _off(LibraryFeature.kindSlides);
    await settle(tester);
    expect(find.byType(SlidesNoteView), findsNothing);
    expect(find.byType(MarkdownSourceView), findsOneWidget);
    expect(onDisk(), slides);
  });
}
