/// Measures a note's statistics both ways, on the real [SourceBuffer].
///
/// The old shape: join the note, copy it to an isolate, count its words there
/// and walk it again for its headings. The new one
/// (`lib/src/editor/word_count_index.dart` and `outlineOfBlocks`): the count
/// is kept per line and follows the edits, and the headings are read off the
/// blocks the styling already scanned.
///
/// The claim it checks is the one `docs/dev/huge-notes.md` records: on the
/// 247 MB note a refresh was 190 ms of join on the UI isolate plus about
/// 1.4 s of isolate work, and it is now a lookup — with the count built once,
/// in the background, and an edit paying for the lines it touched.
///
/// It prints rather than asserts, as the repo's benchmarks do, and JIT
/// inflates the absolutes — the shape carries.
///
/// ```sh
/// dart run tool/stats_bench.dart
/// dart run tool/stats_bench.dart "Quicknote.md"
/// ```
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

Future<void> main(List<String> args) async {
  final path = args.isEmpty ? 'Quicknote.md' : args.first;
  final raw = await File(path).readAsString();
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final buffer = SourceBuffer.fromText(text);
  print('$path: ${text.length} chars, ${buffer.lineCount} lines');

  _old(buffer, text);
  final words = _new(buffer);
  _refresh(buffer, words);
  _edits(buffer);
}

/// The join, the copy, the word walk and the heading walk.
void _old(SourceBuffer buffer, String text) {
  var clock = Stopwatch()..start();
  final joined = buffer.text;
  final joinMs = clock.elapsedMilliseconds;
  clock = Stopwatch()..start();
  final words = countWords(joined);
  final countMs = clock.elapsedMilliseconds;
  clock = Stopwatch()..start();
  final outline = outlineOfText(joined);
  final outlineMs = clock.elapsedMilliseconds;
  print(
    'OLD  join ${joinMs}ms + count ${countMs}ms + outline ${outlineMs}ms '
    '= ${joinMs + countMs + outlineMs}ms of one refresh on the UI isolate '
    '($words words, ${outline.length} headings)',
  );
}

/// The count kept per line, and the headings read off a scan.
WordCount _new(SourceBuffer buffer) {
  var clock = Stopwatch()..start();
  final words = WordCount.of(buffer);
  final adoptMs = clock.elapsedMilliseconds;
  clock = Stopwatch()..start();
  final blocks = BlockScanner(buffer).index;
  final scanMs = clock.elapsedMilliseconds;
  final headings = outlineOfBlocks(blocks, buffer.lineAt);
  final outlineMs = clock.elapsedMilliseconds - scanMs;
  print(
    'NEW  count once ${adoptMs}ms (then O(1) per refresh) + scan ${scanMs}ms '
    '+ outline ${outlineMs}ms = ${adoptMs + scanMs + outlineMs}ms once '
    '(${words.words} words, ${headings.length} headings)',
  );
  return words;
}

/// What a refresh pays once the count and the scan are there: an O(1) total,
/// the headings read off the scan the pane already holds, and the
/// frontmatter's error from the note's first lines only.
void _refresh(SourceBuffer buffer, WordCount words) {
  final scanned = BlockScanner(buffer).index;
  var clock = Stopwatch()..start();
  final count = words.words;
  final countMs = clock.elapsedMilliseconds;
  clock = Stopwatch()..start();
  final headings = outlineOfBlocks(scanned, buffer.lineAt);
  final outlineMs = clock.elapsedMilliseconds;
  clock = Stopwatch()..start();
  final head = StringBuffer();
  for (
    var line = 0;
    line < buffer.lineCount && head.length < 8 * 1024;
    line++
  ) {
    head
      ..write(buffer.lineAt(line))
      ..write(buffer.terminatorAt(line));
  }
  final frontmatterMs = clock.elapsedMilliseconds;
  print(
    'NEW  a refresh: count ${countMs}ms + outline ${outlineMs}ms + '
    'frontmatter ${frontmatterMs}ms = '
    '${countMs + outlineMs + frontmatterMs}ms '
    '($count words, ${headings.length} headings)',
  );
}

/// What one edit costs the count, at three shapes of edit.
void _edits(SourceBuffer buffer) {
  final words = WordCount.of(buffer);
  final middle = buffer.lineCount ~/ 2;

  var clock = Stopwatch()..start();
  var edit = buffer.replaceRange(
    buffer.offsetOfLine(middle),
    buffer.offsetOfLine(middle) + 1,
    'X',
  );
  words.edited(edit, buffer);
  print('NEW  a character: ${clock.elapsedMilliseconds}ms');

  clock = Stopwatch()..start();
  edit = buffer.insert(buffer.offsetOfLine(middle), 'a new line\n');
  words.edited(edit, buffer);
  print('NEW  an Enter: ${clock.elapsedMilliseconds}ms');

  clock = Stopwatch()..start();
  final breakAt = buffer.offsetOfLine(middle) - 1;
  edit = buffer.delete(breakAt, breakAt + 1);
  words.edited(edit, buffer);
  print('NEW  a line join: ${clock.elapsedMilliseconds}ms');
}
