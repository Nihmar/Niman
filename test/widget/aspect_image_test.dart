// T-PP-22: an image reserves its box as soon as its dimensions are known,
// so the blocks below it do not jump when the bytes land — the jump that
// used to drag the scroll map's target away from the editor.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/preview/aspect_image.dart';
import 'package:niman/src/preview/decode_bound.dart';
import 'package:path/path.dart' as p;

/// A provider handing out an already-decoded test image.
final class _TestImageProvider extends ImageProvider<_TestImageProvider> {
  new(this.image);

  final ui.Image image;

  @override
  Future<_TestImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_TestImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    _TestImageProvider key,
    ImageDecoderCallback decode,
  ) {
    // A handle of its own: the image cache disposes what it holds when it
    // lets go, and the test disposes [image].
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.value(ImageInfo(image: image.clone())),
    );
  }
}

void main() {
  testWidgets('reserves the provider aspect ratio once dimensions land', (
    tester,
  ) async {
    // Decoding runs on the engine's task runner: outside the fake async
    // clock it only completes inside runAsync.
    final image = (await tester.runAsync(
      () => createTestImage(width: 40, height: 20),
    ))!;
    addTearDown(image.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: AspectImage(provider: _TestImageProvider(image)),
          ),
        ),
      ),
    );
    // The first frame lays the placeholder out and learns the width;
    // the decode at that width lands on the next.
    await tester.pump();
    await tester.pump();

    final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(ratio.aspectRatio, 2);
    // 200 wide, so the reserved box is 100 tall.
    expect(tester.getSize(find.byType(AspectImage)).height, 100);
  });

  // A picture in a table cell is asked its intrinsic width (the read view's
  // columns are `IntrinsicColumnWidth`), which a `LayoutBuilder` cannot
  // answer: the width the decode is bounded by is read after layout.
  testWidgets('answers an intrinsic query, as in a table cell', (tester) async {
    final image = (await tester.runAsync(
      () => createTestImage(width: 40, height: 20),
    ))!;
    addTearDown(image.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(
                children: [
                  SizedBox(
                    width: 200,
                    child: AspectImage(provider: _TestImageProvider(image)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio, 2);
    expect(tester.getSize(find.byType(AspectImage)), const Size(200, 100));
  });

  // 2026-09-10 device report: a portrait figure filled the whole preview
  // pane, and the prose around it went off screen.
  testWidgets('a tall image is capped, keeping its ratio', (tester) async {
    final image = (await tester.runAsync(
      () => createTestImage(width: 200, height: 1000),
    ))!;
    addTearDown(image.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: AspectImage(
              provider: _TestImageProvider(image),
              maxHeight: 300,
            ),
          ),
        ),
      ),
    );
    // The first frame lays the placeholder out and learns the width;
    // the decode at that width lands on the next.
    await tester.pump();
    await tester.pump();

    // At the pane's full width the box would be 2000 px tall. Capped, it
    // takes the height and derives the width from the ratio.
    final size = tester.getSize(find.byType(AspectRatio));
    expect(size.height, 300);
    expect(size.width, moreOrLessEquals(60, epsilon: 0.5));
  });

  testWidgets('a wide image is left alone by the cap', (tester) async {
    final image = (await tester.runAsync(
      () => createTestImage(width: 400, height: 100),
    ))!;
    addTearDown(image.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: AspectImage(
              provider: _TestImageProvider(image),
              maxHeight: 300,
            ),
          ),
        ),
      ),
    );
    // The first frame lays the placeholder out and learns the width;
    // the decode at that width lands on the next.
    await tester.pump();
    await tester.pump();

    final size = tester.getSize(find.byType(AspectRatio));
    expect(size.width, 400);
    expect(size.height, 100);
  });

  // #1194: a picture was decoded at its file's pixel size whatever it was
  // drawn at, so every picture of every mounted note stayed in memory whole.
  group('decodes at the drawn size', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('niman_aspect_'));
    tearDown(() => dir.deleteSync(recursive: true));

    /// Takes the picture down, and what the cache holds of it with it.
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      imageCache.clear();
      await tester.pump();
    }

    /// A PNG file of [width] x [height] pixels.
    Future<File> picture(WidgetTester tester, int width, int height) async {
      final bytes = await tester.runAsync(() async {
        final image = await createTestImage(width: width, height: height);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      return File(p.join(dir.path, '${width}x$height.png'))
        ..writeAsBytesSync(bytes!);
    }

    /// An 800 x 600 logical window at a pixel ratio of 2.
    void window(WidgetTester tester) {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(1600, 1200);
      addTearDown(tester.view.reset);
    }

    Future<void> mount(WidgetTester tester, File file, double width) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: AspectImage(provider: FileImage(file)),
            ),
          ),
        ),
      );
    }

    /// Lets the decode that is under way land: pumps in real time until
    /// the picture [reaches] the width asked for.
    Future<void> settle(WidgetTester tester, {int? reaches}) async {
      // The file's read and the codec run on real time.
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        final raw = find.byType(RawImage);
        if (raw.evaluate().isEmpty) continue;
        final image = tester.widget<RawImage>(raw).image;
        if (image != null && (reaches == null || image.width == reaches)) {
          return;
        }
      }
    }

    int decodedWidth(WidgetTester tester) =>
        tester.widget<RawImage>(find.byType(RawImage)).image!.width;

    testWidgets('a 4000 x 3000 picture drawn 400 wide at a ratio of 2', (
      tester,
    ) async {
      window(tester);
      final file = await picture(tester, 4000, 3000);
      await mount(tester, file, 400);
      await settle(tester);

      // Drawn 400 x 300 logical, so 800 x 600 physical: decoded within the
      // bound rounded up to a step, a fraction of the file's 4000 px.
      final bound = decodeBound(400, 2);
      expect(bound, 1024);
      final decoded = tester.widget<RawImage>(find.byType(RawImage)).image!;
      expect(decoded.width, lessThanOrEqualTo(bound));
      expect(decoded.height, lessThanOrEqualTo(decodeBound(300, 2)));
      expect(decoded.width, greaterThanOrEqualTo(800));
      // The box keeps the file's ratio.
      final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(ratio.aspectRatio, moreOrLessEquals(4 / 3, epsilon: 0.001));
      expect(tester.getSize(find.byType(AspectRatio)).width, 400);

      await unmount(tester);
    });

    testWidgets('a picture smaller than the box is not upscaled', (
      tester,
    ) async {
      window(tester);
      final file = await picture(tester, 120, 90);
      await mount(tester, file, 400);
      await settle(tester);

      expect(decodedWidth(tester), 120);

      await unmount(tester);
    });

    testWidgets('a width that moves keeps the box and the picture', (
      tester,
    ) async {
      window(tester);
      final file = await picture(tester, 4000, 500);
      await mount(tester, file, 400);
      await settle(tester);

      // 800 physical: the 1024 step.
      expect(decodedWidth(tester), 1024);
      final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(ratio.aspectRatio, 8);

      // Within the step (780 physical): the same decode, nothing to wait for.
      await mount(tester, file, 390);
      await tester.pump();
      expect(find.byType(AspectRatio), findsOneWidget);
      expect(
        tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
        8,
      );
      expect(decodedWidth(tester), 1024);

      // Across a step: decoded again, and the old frame stays up until the
      // new one lands — the placeholder never comes back.
      await mount(tester, file, 780);
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        expect(find.byType(AspectRatio), findsOneWidget);
        expect(find.byType(RawImage), findsOneWidget);
        expect(
          tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
          8,
        );
        if (decodedWidth(tester) == 1792) break;
      }
      // 1560 physical: the 1792 step.
      expect(decodedWidth(tester), 1792);
      expect(tester.getSize(find.byType(AspectRatio)), const Size(780, 97.5));

      await unmount(tester);
    });
  });

  test('a decode bound rounds the drawn size up to a step', () {
    expect(decodeBound(400, 2), 1024);
    expect(decodeBound(390, 2), 1024);
    expect(decodeBound(384, 2), 768);
    expect(decodeBound(128, 2), 256);
    expect(decodeBound(129, 2), 512);
    expect(decodeBound(780, 2), 1792);
    // Before layout: still a valid bound.
    expect(decodeBound(0, 2), decodeStep);
    expect(decodeBound(-5, 2), decodeStep);
    expect(decodeBound(double.nan, 2), decodeStep);
  });

  test('the cap follows the window, up to a limit', () {
    expect(maxImageHeight, 480);
  });
}
