// #538 for books: a book's text zooms as a note's does — a pinch, the zoom
// keys — on the books' own text size, the one the look sheet's slider
// sets, kept in the library and held to the slider's range.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:niman/src/ui/epub_text_zoom.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';
import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  late FakeLibrarySession session;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_epub_zoom_');
    session = FakeLibrarySession();
  });
  tearDown(() {
    dir.deleteSync(recursive: true);
    EpubLooks.reset();
  });

  String novel() => writeTestEpub(
    p.join(dir.path, 'novel.epub'),
    chapters: [
      (
        path: 'one.xhtml',
        body:
            '<h1>Chapter one</h1><p>It begins.</p>'
            '${List.filled(30, '<p>A paragraph of the book.</p>').join()}',
      ),
    ],
  ).path;

  Future<void> pump(
    WidgetTester tester, {
    bool zooms = true,
    ValueNotifier<Object?>? fullScreen,
  }) async {
    final path = novel();
    // Real time: the book is read on an isolate, which fake time never
    // lets finish.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EpubPane(
              path: path,
              cacheDir: () async => p.join(dir.path, 'cache'),
              onTextScale: zooms
                  ? (scale) => unawaited(keepEpubTextScale(session, scale))
                  : null,
              fullScreen: fullScreen,
            ),
          ),
        ),
      );
      final state = tester.state<EpubPaneState>(find.byType(EpubPane));
      for (var i = 0; i < 250 && state.document == null && !state.failed; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
  }

  Future<double> kept() async => (await session.epubLook).textScale;

  /// How tall the book's first paragraph is: its lines grow with the text.
  double height(WidgetTester tester) =>
      tester.getSize(find.text('It begins.')).height;

  /// Two fingers from [from] to [to], in steps.
  Future<void> twoFingers(
    WidgetTester tester,
    (Offset, Offset) from,
    (Offset, Offset) to,
  ) async {
    final one = await tester.startGesture(from.$1, pointer: 1);
    final two = await tester.startGesture(from.$2, pointer: 2);
    for (var step = 1; step <= 10; step++) {
      await one.moveTo(Offset.lerp(from.$1, to.$1, step / 10)!);
      await two.moveTo(Offset.lerp(from.$2, to.$2, step / 10)!);
      await tester.pump();
    }
    await one.up();
    await two.up();
    await tester.pumpAndSettle();
  }

  Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  /// Puts the focus in the book, as a click in it does.
  Future<void> focusBook(WidgetTester tester) async {
    await tester.tap(find.text('It begins.'));
    await tester.pumpAndSettle();
  }

  testWidgets('a pinch over the book zooms its text, and the size is kept', (
    tester,
  ) async {
    await session.setEpubLook(const EpubLook(font: EpubFont.mono));
    await pump(tester);
    final before = height(tester);
    final at = tester.getCenter(find.text('It begins.'));
    await twoFingers(
      tester,
      (at - const Offset(30, 0), at + const Offset(30, 0)),
      (at - const Offset(45, 0), at + const Offset(45, 0)),
    );
    expect(EpubLooks.look.textScale, 1.5, reason: 'half again as far apart');
    expect(await kept(), 1.5, reason: 'kept when the fingers lift');
    expect((await session.epubLook).font, EpubFont.mono, reason: 'the rest');
    expect(height(tester), greaterThan(before));
    await twoFingers(
      tester,
      (at - const Offset(60, 0), at + const Offset(60, 0)),
      (at - const Offset(20, 0), at + const Offset(20, 0)),
    );
    expect(await kept(), minTextScale, reason: 'held to the range');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the zoom keys step the size, Ctrl+0 puts it back', (
    tester,
  ) async {
    await pump(tester);
    await focusBook(tester);
    final before = height(tester);
    await ctrl(tester, LogicalKeyboardKey.equal);
    expect(EpubLooks.look.textScale, closeTo(1.1, 1e-9));
    expect(await kept(), closeTo(1.1, 1e-9));
    expect(height(tester), greaterThan(before));
    await ctrl(tester, LogicalKeyboardKey.minus);
    await ctrl(tester, LogicalKeyboardKey.minus);
    expect(await kept(), closeTo(0.9, 1e-9));
    await ctrl(tester, LogicalKeyboardKey.digit0);
    expect(await kept(), defaultTextScale);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a key past the end of the range leaves the size there', (
    tester,
  ) async {
    await session.setEpubLook(const EpubLook(textScale: maxTextScale));
    await pump(tester);
    await focusBook(tester);
    await ctrl(tester, LogicalKeyboardKey.equal);
    expect(await kept(), maxTextScale);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the keys zoom the book read over the whole screen', (
    tester,
  ) async {
    final fullScreen = ValueNotifier<Object?>(null);
    addTearDown(fullScreen.dispose);
    await pump(tester, fullScreen: fullScreen);
    await tester.tap(find.byKey(const Key('epub-full-screen-button')));
    await tester.pumpAndSettle();
    // The focus is the full screen's own, over the book: nothing tapped.
    await ctrl(tester, LogicalKeyboardKey.equal);
    expect(await kept(), closeTo(1.1, 1e-9));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a pane with no size to keep zooms nothing', (tester) async {
    await pump(tester, zooms: false);
    await focusBook(tester);
    await ctrl(tester, LogicalKeyboardKey.equal);
    final at = tester.getCenter(find.text('It begins.'));
    await twoFingers(
      tester,
      (at - const Offset(30, 0), at + const Offset(30, 0)),
      (at - const Offset(45, 0), at + const Offset(45, 0)),
    );
    expect(EpubLooks.look.textScale, defaultTextScale);
    expect(await kept(), defaultTextScale);
    await tester.pumpWidget(const SizedBox());
  });
}
