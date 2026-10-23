/// Taking checkbox items out of a note, and putting them back (#1152).
///
/// Both are one edit of the note, computed against the buffer as it is now:
/// the items' lines go (with their line breaks, so no blank line is left
/// behind), and the text taken is kept so Undo can return it. Undo does not
/// replay the editor's history — the writer may have typed since — but looks
/// for where the lines stood: at the same place when the lines around it are
/// as they were, otherwise at the nearest place that is a start of a block.
library;

import 'dart:math' as math;

import 'package:niman/src/editor/task_items.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// One edit of a note: its text from `start` to `end` becomes `text`.
typedef NoteSpanEdit = ({int start, int end, String text});

/// What taking items out removed, to put it back.
final class TakenTaskItems {
  /// The [runs] of lines a take-out removed.
  const new(this.runs, this.count);

  /// The contiguous runs of lines removed, in note order.
  final List<TakenRun> runs;

  /// How many items were taken.
  final int count;
}

/// A run of removed lines, with the lines around it as they were.
final class TakenRun {
  /// A run whose removed [text] stood at line [line] of the note it was taken
  /// from, between the lines [before] and [after] (null at the note's ends).
  ///
  /// [leadingBreak]: the run was the note's last lines, so the line break
  /// before it went with it instead of the one after.
  const new({
    required this.text,
    required this.line,
    required this.before,
    required this.after,
    required this.leadingBreak,
  });

  /// The removed text, line breaks included, verbatim.
  final String text;

  /// The line the run stood at, once the runs above it were gone too.
  final int line;

  /// The line above the run, or null at the note's start.
  final String? before;

  /// The line below the run, or null at the note's end.
  final String? after;

  /// Whether [text] begins with a line break, not ends with one.
  final bool leadingBreak;
}

/// The edit that takes [items] out of [buffer], and what puts them back —
/// null when none of them is in [buffer] as it was read: an item stays unless
/// its lines are still where they were, word for word.
({NoteSpanEdit edit, TakenTaskItems taken})? takeOutTaskItems(
  SourceBuffer buffer,
  List<TaskItem> items,
) {
  final held = [
    for (final item in items)
      if (_isStillThere(buffer, item)) item,
  ]..sort((a, b) => a.line.compareTo(b.line));
  if (held.isEmpty) return null;
  // Items that follow each other are one run.
  final runs = <({int first, int end})>[];
  for (final item in held) {
    if (runs.isNotEmpty && runs.last.end >= item.line) {
      runs[runs.length - 1] = (
        first: runs.last.first,
        end: item.endLine > runs.last.end ? item.endLine : runs.last.end,
      );
    } else {
      runs.add((first: item.line, end: item.endLine));
    }
  }
  final ranges = <({int start, int end})>[];
  final taken = <TakenRun>[];
  var gone = 0;
  for (final run in runs) {
    final last = run.end >= buffer.lineCount;
    final leadingBreak = last && run.first > 0;
    final start = leadingBreak
        ? buffer.offsetOfLine(run.first - 1) +
              buffer.lineLengthAt(run.first - 1)
        : buffer.offsetOfLine(run.first);
    final end = last ? buffer.length : buffer.offsetOfLine(run.end);
    ranges.add((start: start, end: end));
    taken.add(
      TakenRun(
        text: buffer.substring(start, end),
        line: run.first - gone,
        before: run.first > 0 ? buffer.lineAt(run.first - 1) : null,
        after: last ? null : buffer.lineAt(run.end),
        leadingBreak: leadingBreak,
      ),
    );
    gone += run.end - run.first;
  }
  final pieces = StringBuffer();
  for (var i = 0; i + 1 < ranges.length; i++) {
    pieces.write(buffer.substring(ranges[i].end, ranges[i + 1].start));
  }
  return (
    edit: (start: ranges.first.start, end: ranges.last.end, text: '$pieces'),
    taken: TakenTaskItems(taken, held.length),
  );
}

/// Whether the lines of [item] are in [buffer] where they were.
bool _isStillThere(SourceBuffer buffer, TaskItem item) {
  if (item.line < 0 || item.line + item.raw.length > buffer.lineCount) {
    return false;
  }
  for (var at = 0; at < item.raw.length; at++) {
    if (buffer.lineAt(item.line + at) != item.raw[at]) return false;
  }
  return true;
}

