/// Where a card's pieces stand in the note: the maps of the read view's
/// inline text, put back on the note's offsets (#533).
library;

import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_map.dart';

/// `[from, to)` of an inline text, trimmed of white space, as the stretch of
/// the note it was read from; null when nothing is left, or when its ends
/// are no character of the note.
NoteRange? noteRange(
  SourceMap map,
  SourceBuffer buffer,
  String text,
  int from,
  int to,
) {
  var start = from;
  var end = to;
  while (start < end && _blank(text.codeUnitAt(start))) {
    start++;
  }
  while (end > start && _blank(text.codeUnitAt(end - 1))) {
    end--;
  }
  if (start >= end) return null;
  final first = map.positionOf(start);
  final last = map.positionOf(end - 1);
  if (first == null || last == null) return null;
  return (
    start: buffer.offsetAt(first.line, first.column),
    end: buffer.offsetAt(last.line, last.column) + 1,
  );
}

/// The source of a card written on [spans] of [buffer], lines and content;
/// [question] and [answer] where they stand.
CardSource sourceOf(
  SourceBuffer buffer,
  List<SourceSpan> spans, {
  NoteRange? question,
  NoteRange? answer,
  int? questionColumn,
  int? answerColumn,
}) {
  final first = spans.first;
  final last = spans.last;
  return CardSource(
    firstLine: first.line,
    lastLine: last.line,
    content: (
      start: buffer.offsetAt(first.line, first.start),
      end: buffer.offsetAt(last.line, last.end),
    ),
    lines: (
      start: buffer.offsetOfLine(first.line),
      end: buffer.offsetOfLine(last.line) + buffer.lineLengthAt(last.line),
    ),
    question: question,
    answer: answer,
    questionColumn: questionColumn,
    answerColumn: answerColumn,
    lineContents: spans.length == 1
        ? const <NoteRange>[]
        : [
            for (final span in spans)
              (
                start: buffer.offsetAt(span.line, span.start),
                end: buffer.offsetAt(span.line, span.end),
              ),
          ],
  );
}

bool _blank(int unit) => unit == 0x20 || unit == 0x09 || unit == 0x0A;
