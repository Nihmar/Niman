// Text on the canvas target (#530): a label centred in its box, as the
// SVG target centres it, and never wrapped again — the layout already broke
// it into lines, and a real face a little wider than the estimate it was
// measured with is still one line.
//
// The test face draws every glyph as a full square of its size, so where
// the ink is says where the text went.
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';

/// The ink's bounds once [lines] are drawn into [box] on a 200×60 canvas.
Future<Rect> _ink(List<String> lines, Rect box, {bool left = false}) async {
  final recorder = ui.PictureRecorder();
  CanvasDiagramTarget(ui.Canvas(recorder)).text(
    lines,
    box,
    color: const Color(0xFF000000),
    fontSize: 10,
    alignLeft: left,
  );
  final image = await recorder.endRecording().toImage(200, 60);
  final bytes = (await image.toByteData())!;
  var minX = 200;
  var maxX = -1;
  var minY = 60;
  var maxY = -1;
  for (var y = 0; y < 60; y++) {
    for (var x = 0; x < 200; x++) {
      if (bytes.getUint8((y * 200 + x) * 4 + 3) < 128) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  image.dispose();
  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    maxX + 1.0,
    maxY + 1.0,
  );
}

void main() {
  test('a label is centred in its box', () async {
    final ink = await _ink(['ab'], const Rect.fromLTWH(0, 0, 200, 20));
    expect(ink.width, closeTo(20, 1));
    expect(ink.center.dx, closeTo(100, 1));
  });

  test('a label set to the left starts at the box', () async {
    final ink = await _ink(
      ['ab'],
      const Rect.fromLTWH(30, 0, 140, 20),
      left: true,
    );
    expect(ink.left, closeTo(30, 1));
  });

  test('a line wider than its box stays one line, centred on it', () async {
    final ink = await _ink(['abcdef'], const Rect.fromLTWH(80, 0, 40, 20));
    expect(ink.height, lessThanOrEqualTo(12.5));
    expect(ink.width, closeTo(60, 1));
    expect(ink.center.dx, closeTo(100, 1));
  });
}
