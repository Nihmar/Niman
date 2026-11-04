import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/live_quote_runs.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/render/source_folds.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// The rows the source view draws and the heights it places them with: one
/// row per line nobody has folded away, a side-by-side `columns` block's
/// lines drawn in its opener's row (#729), and the height map over them —
/// estimated before a frame has drawn a row, kept as drawn after.
///
/// The view owns it and asks it for [heights]; the folds and the blocks
/// laid out side by side are the view's, handed in, and so is what the
/// estimates are counted in.
final class SourceRows {
  /// The rows of [_buffer]'s note, as [_folds] and [_hosts] leave them.
  new({
    required this._buffer,
    required this._live,
    required this._styler,
    required this._folds,
    required this._hosts,
    required this._sectionEnd,
    required this._em,
    required this._rowHeight,
    required this._gap,
    required this._band,
    required this._columnsPerLine,
    required this._itemsIndent,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// Whether the view draws `live`, where `columns` blocks are laid out.
  final bool Function() _live;

  /// The colours, whose scan says where the `columns` blocks are.
  final SourceStyler? Function() _styler;

  /// The folded sections, and the rows they leave.
  final SourceFolds _folds;

  /// The blocks drawn side by side at the pane's width (#729).
  final LiveHosts _hosts;

  /// Where the section under a heading ends, for the folds an edit moves.
  final int? Function(int line) _sectionEnd;

  /// An em of the note's text, as drawn.
  final double Function() _em;

  /// One row's height as the lines are drawn.
  final double Function() _rowHeight;

  /// The room between two columns, and between two rows of them.
  final double Function() _gap;

  /// A fence line's band, as drawn.
  final double Function() _band;

  /// Roughly how many monospace characters fit a line.
  final double Function() _columnsPerLine;

  /// How far the list items and the quote a run stands in indent its
  /// columns.
  final double Function(LiveRun run) _itemsIndent;

  /// The heights the sliver places the rows with: one per line nobody has
  /// folded away.
  BlockHeightMap get heights => _heights;
  late BlockHeightMap _heights;

  /// The `columns` blocks in the note's quotes, each quote read once until
  /// an edit touches it.
  final LiveQuoteRuns _quoteRuns = LiveQuoteRuns();

  /// The note's outermost `columns` blocks, by line (#729), as of
  /// [_runsRevision]; read again when the buffer moves on.
  List<LiveRun> _runs = const <LiveRun>[];
  int _runsRevision = -1;

  /// Whether a layout asked for [liveRuns] while the scan owed part of the
  /// note, and drew the blocks past what it had read stacked: the scan
  /// settling owes it a layout.
  bool get runsOwed => _runsOwed;
  bool _runsOwed = false;

  /// How many lines [_estimate] was asked about, for the test that holds a
  /// note with a side-by-side block (#729) to the chunks a frame reaches.
  int lineEstimates = 0;

  /// The outermost `columns` blocks `live` draws, read off the scan's fence
  /// lines: none in `source`, and while the scan owes part of the note only
  /// the ones that open where it has read — its blocks past that are hints.
  /// That answer is not kept: the scan settles at the same revision.
  List<LiveRun> get liveRuns {
    if (!_live()) return const <LiveRun>[];
    final buffer = _buffer();
    final revision = buffer.revision;
    if (revision == _runsRevision) return _runs;
    final styler = _styler();
    final fences = styler?.divBlocks;
    final quotes = styler?.fenceQuoteBlocks;
    if (styler == null || fences == null || quotes == null) {
      _runsOwed = styler != null;
      return const <LiveRun>[];
    }
    // The note's own, and the ones in its quotes and callouts, read off
    // each quote's content. An opener the scan has read is followed to its
    // closer: the blocks on the way are caught up as they are asked for.
    final runs = [
      ...LiveRun.of(fences, styler.blockOf, buffer.lineAt),
      ..._quoteRuns.of(quotes, buffer),
    ]..sort((a, b) => a.start.compareTo(b.start));
    _runsOwed = !styler.settled;
    if (_runsOwed) return runs;
    _runs = runs;
    _runsRevision = revision;
    return _runs;
  }

  /// The heights measured again from the note as it is: another note, or
  /// this one changed behind the view's back.
  void rebuild() => _heights = _map();

  /// Keeps the height map at the buffer's line count, after [edit].
  ///
  /// The view draws the buffer's lines and places them with the map, so the
  /// three have to agree about how many there are. When the count changed the
  /// map is **spliced** — the lines the edit replaced go, the ones it added
  /// come in estimated, and every other line keeps the height a frame measured
  /// — because rebuilding it moved everything on screen on every Enter. A
  /// keystroke inside a line is corrected by the sliver's own measurement.
  void sync([SourceEdit? edit]) {
    final lines = _buffer().lineCount;
    // The side-by-side blocks follow the edit: typing in a column splices
    // its map, and changes no row (#729).
    if (edit != null) {
      _hosts.edited(edit, _estimateAt);
      _quoteRuns.edited(edit);
    }
    if (!_folds.isEmpty) {
      // The folds follow the edit; when what they hide changed shape, the
      // rows are measured again rather than spliced.
      final reshaped = edit == null || _folds.edited(edit, lines, _sectionEnd);
      if (edit == null) _folds.clear();
      if (reshaped) {
        _heights = _map();
        return;
      }
    }
    final rows = _folds.rowCount(lines);
    if (_heights.length == rows) return;
    if (edit != null &&
        _heights.length - edit.removedLines + edit.insertedLines == rows) {
      _heights.splice(
        _folds.rowOf(edit.firstLine),
        edit.removedLines,
        edit.insertedLines,
        _estimateRow,
      );
    } else {
      _heights = _map();
    }
  }

  /// Lays the note's `columns` blocks out in [width], the text's: the ones
  /// that sit side by side there are hosted, each in its opener's row, and
  /// the rows are reshaped when that changed which. A block a fold hides or
  /// holds stays stacked, as do they all in `source`.
  void layOutHosts(double width) {
    _hosts.layOut(
      liveRuns,
      widthOf: (run) => width - _itemsIndent(run),
      em: _em(),
      estimate: _estimateAt,
      // Not a block a fold hides, nor one with a fold inside.
      allowed: (run) =>
          !_folds.isHidden(run.start) &&
          !_folds.foldsWithin(run.start, run.end),
    );
    final hosts = _hosts.hosts;
    if (_sameHosts(hosts, _folds.hosts)) return;
    _reshapeHosts(hosts);
  }

  /// Makes [hosts] the side-by-side blocks, and splices the rows of each
  /// block that went into one row or came out of it: every other row keeps
  /// the height a frame measured, and a map that asks a chunk only when a
  /// frame reaches it still does — a block hosted on the frame that opens
  /// the note asks no other row.
  void _reshapeHosts(Map<int, int> hosts) {
    final was = Map<int, int>.of(_folds.hosts);
    // The lines whose rows change: each block hosted before and not now
    // with the same end, or now and not before, merged where they meet.
    final changed = <(int, int)>[
      for (final MapEntry(key: start, value: end) in was.entries)
        if (hosts[start] != end) (start, end),
      for (final MapEntry(key: start, value: end) in hosts.entries)
        if (was[start] != end) (start, end),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final ranges = <(int, int)>[];
    for (final (start, end) in changed) {
      if (ranges.isNotEmpty && start < ranges.last.$2) {
        if (end > ranges.last.$2) ranges.last = (ranges.last.$1, end);
      } else {
        ranges.add((start, end));
      }
    }
    final lines = _buffer().lineCount;
    int rowAt(int line) =>
        line < lines ? _folds.rowOf(line) : _folds.rowCount(lines);
    // From the top down, a range at a time, the folds saying what the map
    // holds at each splice — the blocks above as they are now, the ones
    // below as they were — so a chunk a splice works out, and the rows it
    // inserts, are read by the rows the map has.
    for (final (start, end) in ranges) {
      final from = rowAt(start);
      final removed = rowAt(end) - from;
      _folds.setHosts({
        for (final MapEntry(key: opener, value: close) in hosts.entries)
          if (opener < end) opener: close,
        for (final MapEntry(key: opener, value: close) in was.entries)
          if (opener >= end) opener: close,
      });
      _heights.splice(from, removed, rowAt(end) - from, _estimateRow);
    }
    _folds.setHosts(hosts);
    final rows = _folds.rowCount(lines);
    assert(_heights.length == rows, 'the splices left the rows miscounted');
    if (_heights.length != rows) _heights = _map();
  }

  static bool _sameHosts(Map<int, int> a, Map<int, int> b) =>
      a.length == b.length &&
      a.entries.every((entry) => b[entry.key] == entry.value);

  /// Runs [change] on the folds and, when it says it changed them, gives the
  /// rows new heights — each line that was drawn before keeps the height it
  /// was drawn at, so unfolding a section does not move the rest.
  ///
  /// Only a drawn row's height is read off the old map: a chunk of it no
  /// frame reached is worked out when first asked, by the rows as they are
  /// then, which [change] has already moved.
  void reshape(bool Function() change) {
    final before = _folds.copy();
    final old = _heights;
    if (!change()) return;
    double? drawn(int line) {
      final was = before.rowOf(line);
      return old.isMeasured(was) ? old.extentFor(was) : null;
    }

    _heights = BlockHeightMap(
      count: _folds.rowCount(_buffer().lineCount),
      estimate: (row) {
        final line = _folds.lineOf(row);
        // A side-by-side block's row is the block (#729): one drawn as it
        // was keeps its height, any other row in or out of one is
        // estimated again.
        final hosted = _hosts.openedOn(line);
        if (_folds.isHost(line) && hosted != null) {
          if (before.isHost(line) && before.hosts[line] == _folds.hosts[line]) {
            final height = drawn(line);
            if (height != null) return height;
          }
          return _hostEstimate(hosted);
        }
        if (!before.isHidden(line) &&
            !before.isHost(line) &&
            before.hostOf(line) == null) {
          final height = drawn(line);
          if (height != null) return height;
        }
        return _estimate(line);
      },
    );
  }

  /// Line [line]'s height before a frame has drawn it, [width] wide.
  double _estimateAt(int line, double width) {
    final advance = _em() * 0.6;
    final columns = advance <= 0 ? 1.0 : width / advance;
    return _estimateOf(_buffer().lineLengthAt(line), columns, _rowHeight());
  }

  /// [layout]'s block's height before a frame has drawn it.
  double _hostEstimate(LiveLayout layout) {
    final band = _band();
    return LiveHosts.estimateOf(
      layout,
      _gap(),
      layout.run.closed ? 2 * band : band,
    );
  }

  BlockHeightMap _map() {
    // Read once for the whole map, not once a row: a map is built over every
    // row of the note, 2.76 M on the 246 MB one.
    final columns = _columnsPerLine();
    final row = _rowHeight();
    final buffer = _buffer();
    // A row's estimate when a frame first comes near it, a chunk of rows at
    // a time: the map is built on the frame that opens the note, and asking
    // every line was 2.9 M estimates on the 246 MB stress note. A chunk is
    // asked with the rows as they are then — folds and side-by-side blocks
    // (#729) may have come since — so with any, a row is read as its line.
    return BlockHeightMap.lazy(
      count: _folds.rowCount(buffer.lineCount),
      estimate: (index) => _folds.isEmpty
          ? _estimateOf(buffer.lineLengthAt(index), columns, row)
          : _estimateRow(index),
      estimateSpan: (first, end) => _folds.isEmpty
          ? _estimateSpanOf(buffer, first, end, columns, row)
          : _estimateRowSpan(first, end, columns, row),
    );
  }

  /// Rows `[first, end)`'s height as best known without asking each: the
  /// lines they draw, less the ones a fold hides — a side-by-side block's
  /// counted as its lines one under the other.
  double _estimateRowSpan(int first, int end, double columns, double row) {
    if (end <= first) return 0;
    final from = _folds.lineOf(first);
    final last = _folds.lineOf(end - 1);
    final to = _folds.hosts[last] ?? last + 1;
    var total = 0.0;
    for (final (start, stop) in _folds.unfoldedSpans(from, to)) {
      total += _estimateSpanOf(_buffer(), start, stop, columns, row);
    }
    return total;
  }

  /// Row [row]'s height before a frame has drawn it: its line's, or a
  /// side-by-side block's.
  double _estimateRow(int row) {
    final line = _folds.lineOf(row);
    final hosted = _folds.isHost(line) ? _hosts.openedOn(line) : null;
    return hosted == null ? _estimate(line) : _hostEstimate(hosted);
  }

  /// A line's height before a frame has drawn it: its character count over the
  /// width a line holds, which is the same shape the read view's estimator has
  /// and is corrected by the sliver's own measurement.
  double _estimate(int index) {
    lineEstimates++;
    return _estimateOf(
      // The *buffer*, never the tokenizer: `HighlightDocument.lineAt`
      // materializes the line, so asking it for every line of a 10 000-line
      // note to fill the height map is a whole-note tokenize on every
      // keystroke. And the line's length, not the line: a line is cut out of
      // the text it was read from when it is asked for (`LineChunk`).
      _buffer().lineLengthAt(index),
      _columnsPerLine(),
      _rowHeight(),
    );
  }

  /// The height of a line [length] long, [columns] to a row of [row].
  static double _estimateOf(int length, double columns, double row) =>
      (length == 0 ? 1 : (length / columns).ceil()) * row;

  /// The height of lines `[first, end)` of [buffer] before they are asked
  /// one by one: from their characters alone, O(log lines).
  ///
  /// A line of `l` characters takes `l / columns` rows rounded up — half a
  /// row more than the division, on average — and one row at least. So
  /// lines holding `c` characters between them take about `c / columns +
  /// lines / 2` rows, and never fewer than one each.
  static double _estimateSpanOf(
    SourceBuffer buffer,
    int first,
    int end,
    double columns,
    double row,
  ) {
    final lines = end - first;
    final to = end < buffer.lineCount
        ? buffer.offsetOfLine(end)
        : buffer.length;
    // The terminators are not text: about one character a line.
    final text = to - buffer.offsetOfLine(first) - lines;
    final rows = text / columns + lines / 2;
    return (rows < lines ? lines : rows) * row;
  }
}
