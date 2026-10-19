// #1109: with the readers off a PDF and a book take the path of any file the
// pane does not show — the note pane's "not a text note" message and, on a
// desktop, the hand-off to the system's application — and with annotations
// off the readers offer no annotating. Pictures are not readers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/shell_preview_actions.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

Features _off(LibraryFeature feature) =>
    const Features().withSwitch(feature, on: false);

void main() {
  group('isShownAttachment', () {
    test('a PDF and a book follow the readers, a picture does not', () {
      final off = _off(LibraryFeature.readers);
      for (final name in ['Docs/Paper.PDF', 'Books/Novel.EPUB']) {
        expect(isShownAttachment(name), isTrue, reason: name);
        expect(isShownAttachment(name), isTrue);
        expect(isShownAttachment(name, off), isFalse, reason: name);
        // Annotations alone do not take the reader away.
        expect(
          isShownAttachment(name, _off(LibraryFeature.annotations)),
          isTrue,
          reason: name,
        );
        expect(
          isShownAttachment(
            name,
            off.withSwitch(LibraryFeature.readers, on: true),
          ),
          isTrue,
          reason: 'on again is the whole undo',
        );
      }
      for (final name in ['a.png', 'b.JPG', 'c.webp']) {
        expect(isShownAttachment(name, off), isTrue, reason: name);
      }
      for (final name in ['a.md', 'c.zip']) {
        expect(isShownAttachment(name, off), isFalse, reason: name);
      }
    });

    test('the eye is offered on a PDF that is not shown as one', () {
      final off = _off(LibraryFeature.readers);
      expect(previewToggleOffered(path: 'a.pdf', kindGui: null), isFalse);
      expect(
        previewToggleOffered(path: 'a.pdf', kindGui: null, features: off),
        isTrue,
      );
    });
  });

  group('in the shell', () {
    late FakeLibrarySession controller;
    late FakeFilePicker filePicker;

    setUp(() {
      controller = FakeLibrarySession();
      filePicker = useFakeFilePicker();
    });

    Future<void> openOnPhone(WidgetTester tester, String name) async {
      setSurfaceSize(tester, const Size(400, 800));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            librarySessionProvider.overrideWithValue(controller),
            todoSourceFactoryProvider.overrideWithValue(
              (_) => FakeTodoSource(),
            ),
          ],
          child: const NimanApp(),
        ),
      );
      await tester.pump();
      await openLibrary(tester, filePicker);
      await controller.seedFile(name);
      await settle(tester);
      await tester.tap(noteRow(name));
      await settle(tester);
    }

    for (final name in ['paper.pdf', 'book.epub']) {
      testWidgets('$name with the readers off is not shown as one', (
        tester,
      ) async {
        controller.features.value = _off(LibraryFeature.readers);
        await openOnPhone(tester, name);
        expect(find.byType(AttachmentView), findsNothing);
        // The path of a file the pane does not show: the note pane.
        expect(find.byType(NoteView), findsOneWidget);
      });

      testWidgets('$name with the readers on is the reader', (tester) async {
        await openOnPhone(tester, name);
        expect(find.byType(AttachmentView), findsOneWidget);
      });
    }

    testWidgets('a picture is shown with the readers off', (tester) async {
      controller.features.value = _off(LibraryFeature.readers);
      await openOnPhone(tester, 'photo.png');
      expect(find.byType(AttachmentView), findsOneWidget);
    });

    testWidgets('switching the readers off takes the reader away', (
      tester,
    ) async {
      await openOnPhone(tester, 'paper.pdf');
      expect(find.byType(AttachmentView), findsOneWidget);
      controller.features.value = _off(LibraryFeature.readers);
      await settle(tester);
      expect(find.byType(AttachmentView), findsNothing);
      controller.features.value = const Features();
      await settle(tester);
      expect(find.byType(AttachmentView), findsOneWidget);
    });

    testWidgets('annotations off: the reader annotates nothing', (
      tester,
    ) async {
      await openOnPhone(tester, 'paper.pdf');
      var view = tester.widget<AttachmentView>(find.byType(AttachmentView));
      expect(view.onAnnotate, isNotNull);
      expect(view.marks, isNotNull);

      controller.features.value = _off(LibraryFeature.annotations);
      await settle(tester);
      view = tester.widget<AttachmentView>(find.byType(AttachmentView));
      expect(view.onAnnotate, isNull);
      expect(view.marks, isNull);

      controller.features.value = const Features();
      await settle(tester);
      view = tester.widget<AttachmentView>(find.byType(AttachmentView));
      expect(view.onAnnotate, isNotNull);
    });
  });
}
