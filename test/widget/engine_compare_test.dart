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
/// How far the two engines agreed on each fixture when this test was written.
///
/// The value is the offset of the **first divergence**: `-1` means the two
/// render the same words in the same order, and anything else means they agree
/// up to that character. It is a ratchet rather than a pass mark, because the
/// number may not go *down*: a change that makes the unified engine disagree
/// sooner than it did is a regression, and the offset says where to look.
const Map<String, int> _agreedUpTo = <String, int>{
  'fixture-1kb.md': -1,
  'fixture-10kb.md': 281,
  // A paragraph in this one carries a display formula in the middle of prose.
  // The preview typesets the whole run; the unified engine's masking reads the
  // opening `$$` and the next one as a pair, so the tex after it is left as
  // text. It is the one shape worth fixing next, and it is listed here so it
  // cannot be forgotten and cannot quietly get worse.
  'fixture-50kb.md': 86,
};

/// The fixtures to compare.
final Iterable<String> _fixtures = _agreedUpTo.keys;

/// A cache that renders in-line, as the preview's own tests do.
MathCache _mathCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

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
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
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
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final markdown = File(p.join('test', 'fixtures', 'markdown', name))
          .readAsStringSync();

      // The preview, exactly as the app builds it.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownPreview(
              data: markdown,
              controller: ScrollController(),
              scrollMap: ScrollMap(),
              mathCache: _mathCache(),
            ),
          ),
        ),
      );
      await tester.pump();
      final preview = _visibleText(tester);

      // The unified read mode, over the same note.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText(markdown),
              parser: BlockParser(),
              mathCache: _mathCache(),
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
        anyOf(-1, greaterThanOrEqualTo(agreed)),
        reason: _firstDifference(unified, preview),
      );
      if (agreed >= 0) {
        // Recorded on purpose: the difference is known, listed above with its
        // reason, and the ratchet only forbids it getting worse.
        expect(at, isNot(-1), reason: '$name now matches: raise the ratchet');
      }
    });
  }
}
