import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/live_quote_runs.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

const String _note = '''
Top.

> :::: columns
> ::: column
> Left
> :::
>
> ::: column
> Right
> :::
> ::::

Middle.

> A plain quote.

Bottom.''';

Iterable<Block> _quotes(SourceBuffer buffer) =>
    BlockScanner(buffer).index.blocks
        .where((block) => block.kind == BlockKind.quote);

/// The runs [runs] has for [buffer]'s quotes after [edit], which it
/// follows.
List<LiveRun> _after(LiveQuoteRuns runs, SourceBuffer buffer, SourceEdit edit) {
  runs.edited(edit);
  return runs.of(_quotes(buffer), buffer);
}

/// The runs a fresh read of [buffer]'s quotes finds, by their lines.
List<String> _fresh(SourceBuffer buffer) =>
    LiveRun.inQuotes(_quotes(buffer), buffer).map(_lines).toList();

String _lines(LiveRun run) =>
    '${run.start}-${run.end} '
    '${[for (final column in run.columns) '${column.start}-${column.end}']}';

void main() {
  test('an edit away from a quote reads no quote again', () {
    final buffer = SourceBuffer.fromText(_note);
    final runs = LiveQuoteRuns();
    final first = runs.of(_quotes(buffer), buffer).single;
    final at = buffer.offsetOfLine(buffer.lineCount - 1);
    final again = _after(runs, buffer, buffer.replaceRange(at, at, 'More. '));
    expect(identical(again.single, first), isTrue, reason: 'the reading kept');
  });

  test('an edit above a quote moves its runs with the lines', () {
    final buffer = SourceBuffer.fromText(_note);
    final runs = LiveQuoteRuns()..of(_quotes(buffer), buffer);
    final moved = _after(runs, buffer, buffer.replaceRange(0, 0, 'New.\n\n'));
    expect(moved.map(_lines), _fresh(buffer));
    expect(moved.single.start, 4);
  });

  test('an edit inside a quote reads it again', () {
    final buffer = SourceBuffer.fromText(_note);
    final runs = LiveQuoteRuns()..of(_quotes(buffer), buffer);
    final at = buffer.offsetOfLine(4) + '> Left'.length;
    final grown = _after(
      runs,
      buffer,
      buffer.replaceRange(at, at, '\n> more left'),
    );
    expect(grown.map(_lines), _fresh(buffer));
    // Its columns undone: no run.
    final opener = buffer.offsetOfLine(2);
    final undone = _after(
      runs,
      buffer,
      buffer.replaceRange(opener, opener + 2, ''),
    );
    expect(undone, isEmpty);
    expect(_fresh(buffer), isEmpty);
  });

  test('a change no edit told of reads every quote again', () {
    final buffer = SourceBuffer.fromText(_note);
    final runs = LiveQuoteRuns()..of(_quotes(buffer), buffer);
    buffer.replaceRange(0, 0, 'Untold.\n\n');
    expect(runs.of(_quotes(buffer), buffer).map(_lines), _fresh(buffer));
  });
}