/// The edit that puts [taken] back into [buffer], as it is now.
///
/// Each run goes where it stood when the lines around it still read as they
/// did; if they do not, to the nearest line after which the run's predecessor
/// stands, or before which its successor does, and failing that the nearest
/// line there is — always at the start of a block ([blockAt]), never inside
/// a code fence or a paragraph.
NoteSpanEdit? restoreTaskItems(
  SourceBuffer buffer,
  TakenTaskItems taken,
  Block? Function(int line) blockAt,
) {
  if (taken.runs.isEmpty) return null;
  bool atBoundary(int line) {
    if (line <= 0 || line >= buffer.lineCount) return true;
    final block = blockAt(line);
    return block == null || block.startLine == line;
  }

  bool after(TakenRun run, int line) =>
      line > 0 && buffer.lineAt(line - 1) == run.before;
  bool before(TakenRun run, int line) =>
      line < buffer.lineCount && buffer.lineAt(line) == run.after;
  bool ends(TakenRun run, int line) =>
      (run.before == null ? line == 0 : after(run, line)) &&
      (run.after == null ? line == buffer.lineCount : before(run, line));

  int nearest(TakenRun run, bool Function(int line) fits) {
    final from = math.min(run.line, buffer.lineCount);
    for (var d = 0; d <= _reach; d++) {
      for (final line in d == 0 ? [from] : [from - d, from + d]) {
        if (line < 0 || line > buffer.lineCount) continue;
        if (fits(line) && atBoundary(line)) return line;
      }
    }
    return -1;
  }

  final puts = <({int offset, String text})>[];
  for (final run in taken.runs) {
    var line = nearest(run, (at) => ends(run, at));
    if (line < 0 && run.before != null) {
      line = nearest(run, (at) => after(run, at));
    }
    if (line < 0 && run.after != null) {
      line = nearest(run, (at) => before(run, at));
    }
    if (line < 0) line = nearest(run, (_) => true);
    if (line < 0) line = math.min(run.line, buffer.lineCount);
    puts.add(_placed(buffer, run, line));
  }
  // Every run lands in the note as it stands, so one edit from the first
  // place to the last carries them all: the text between is kept as it is.
  puts.sort((a, b) => a.offset.compareTo(b.offset));
  final text = StringBuffer();
  for (var i = 0; i < puts.length; i++) {
    text.write(puts[i].text);
    if (i + 1 < puts.length) {
      text.write(buffer.substring(puts[i].offset, puts[i + 1].offset));
    }
  }
  return (start: puts.first.offset, end: puts.last.offset, text: '$text');
}

/// How many lines either side of where a run stood Undo looks for a place.
const int _reach = 5000;

/// Where [run] goes when it goes before [line], and the text to put there.
({int offset, String text}) _placed(
  SourceBuffer buffer,
  TakenRun run,
  int line,
) {
  final eol = buffer.eol;
  var text = run.text;
  if (line < buffer.lineCount) {
    if (run.leadingBreak) {
      // It stood last, with the break before it; it goes between lines, so
      // the break comes after it instead.
      text = '${text.substring(_breakLength(text))}$eol';
    }
    return (offset: buffer.offsetOfLine(line), text: text);
  }
  final last = buffer.lineCount - 1;
  final endOfLast = buffer.offsetOfLine(last) + buffer.lineLengthAt(last);
  if (!run.leadingBreak) {
    // It ended with its own break; at the end of a note whose last line has
    // none, that break goes before it.
    if (buffer.terminatorAt(last).isEmpty && buffer.lineLengthAt(last) > 0) {
      text = '$eol${text.substring(0, text.length - _trailingBreak(text))}';
    }
  }
  return (offset: endOfLast, text: text);
}

/// The length of the line break [text] begins with.
int _breakLength(String text) => text.startsWith('\r\n') ? 2 : 1;

/// The length of the line break [text] ends with.
int _trailingBreak(String text) {
  if (text.endsWith('\r\n')) return 2;
  return text.endsWith('\n') || text.endsWith('\r') ? 1 : 0;
}
