// The read view's first layout of a long side-by-side `columns` block,
// scrolled to its middle (#729, `docs/records/note-columns.md`, "Performance
// bars"): each column is windowed by a sliver of its own, so a block of
// 2 000 lines builds what the viewport shows, not the block.
//
// Every run holds the count — the blocks built stay within two viewports of
// them — which no hardware explains away. The time is a debug harness's
// (the ratios carry, the absolutes do not), so the bar a run asks for with
// `NIMAN_PERF=1` is a ratio: a block built in a column costs no more than
// 1.3 times one built in a note of the same paragraphs without columns,
// jumped to its middle the same way.

// The point of this file is to print its measurements into the test log.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// How much more a block built in a column may cost than one built in the
/// note's own run of blocks.
const double _ratio = 1.3;

/// [paragraphs] paragraphs a side, in two columns of one `columns` block
/// when [columns], one after the other otherwise.
String _note(int paragraphs, {required bool columns}) {
  final note = StringBuffer(columns ? ':::: columns\n::: column\n' : '');
  for (final side in ['Left', 'Right']) {
    if (columns && side == 'Right') note.writeln(':::\n::: column');
    for (var at = 0; at < paragraphs; at++) {
      note
        ..writeln('$side paragraph $at, a line of prose to wrap.')
        ..writeln();
    }
  }
  if (columns) note.writeln(':::\n::::');
  return note.toString();
}

/// The blocks built by the jump to [text]'s middle, and what it took.
Future<(int, Duration)> _jump(WidgetTester tester, String text) async {
  final controller = ScrollController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          key: UniqueKey(),
          buffer: SourceBuffer.fromText(text),
          parser: ReadParser(),
          mathCache: MathCache(
            renderer: (tex, {required displayMode}) => renderToBox(
              tex,
              options: KatexOptions(displayMode: displayMode),
            ),
          ),
          controller: controller,
        ),
      ),
    ),
  );
  final state = tester.state<MarkdownReadViewState>(
    find.byType(MarkdownReadView),
  );
  final first = state.builtBlocks;
  final clock = Stopwatch()..start();
  controller.jumpTo(controller.position.maxScrollExtent / 2);
  await tester.pump();
  clock.stop();
  return (state.builtBlocks - first, clock.elapsed);
}

void main() {
  testWidgets('a 2 000-line columns block, scrolled to its middle', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final text = _note(500, columns: true);
    expect(text.split('\n').length, greaterThan(2000));
    // Once each first, so neither pays for the parser's first use.
    await _jump(tester, _note(50, columns: false));
    await _jump(tester, _note(50, columns: true));
    final (plainBuilt, plainTook) = await _jump(
      tester,
      _note(500, columns: false),
    );
    final (built, took) = await _jump(tester, text);
    // A viewport of 800 px holds 800 / 21 rows of prose in each column; a
    // paragraph and its blank line are two blocks a row or more.
    final viewport = 2 * (800 / 21).ceil();
    final perBlock = took.inMicroseconds / built;
    final plainPerBlock = plainTook.inMicroseconds / plainBuilt;
    print(
      'columns read layout: ${took.inMilliseconds} ms, $built blocks built '
      '(${perBlock.round()} µs each); without columns '
      '${plainTook.inMilliseconds} ms, $plainBuilt built '
      '(${plainPerBlock.round()} µs each). Bar: ${2 * viewport} built; '
      '$_ratio x the cost a block under NIMAN_PERF',
    );
    expect(built, lessThanOrEqualTo(2 * viewport));
    if (Platform.environment['NIMAN_PERF'] == '1') {
      expect(perBlock, lessThanOrEqualTo(_ratio * plainPerBlock));
    }
  });
}
