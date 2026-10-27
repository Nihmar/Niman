// An attachment picked in the tree is shown in the note pane: a picture
// zoomed and panned, a PDF page by page, a book read like a note (its own
// test: epub_pane_test.dart). (The PDF is drawn by PDFium, a
// native library a widget test cannot load: its viewer is left to the
// device, and only which files it takes is held here.)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/attachment_picture.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:path/path.dart' as p;

void main() {
  test('the files the pane shows itself', () {
    for (final name in ['a.png', 'b.JPG', 'c.jpeg', 'd.gif', 'e.webp']) {
      expect(isShownAttachment(name), isTrue, reason: name);
    }
    expect(isShownAttachment('Docs/Paper.PDF'), isTrue);
    expect(isShownAttachment('Books/Novel.EPUB'), isTrue);
    for (final name in ['a.md', 'todo.txt', 'c.zip', 'noext']) {
      expect(isShownAttachment(name), isFalse, reason: name);
    }
  });

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('niman_attach_'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester, String path) async {
    // Mounted with real time: the picture's read is real I/O, and started
    // in the test's fake time it never ends — the file stays open, which
    // Windows will not delete, and a bad picture never reports.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentView(path: path)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    imageCache.clear();
  }

  testWidgets('a picture is shown, zoomable, with its name', (tester) async {
    final png = await tester.runAsync(() async {
      final image = await createTestImage(width: 4, height: 3);
      return (await image.toByteData(format: ui.ImageByteFormat.png))!;
    });
    final file = File(p.join(dir.path, 'photo.png'))
      ..writeAsBytesSync(png!.buffer.asUint8List());
    await pump(tester, file.path);
    expect(find.byKey(const Key('attachment-picture')), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('photo.png'), findsOneWidget);
    expect(find.byKey(const Key('attachment-unreadable')), findsNothing);
    await unmount(tester);
  });

  // #1194: the viewer decoded the file at its own size, however small the
  // pane, and kept every pixel of it for as long as the note was open.
  group('decodes at the size it is seen at', () {
    /// An 800 x 600 logical window at a pixel ratio of 1.
    void window(WidgetTester tester) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.reset);
    }

    Future<File> picture(WidgetTester tester) async {
      final bytes = await tester.runAsync(() async {
        final image = await createTestImage(width: 4000, height: 3000);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      return File(p.join(dir.path, 'big.png'))..writeAsBytesSync(bytes!);
    }

    /// Lets the decode that is under way land: pumps in real time until
    /// the picture [reaches] a width past [above].
    Future<void> settle(WidgetTester tester, {int above = 0}) async {
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        final raw = find.byType(RawImage);
        if (raw.evaluate().isEmpty) continue;
        final image = tester.widget<RawImage>(raw).image;
        if (image != null && image.width > above) return;
      }
    }

    int decodedWidth(WidgetTester tester) =>
        tester.widget<RawImage>(find.byType(RawImage)).image!.width;

    testWidgets('the viewport at first, the zoom it settles on after', (
      tester,
    ) async {
      window(tester);
      final file = await picture(tester);
      await pump(tester, file.path);
      await settle(tester);

      // 800 px wide, and the bar under it takes some of the 600: the
      // bound is the 1024 x 768 step, a quarter of the file's width.
      final first = decodedWidth(tester);
      expect(first, lessThanOrEqualTo(1024));
      expect(first, greaterThanOrEqualTo(700));

      // A pinch that spreads two fingers x3.8 apart settles the zoom at 4:
      // four times the pixels.
      final center = tester.getCenter(
        find.byKey(const Key('attachment-picture')),
      );
      final left = await tester.startGesture(
        center - const Offset(50, 0),
        pointer: 1,
      );
      final right = await tester.startGesture(
        center + const Offset(50, 0),
        pointer: 2,
      );
      await left.moveTo(center - const Offset(190, 0));
      await right.moveTo(center + const Offset(190, 0));
      await left.up();
      await right.up();
      await tester.pump();
      await settle(tester, above: first);

      final zoomed = decodedWidth(tester);
      expect(zoomed, greaterThan(2 * first));
      expect(zoomed, lessThanOrEqualTo(3328));
      // Never beyond the file's own pixels.
      expect(zoomed, lessThanOrEqualTo(4000));
      await unmount(tester);
    });

    test('a zoom decodes at the next power of two, up to the limit', () {
      expect(zoomDecodeScale(0.5), 1);
      expect(zoomDecodeScale(1), 1);
      expect(zoomDecodeScale(1.01), 2);
      expect(zoomDecodeScale(2), 2);
      expect(zoomDecodeScale(3.86), 4);
      expect(zoomDecodeScale(4), 4);
      expect(zoomDecodeScale(5), 8);
      expect(zoomDecodeScale(16), 16);
      expect(zoomDecodeScale(100), 16);
      expect(zoomDecodeScale(double.nan), 1);
    });
  });

  testWidgets('a picture that does not decode says so', (tester) async {
    final file = File(p.join(dir.path, 'broken.png'))
      ..writeAsStringSync('not a picture');
    await pump(tester, file.path);
    expect(find.byKey(const Key('attachment-unreadable')), findsOneWidget);
    await unmount(tester);
  });
}
