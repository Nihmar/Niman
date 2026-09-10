// T-PP-22: an image reserves its box as soon as its dimensions are known,
// so the blocks below it do not jump when the bytes land — the jump that
// used to drag the scroll map's target away from the editor.
import 'dart:ui' as ui;

import 'package:copist/src/preview/aspect_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.value(ImageInfo(image: image)),
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
    await tester.pump();

    final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(ratio.aspectRatio, 2);
    // 200 wide, so the reserved box is 100 tall.
    expect(tester.getSize(find.byType(AspectImage)).height, 100);
  });
}
