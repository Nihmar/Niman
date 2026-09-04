// Benchmark spike for T-M2-00 (editor architecture decision) and the
// preview cost model. Prints timings; no assertions so it stays green on
// any machine — the numbers are read from the log, not enforced.
//
// Run: flutter test test/unit/m2_spike_benchmark_test.dart
//
// The whole point of this file is to print timings into the test log.
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' show Canvas, Offset, PictureRecorder;

import 'package:copist/src/editor/highlighting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

const String _fixturePath = 'test/fixtures/markdown/fixture-200kb.md';

double _msf(Duration d) => d.inMicroseconds / 1000.0;

/// Best of [n] runs.
Duration _best(int n, Duration Function() body) {
  var best = const Duration(days: 1);
  for (var i = 0; i < n; i++) {
    final d = body();
    if (d < best) best = d;
  }
  return best;
}

/// A styled span for one source line: token runs get a bold foreground,
/// the gaps are plain. Mirrors what the editor paint layer builds.
TextSpan _lineSpan(StyledLine line) {
  final text = line.text;
  final runs = <TextSpan>[];
  var pos = 0;
  for (final t in line.tokens) {
    if (t.start > pos) {
      runs.add(TextSpan(text: text.substring(pos, t.start)));
    }
    runs.add(TextSpan(
      text: text.substring(t.start, t.end),
      style: const TextStyle(fontWeight: FontWeight.bold),
    ));
    pos = t.end;
  }
  if (pos < text.length) {
    runs.add(TextSpan(text: text.substring(pos)));
  }
  return TextSpan(
    children: runs,
    style: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.5,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final raw = File(_fixturePath).readAsStringSync();
  final nLines = raw.split('\n').length;
  print('fixture: ${raw.length} chars, $nLines lines');

  // Warm the text engine (first layout loads the engine + default font).
  TextPainter(textDirection: TextDirection.ltr)
    ..text = const TextSpan(text: 'warmup')
    ..layout();

  group('T-M2-00 editor spike', () {
    late HighlightDocument doc;

    setUpAll(() {
      doc = HighlightDocument.fromText(raw);
    });

    test('tokenize full 200 KB', () {
      final d = _best(3, () {
        final sw = Stopwatch()..start();
        HighlightDocument.fromText(raw);
        sw.stop();
        return sw.elapsed;
      });
      print('  tokenize full:        ${_msf(d).toStringAsFixed(2)} ms');
    });

    test('incremental replace mid-buffer (one line changed)', () {
      final at = raw.length ~/ 2;
      final lineStart = raw.substring(0, at).lastIndexOf('\n') + 1;
      const snippet = 'replace-me';
      final original = raw.substring(lineStart, lineStart + 5);
      var best = const Duration(days: 1);
      for (var i = 0; i < 5; i++) {
        final sw = Stopwatch()..start();
        doc.replace(lineStart, lineStart + 5, snippet);
        sw.stop();
        if (sw.elapsed < best) best = sw.elapsed;
        doc.replace(lineStart, lineStart + snippet.length, original);
      }
      print('  incremental edit:     ${_msf(best).toStringAsFixed(3)} ms');
    });

    test('TextPainter per line (the real editor paint unit)', () {
      final lines = doc.lines;
      final spans = [for (final l in lines) _lineSpan(l)];
      final sw = Stopwatch()..start();
      for (final s in spans) {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        TextPainter(text: s, textDirection: TextDirection.ltr)
          ..layout()
          ..paint(canvas, Offset.zero);
        recorder.endRecording();
      }
      sw.stop();
      final perUs = sw.elapsed.inMicroseconds / lines.length;
      print(
          '  line layout+paint:    ${_msf(sw.elapsed).toStringAsFixed(1)} ms '
          'for ${lines.length} lines = ${perUs.toStringAsFixed(1)} us/line');
    });

    test('TextPainter whole buffer as one span (single-blob alternative)',
        () {
      final d = _best(1, () {
        final sw = Stopwatch()..start();
        TextPainter(
          text: TextSpan(
            text: raw,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          textDirection: TextDirection.ltr,
        ).layout();
        sw.stop();
        return sw.elapsed;
      });
      print('  whole-buffer layout:  ${_msf(d).toStringAsFixed(1)} ms');
    });
  });

  group('preview cost model', () {
    test('SmoothMarkdown parse (MarkdownParser only)', () {
      final parser = MarkdownParser();
      final d = _best(3, () {
        final sw = Stopwatch()..start();
        parser.parse(raw);
        sw.stop();
        return sw.elapsed;
      });
      print('  smooth parse:         ${_msf(d).toStringAsFixed(1)} ms');
    });

    testWidgets('SmoothMarkdown eager render (parse+build+layout+paint)',
        (tester) async {
      // First frame is the cost the preview pays per (debounced) re-render.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SmoothMarkdown(data: raw)),
          ),
        ),
      );
      await tester.pump(); // build + layout + paint
      sw.stop();
      print(
          '  smooth eager frame:   ${_msf(sw.elapsed).toStringAsFixed(1)} ms');
    });
  });
}
