/// The `columns` blocks inside the note's quotes that `live` draws (#729):
/// each quote's content read again once, and kept until an edit touches
/// the quote, so a keystroke elsewhere reads no quote's lines.
library;

import 'dart:collection';

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// One quote's reading: the quote block as it stands — its lines, and the
/// list item and footnote definition it is in or not, which decide whether
/// its columns are drawn — the line its runs were read at, and the runs,
/// none for a quote that holds no `columns` block.
typedef _Reading = ({Block quote, int readAt, List<LiveRun> runs});

/// The runs of the note's quotes, by quote.
final class LiveQuoteRuns {
  /// Each quote read, by its first line as the note stands at [_revision].
  SplayTreeMap<int, _Reading> _byStart = SplayTreeMap<int, _Reading>();

  /// The buffer revision the readings follow; -1 for none.
  int _revision = -1;

  /// The runs in [quotes] — the note's quote blocks, in order — of
  /// [buffer]: a quote is read again only when no reading of it stands,
  /// at its lines, since the edits [edited] followed.
  List<LiveRun> of(Iterable<Block> quotes, SourceBuffer buffer) {
    // A change no edit told of: every reading may be of other lines.
    if (_revision != buffer.revision) _byStart.clear();
    final kept = SplayTreeMap<int, _Reading>();
    final runs = <LiveRun>[];
    for (final quote in quotes) {
      final had = _byStart[quote.startLine];
      final reading =
          had != null &&
              had.quote.endLine == quote.endLine &&
              had.quote.sameShape(quote)
          ? had
          : (
              quote: quote,
              readAt: quote.startLine,
              runs: LiveRun.inQuotes([quote], buffer),
            );
      kept[quote.startLine] = reading;
      for (final run in reading.runs) {
        runs.add(run.shifted(quote.startLine - reading.readAt));
      }
    }
    _byStart = kept;
    _revision = buffer.revision;
    return runs;
  }

  /// Follows [edit]: a quote above it keeps its reading, one after it
  /// moves with the lines, and one it touched is read again.
  void edited(SourceEdit edit) {
    if (edit.revision == _revision) return;
    if (edit.revision != _revision + 1) {
      _byStart.clear();
      _revision = -1;
      return;
    }
    final first = edit.firstLine;
    final untouched = edit.firstUntouchedLine;
    final moved = SplayTreeMap<int, _Reading>();
    for (final MapEntry(key: start, value: reading) in _byStart.entries) {
      if (start >= untouched) {
        moved[start + edit.lineDelta] = (
          quote: reading.quote.shifted(edit.lineDelta),
          readAt: reading.readAt,
          runs: reading.runs,
        );
      } else if (reading.quote.endLine <= first) {
        moved[start] = reading;
      }
    }
    _byStart = moved;
    _revision = edit.revision;
  }
}
