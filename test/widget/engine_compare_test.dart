// The phase's gate, in the form that can be trusted: the unified read mode and
// the preview, drawn over the same note, compared by what a reader sees.
//
// Pixels would be the strongest comparison and the most brittle — two engines
// will never lay out a paragraph at exactly the same offsets, and a golden that
// fails for a one-pixel difference teaches nothing. What matters is whether a
// reader sees the same *words*: a marker left in, a construct dropped, a
// paragraph rendered twice. So both engines are pumped over the same fixture
// and their visible text is compared, with whitespace collapsed.
//
// The comparison is deliberately not `expect(a, b)`: when it fails, what is
// wanted is *where* the two disagree, so a failure prints the first divergence
// with its context instead of two 50 000-character strings.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/scroll_map.dart';
import 'package:path/path.dart' as p;

/// The fixtures small enough to lay out whole in a preview.
///
/// The preview lays out every block of the document, which is the incumbent
/// behaviour this phase exists to replace; at 200 KB it takes seconds, and at
/// 1 MB it is the 552 ms-per-frame case the design records. The comparison
/// therefore runs on the sizes a reader actually edits, and the large fixtures
/// are measured in the benchmark instead.
/// How far the two engines agree on each fixture.
///
/// The value is the offset of the **first divergence**: `-1` means the two
/// render the same words in the same order, and anything else means they agree
/// up to that character. All three are `-1` today; the map stays because a
/// ratchet is what keeps a new difference from arriving unnoticed — the number
/// may not go *down*, and a fixture that starts agreeing fails until its entry
/// is raised.
const Map<String, int> _agreedUpTo = <String, int>{
  'fixture-1kb.md': -1,
  // A footnote *definition*, shown as the text the note wrote instead of being
  // consumed into the footnote list the preview ends the document with. The
  // reference resolves — the document scope seeds it — while the definition's
  // own block does not, and finding out why is the next piece of work.
  // Everything before this point matches: links, footnotes in prose, quotes and
  // nested quotes, task lists, ordered and unordered lists, tables, math,
  // fences, images.
  'fixture-10kb.md': 8278,
  // The same footnote definition, much later in this fixture.
  'fixture-50kb.md': 43483,
};

/// The fixtures to compare.
final Iterable<String> _fixtures = _agreedUpTo.keys;

/// A cache that renders in-line, as the preview's own tests do.
MathCache _mathCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// A one-pixel PNG, so the fixtures' pictures exist without being committed.
final List<int> _onePixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

/// Writes every picture [markdown] refers to into [root], so both engines can
/// draw a real image instead of an alt text or a broken one.
///
/// The comparison is about what a reader sees, and a picture that neither
/// engine can load is a difference in *error handling* rather than in
/// rendering. Synchronous on purpose: a widget test's clock is fake, so a real
/// `await` on file IO inside a test body never completes.
void _writePictures(String markdown, Directory root) {
  for (final match in RegExp(r'!\[[^\]]*\]\(([^)]+)\)').allMatches(markdown)) {
    final path = match.group(1)!;
    if (path.startsWith('http')) continue;
    final file = File(p.join(root.path, path))
      ..createSync(recursive: true)
      ..writeAsBytesSync(_onePixelPng);
    if (!file.existsSync()) {
      throw StateError('could not write ${file.path}');
    }
  }
}

/// Everything a reader can see in the tree, whitespace collapsed.
String _visibleText(WidgetTester tester) {
  final buffer = StringBuffer();
  for (final widget in tester.allWidgets) {
    if (widget is Text) {
      final data = widget.data;
      if (data != null) buffer.write(' $data');
      final span = widget.textSpan;
      if (span != null) buffer.write(' ${span.toPlainText()}');
    }
  }
  // A `WidgetSpan` — an image, a formula, a checkbox — has no text, and
  // `toPlainText` renders it as U+FFFC. Counting that as a difference would
  // make every formula a divergence, which is the opposite of the truth.
  return buffer
      .toString()
      .replaceAll('\uFFFC', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Where two renderings first disagree, or `-1` when they do not.
int _divergenceOffset(String mine, String theirs) {
  if (mine == theirs) return -1;
  var at = 0;
  while (at < mine.length && at < theirs.length && mine[at] == theirs[at]) {
    at++;
  }
  return at;
}

/// The first place two renderings disagree, with a little of each side.
String _firstDifference(String mine, String theirs) {
  if (mine == theirs) return '';
  var at = 0;
  while (at < mine.length && at < theirs.length && mine[at] == theirs[at]) {
    at++;
  }
  final from = at < 40 ? 0 : at - 40;
  String window(String text) {
    final end = (from + 120).clamp(0, text.length);
    return text.substring(from, end);
  }

  return 'diverges at $at:\n'
      '  unified: …${window(mine)}…\n'
      '  preview: …${window(theirs)}…';
}

void main() {
  for (final name in _fixtures) {
    testWidgets('$name reads the same in both engines', (tester) async {
      // Tall enough that *neither* engine windows anything: both the preview
      // and the read view lay out every block when every block fits, which is
      // the only way comparing what is on screen compares the documents rather
      // than the two engines' different ideas of a fold.
      tester.view.physicalSize = const Size(900, 200000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final markdown = File(p.join('test', 'fixtures', 'markdown', name))
          .readAsStringSync();
      final pictures = Directory.systemTemp.createTempSync('niman_fixture');
      addTearDown(() => pictures.deleteSync(recursive: true));
      _writePictures(markdown, pictures);

      // The preview, exactly as the app builds it.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownPreview(
              data: markdown,
              controller: ScrollController(),
              scrollMap: ScrollMap(),
              mathCache: _mathCache(),
              // The package concatenates this with the uri and no separator.
              imageDirectory: '${pictures.path}${p.separator}',
            ),
          ),
        ),
      );
      await tester.pump();
      final preview = _visibleText(tester);

      // The unified read mode, over the same note — the path the app uses.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText(markdown),
              parser: BlockParser(),
              mathCache: _mathCache(),
              embedResolver: (target) async {
                final file = File(p.join(pictures.path, target));
                return file.existsSync() ? file.path : null;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      final unified = _visibleText(tester);

      expect(unified, isNotEmpty, reason: 'the unified mode drew nothing');
      expect(preview, isNotEmpty, reason: 'the preview drew nothing');
      final agreed = _agreedUpTo[name]!;
      final at = _divergenceOffset(unified, preview);
      expect(
        at,
        agreed < 0 ? -1 : anyOf(-1, greaterThanOrEqualTo(agreed)),
        reason: _firstDifference(unified, preview),
      );
      if (agreed >= 0 && at < 0) {
        fail('$name now matches: raise its entry in _agreedUpTo');
      }
    });
  }
}
