// The read view, as pixels (phase 2 of docs/dev/unified-surface.md asked for
// a golden image per fixture, and none was made until 2026-09-23).
//
// The other read-view tests hold properties — the blocks built, the text on
// screen, the heights — and each can pass while the page is wrong: a block
// clipped at its estimate still has its words in the widget tree, and that is
// how #250 reached a device. An image of the page says what the reader sees.
//
// The text is drawn in the test font (every glyph a box), so the images pin
// the layout — where each block, row, bullet, bar, cell and formula is — and
// not a platform's font rendering. They are compared forgiving a faint
// difference on an edge, where the antialiasing of the host that made them
// and of the Linux runner of CI may part, and nothing more.
//
// After a change that moves the page on purpose, look at the failure images
// the run writes next to this file, then refresh the goldens with
// `flutter test --update-goldens test/widget/read_view_golden_test.dart`.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/theme/palettes.dart';

/// A comparator that forgives a faint difference on an edge and nothing
/// else: a pixel counts as different when a channel moved by more than
/// [_faint], and more than [_allowed] such pixels fail the image.
///
/// A share of the pixels would not do: 1 % of this page is 15 000 pixels,
/// and a quote's bar or a bullet gone is a few hundred.
final class _EdgeTolerantComparator extends LocalFileComparator {
  new(super.testFile);

  static const int _faint = 64;
  static const int _allowed = 16;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final expected = Uint8List.fromList(await getGoldenBytes(golden));
    if (await _alike(imageBytes, expected)) return true;
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      expected,
    );
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }

  static Future<bool> _alike(Uint8List a, Uint8List b) async {
    final first = await _pixels(a);
    final second = await _pixels(b);
    if (first.width != second.width || first.height != second.height) {
      return false;
    }
    var different = 0;
    for (var at = 0; at < first.bytes.length; at += 4) {
      for (var channel = 0; channel < 4; channel++) {
        final delta = first.bytes[at + channel] - second.bytes[at + channel];
        if (delta.abs() > _faint) {
          if (++different > _allowed) return false;
          break;
        }
      }
    }
    return true;
  }

  static Future<({int width, int height, Uint8List bytes})> _pixels(
    Uint8List png,
  ) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData();
    final out = (
      width: image.width,
      height: image.height,
      bytes: data!.buffer.asUint8List(),
    );
    image.dispose();
    codec.dispose();
    return out;
  }
}

/// A cache that typesets in line, so a formula is on the first frame.
MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

String _fixture(String name) =>
    File('test/fixtures/markdown/$name').readAsStringSync();

void main() {
  setUpAll(() {
    final base = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = _EdgeTolerantComparator(
      base.resolve('read_view_golden_test.dart'),
    );
  });

  /// Draws [text] in the read view at [size], lets it settle, and compares
  /// it with the golden [name]. [before] runs on the view first — a jump.
  Future<void> page(
    WidgetTester tester,
    String name,
    String text, {
    Size size = const Size(800, 1000),
    Brightness brightness = Brightness.light,
    Future<void> Function(MarkdownReadViewState view)? before,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cache = _syncCache();
    addTearDown(cache.dispose);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(
          const BuiltinAppTheme(AppPalette.catppuccin),
          brightness,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('page'),
            child: MarkdownReadView(
              buffer: SourceBuffer.fromText(text),
              parser: BlockParser(),
              mathCache: cache,
              controller: controller,
              embedResolver: (_) async => null,
            ),
          ),
        ),
      ),
    );
    // The formulas are typeset in line but handed over a microtask later,
    // and a jump corrects itself over a few frames.
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump();
    }
    if (before != null) {
      await before(
        tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView)),
      );
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump();
      }
    }
    await expectLater(
      find.byKey(const Key('page')),
      matchesGoldenFile('goldens/read/$name.png'),
    );
  }

  testWidgets('every construct, light', (tester) async {
    await page(
      tester,
      'constructs_light',
      _fixture('constructs.md'),
      size: const Size(800, 1900),
    );
  });

  testWidgets('every construct, dark', (tester) async {
    await page(
      tester,
      'constructs_dark',
      _fixture('constructs.md'),
      size: const Size(800, 1900),
      brightness: Brightness.dark,
    );
  });

  testWidgets('a narrow page wraps, and nothing runs past its edge', (
    tester,
  ) async {
    await page(
      tester,
      'constructs_narrow',
      _fixture('constructs.md'),
      size: const Size(360, 2600),
    );
  });

  testWidgets('the 10 KB fixture, first screen', (tester) async {
    await page(tester, 'fixture_10kb_top', _fixture('fixture-10kb.md'));
  });

  testWidgets('the 1 MB fixture, first screen', (tester) async {
    await page(tester, 'fixture_1mb_top', _fixture('fixture-1mb.md'));
  });

  testWidgets('the 1 MB fixture, after a jump to its middle', (tester) async {
    // Where the estimates are and the measurements are not: the page a jump
    // lands on is laid out for the first time, which is where a block used
    // to be clipped at its estimated height (#250).
    final text = _fixture('fixture-1mb.md');
    final middle = SourceBuffer.fromText(text).lineCount ~/ 2;
    await page(
      tester,
      'fixture_1mb_middle',
      text,
      before: (view) async => view.jumpToLine(middle),
    );
  });

  testWidgets('the adversarial note, first screen', (tester) async {
    await page(
      tester,
      'worst_note_top',
      File('test/fixtures/spec/worst-note.md').readAsStringSync(),
    );
  });
}
