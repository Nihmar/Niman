/// The block scanner: what each line is, and where one block ends.
///
/// Two ideas, both taken from what this repo already does and generalized
/// (`docs/records/unified-surface.md` §8.5):
///
/// * **A line's block meaning is a function of the line and the state entering
///   it.** `editor/highlighting.dart` already relies on this with a fence, math
///   and frontmatter; [LineState] widens it to the containers Markdown has.
/// * **A re-scan can stop when the state converges.** If the state entering
///   line *i* is what it was before the edit, and line *i* is a boundary where
///   no block can be spanning, then every line after it produces what it
///   produced before. That is the same rule the tokenizer uses at
///   `highlighting.dart:341`, and it is what makes an edit O(change) rather
///   than O(document).
///
/// The scanner is driven by the source buffer: `edited(firstLine)` after a
/// change, and `index` for the answer.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_builder.dart';
import 'package:niman/src/markdown/block_changes.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_list.dart';
import 'package:niman/src/markdown/block_rules.dart';
import 'package:niman/src/markdown/line_rules.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/table_line_syntax.dart';

/// Reads a note's lines into blocks, and keeps up with edits.
final class BlockScanner {
  /// Scans [buffer] from the top, all of it.
  ///
  /// An edit's rescan reads at most [budget] lines past the edit before it
  /// leaves the rest to [advance] (see [edited]).
  ///
  /// `leftOver` is, for a container's content read again, what a tab left
  /// over before each of its lines (`ContainerWalk.of`); such a scan is
  /// read once, never edited.
  new(
    this.buffer, {
    this.budget = defaultBudget,
    this._leftOver = const <int>[],
  }) : _blocks = BlockList() {
    _rebuild(start: 0, headEnd: 0, tailStart: 0, settledFrom: 0, budget: null);
    // The changes are counted from the list a reader first takes.
    _changes
      ..clear()
      ..[_handOver] = BlockChanges();
  }

  /// [scanned]'s answer, for [buffer]: a scan made of a copy of the note —
  /// in an isolate — taken over by the note itself, without scanning again.
  ///
  /// The two must hold the same lines, which is the caller's to promise.
  new rebound(BlockScanner scanned, this.buffer)
    : budget = scanned.budget,
      _leftOver = scanned._leftOver,
      _blocks = BlockList.sharing((scanned..settle())._blocks) {
    _entering.addAll(scanned._entering);
    _lineCount = scanned._lineCount;
  }

  /// How many lines past its edit a rescan reads before it stops, by default:
  /// a few milliseconds of scanning, and far more than a screen of lines.
  static const int defaultBudget = 4096;

  /// How many lines past its edit a rescan reads before it stops.
  final int budget;

  /// The text being scanned.
  final SourceBuffer buffer;

  /// The state entering each scanned line.
  final List<LineState> _entering = <LineState>[];

  /// What a tab left over before each line, for a container's content.
  final List<int> _leftOver;

  /// What the scan makes of each line, read against [_entering].
  late final LineRules _rules = LineRules(buffer, _entering, _leftOver);

  /// The blocks the scan makes of those lines.
  late final BlockRules _blockRules = BlockRules(_rules);

  /// The blocks of the scanned prefix, in line order.
  ///
  /// Spliced in place: the list is the one structure here whose size is the
  /// document's, so an edit replaces a range of it rather than building a
  /// new one. It is kept in chunks, each with the lines its blocks have
  /// moved ([BlockList]): an edit that adds or removes lines moves every
  /// block after it, and moving them — a new block each — was an Enter's
  /// cost on a note of millions of blocks, 170 ms on a 246 MB one. A chunk's
  /// shift moves a thousand of them at once, and a reader that takes the
  /// whole list takes the chunks, not the blocks.
  final BlockList _blocks;

  /// Block [index] where it is now.
  Block _at(int index) => _blocks[index];

  /// What the edits did to the block list since [reader] last asked, and a
  /// fresh record for it from here on.
  ///
  /// For a reader that keeps something per block: it replays these over
  /// what it had instead of starting again. Each reader keeps a record of
  /// its own, so one taking its changes leaves the others theirs — the read
  /// pane's heights, handed over by the editor, are the default reader, and
  /// their record is counted from the scan; any other reader's is counted
  /// from its first call, which is where it has to take the list whole.
  BlockChanges takeChanges([Object? reader]) {
    final key = reader ?? _handOver;
    final taken = _changes[key] ?? BlockChanges();
    _changes[key] = BlockChanges();
    return taken;
  }

  /// The reader [takeChanges] answers when none is named.
  static final Object _handOver = Object();

  /// Each reader's record of the splices since it last took them.
  final Map<Object, BlockChanges> _changes = <Object, BlockChanges>{
    _handOver: BlockChanges(),
  };

  /// The blocks as of [SourceBuffer.revision], for a reader that wants them.
  ///
  /// All of them, so a scan still owed is finished first ([settle]): O(the
  /// rest of the note) once after an edit that changed it, which is why the
  /// readers on a keystroke's path ask [blockAt] instead. The list itself
  /// is a copy that shares the scanner's chunks: O(chunks).
  BlockIndex get index {
    settle();
    return BlockIndex(
      blocks: BlockList.sharing(_blocks),
      revision: buffer.revision,
    );
  }

  /// The line count at the last scan.
  int _lineCount = 0;

  /// How many lines the last scan covered.
  int get scannedLineCount => _lineCount;

  /// How many times a line's state has been computed, for the tests that prove
  /// an edit is O(change) rather than O(document).
  int get scannedLineTotal => _scannedLineTotal;
  int _scannedLineTotal = 0;

  /// The state entering [line]: scanned up to it first when it is owed.
  LineState stateEntering(int line) {
    _catchUp(line);
    return _entering[line];
  }

  /// The block holding [line], or null past the note's end. O(log blocks),
  /// and without the copy [index] makes.
  ///
  /// Current: a line past a [frontier] is scanned up to first — and on to the
  /// end of its block, since a block the scan has not finished is cut where
  /// the scan stopped, and a reader of its last line or of its parse needs
  /// the block that is.
  Block? blockAt(int line) {
    _catchUp(line);
    return _blockHolding(line);
  }

  /// The block holding [line] as the list has it, current or not.
  Block? _blockHolding(int line) {
    if (_blocks.isEmpty || line < 0) return null;
    final at = _firstIndexWhere(0, (block) => block.startLine > line) - 1;
    if (at < 0) return null;
    final block = _at(at);
    return block.contains(line) ? block : null;
  }

  // ------------------------------------------------------------ frontiers

  /// Where the scan stopped short, ascending: from each of these lines on,
  /// the recorded states and blocks are what an earlier scan made of them —
  /// hints, not answers, until [advance] reaches them. Empty when the whole
  /// note is current.
  ///
  /// Why a rescan stops short at all is `docs/records/huge-notes.md` item 3: an
  /// edit can change what the whole rest of the note *is* — the second `$`
  /// of a `$$`, the third backtick of a fence — and then there is nothing to
  /// converge to until the end. That work is the note's, and it cannot be
  /// made smaller; what a keystroke can be spared is doing all of it at once.
  final List<int> _frontiers = <int>[];

  /// Whether every line's state and block is current.
  bool get settled => _frontiers.isEmpty;

  /// The first line that is not yet current, or null when all are.
  int? get frontier => _frontiers.isEmpty ? null : _frontiers.first;

  /// Scans on from the first [frontier], [lines] lines or until the scan
  /// agrees with what was there. Does nothing when [settled].
  void advance([int? lines]) {
    if (_frontiers.isEmpty) return;
    final from = _frontiers.removeAt(0);
    // The block that ends at the frontier is the one the scan had open when it
    // stopped: it is taken open again, and the blocks from the frontier on are
    // the hints the rebuild compares with.
    final headEnd = _firstIndexWhere(0, (block) => block.endLine >= from);
    _rebuild(
      start: from,
      headEnd: headEnd,
      tailStart: headEnd + 1,
      settledFrom: from + 1,
      // At least a line past the frontier, or a caller with nothing left
      // to spend would put it back where it was.
      budget: (lines ?? budget) < 1 ? 1 : lines ?? budget,
    );
  }

  /// Scans until every line is current.
  void settle() {
    while (_frontiers.isNotEmpty) {
      advance(1 << 30);
    }
  }

  /// Scans until [line] and the block holding it are current.
  void _catchUp(int line) {
    while (_frontiers.isNotEmpty) {
      final first = _frontiers.first;
      if (first > line) {
        // The line is current; its block is too unless the scan stopped
        // inside it, which is when the block ends at the frontier.
        final block = _blockHolding(line);
        if (block == null || block.endLine != first) return;
      }
      advance(line >= first ? line - first + budget : budget);
    }
  }

  /// Re-scans after [edit].
  ///
  /// Blocks entirely before the edit are kept, blocks from the point where the
  /// scan converges on are kept, and the region between is rebuilt. When the
  /// rebuild has read [budget] lines past the edit without converging, it
  /// stops there and leaves a [frontier]: the rest is what the edit changed,
  /// and [advance] carries on with it.
  void edited(SourceEdit edit) {
    assert(_leftOver.isEmpty, "a container's content is not edited");
    final untouched = edit.firstUntouchedLine;
    if (edit.firstLine < _entering.length) {
      _replaceStates(
        edit.firstLine,
        (untouched > _entering.length ? _entering.length : untouched) -
            edit.firstLine,
        edit.insertedLines,
      );
    }
    // A frontier below the edit moves with the lines; one inside what the
    // edit replaced is where the edit begins, which the rebuild passes.
    for (var at = 0; at < _frontiers.length; at++) {
      final line = _frontiers[at];
      if (line >= untouched) {
        _frontiers[at] = line + edit.lineDelta;
      } else if (line > edit.firstLine) {
        _frontiers[at] = edit.firstLine;
      }
    }
    final tailStart = _firstIndexWhere(
      0,
      (block) => block.startLine >= untouched,
    );
    // The survivors after the edit are the same blocks, moved by however
    // many lines the document gained or lost — a chunk at a time
    // ([BlockList.shiftFrom]): everything below reads them where they are.
    _blocks.shiftFrom(tailStart, edit.lineDelta);
    var start = edit.firstLine;
    // The lines before the edit read it: a line heads a table — any line
    // may, pipes or not — when the line under it is a delimiter row that
    // stays in its container, which the line under that decides; and a
    // setext underline heads its paragraph only over no delimiter row. So
    // the rebuild starts a line back — two when that line is a delimiter
    // row, which the line above it may head — and takes the block it lands
    // in open, cut there, as at any line. It stops at a blank line, which
    // reads nothing after it: a block after a blank line is not read again
    // for an edit on its first line.
    for (
      var back = 0;
      back < 2 &&
          start > 0 &&
          start - 1 < buffer.lineCount &&
          _rules.lineText(start - 1).trim().isNotEmpty;
      back++
    ) {
      start--;
      if (!TableLineSyntax.isDelimiter(_rules.lineText(start).trimLeft())) {
        break;
      }
    }
    // An edit at or past a frontier lands on lines that are not current: the
    // rebuild starts where they begin.
    if (_frontiers.isNotEmpty && _frontiers.first < start) {
      start = _frontiers.first;
    }
    var headEnd = 0;
    if (start > 0) {
      // The block holding the line before the rebuild, which is a kept one:
      // everything before the edit is where it was.
      headEnd = _firstIndexWhere(0, (block) => block.endLine >= start);
      // A line no kept block holds is a list that no longer tiles the
      // note; a scan from the top is the answer that cannot be wrong.
      if (headEnd >= tailStart) headEnd = start = 0;
    }
    _rebuild(
      start: start,
      headEnd: headEnd,
      tailStart: tailStart,
      // Only from two lines past the edit is a line's recorded state its own:
      // the inserted lines hold placeholders, and the first line after them
      // still reads the last inserted one (an indented block opens only
      // after a blank line).
      settledFrom: edit.firstLine + edit.insertedLines + 1,
      edit: edit,
      budget: budget,
    );
  }

  /// Rebuilds from [start] — the block at [headEnd] holding the line before
  /// it, taken open — until the scan converges on what was there, reaches
  /// the note's end, or has read [budget] lines past [settledFrom].
  ///
  /// The blocks from [tailStart] on are the ones the scan is compared with;
  /// the ones before it that [edit] touched are read where they were before
  /// it. Both ends of the rebuild are the *edit's*, not the block's
  /// (`docs/records/huge-notes.md` item 3): a block can be the whole note — a
  /// paragraph with no blank line in it, a formula that never closes — and a
  /// keystroke that paid for the block paid for the note.
  ///
  /// * **It starts at the edit.** The lines before it are the lines they were,
  ///   entered in the states they were, so the block they are in is the block
  ///   it was up to the edit; the rebuild takes that block *open* and asks, as
  ///   a fresh scan would, whether the edited line goes on with it.
  /// * **It stops where the scan agrees with what was there** — the state
  ///   entering a line is what it was, and so is the block that line is in
  ///   (see [_convergesAt]). From there on every line is the same text entered
  ///   in the same state, so it makes the same blocks it made before.
  void _rebuild({
    required int start,
    required int headEnd,
    required int tailStart,
    required int settledFrom,
    required int? budget,
    SourceEdit? edit,
  }) {
    // The block the line before the rebuild is in, cut at the rebuild: what a
    // fresh scan has open when it reaches the edited line.
    final open = start > 0 && headEnd < _blocks.length
        ? _reopened(_at(headEnd), headEnd, start)
        : null;
    final builder = BlockBuilder(
      _blockRules,
      open: open,
      before: _nonBlankBefore(headEnd),
    );
    final stopAt = budget == null
        ? buffer.lineCount
        : (settledFrom > start ? settledFrom : start) + budget;

    var line = start;
    var state = start == 0 ? LineState.initial : _rules.exitOf(start - 1);
    var keepFrom = -1;
    var converged = false;
    while (line < buffer.lineCount) {
      final previous = line < _entering.length ? _entering[line] : null;
      if (line >= settledFrom && previous == state && !_isFrontier(line)) {
        if (_isBlockBoundary(line, state) && _hasBoundaryAt(line, tailStart)) {
          // Converged at a boundary: the state is what it was, nothing is
          // continuing across this line, and the block list already has a
          // boundary here — so the blocks after it are untouched.
          converged = true;
          break;
        }
        keepFrom = _convergesAt(line, builder, tailStart, headEnd, edit);
        if (keepFrom >= 0) {
          converged = true;
          break;
        }
      }
      if (line >= stopAt) break;
      _setEntering(line, state);
      builder.add(line);
      state = _rules.exitOf(line);
      line++;
    }
    _scannedLineTotal += line - start;
    final rebuilt = builder.finish();

    if (!converged && line < buffer.lineCount) {
      // Stopped short: the lines from here on keep what they had, as hints,
      // and the block the old list has here is cut so the list goes on tiling
      // the note — its shape is the old one's, which [advance] will replace.
      final (index, block, end) = _hintAt(line, tailStart, headEnd, edit);
      if (block == null) {
        keepFrom = _firstIndexWhere(tailStart, (b) => b.startLine >= line);
      } else if (block.startLine >= line) {
        keepFrom = index;
      } else {
        rebuilt.add(block.cutFrom(line, end));
        keepFrom = index + 1;
      }
    }
    // Everything from the convergence point on is what it was, so the
    // survivors are spliced back in place instead of being copied into a new
    // list: one range replacement, and the blocks inside the edit — the ones
    // between the head and the tail — are what it drops.
    if (keepFrom < 0) {
      keepFrom = _firstIndexWhere(
        tailStart,
        (block) => block.startLine >= line,
      );
    }
    // The dropped blocks are the ones between the head and the kept tail.
    _blocks.splice(headEnd, keepFrom, rebuilt);
    for (final changes in _changes.values) {
      changes.record(headEnd, keepFrom - headEnd, rebuilt.length);
    }
    // The frontiers the rebuild passed are behind it; a converged one leaves
    // the ones below it, whose hints it did not reach, and one that stopped
    // short is the first frontier itself.
    _frontiers.removeWhere((frontier) => frontier <= line);
    if (!converged && line < buffer.lineCount) _frontiers.insert(0, line);
    // The states recorded after the convergence point are *kept*: convergence
    // means they are what they were, and a later edit down there needs the
    // state entering its block. Only the entries past the document's end go,
    // which is what a deletion leaves behind.
    if (_entering.length > buffer.lineCount) {
      _entering.removeRange(buffer.lineCount, _entering.length);
    }
    _lineCount = buffer.lineCount;
  }

  /// Whether a scan stopped short at [line]: the block there was cut from one
  /// above it, so it is no block of the note's and nothing converges on it.
  bool _isFrontier(int line) {
    for (final frontier in _frontiers) {
      if (frontier == line) return true;
      if (frontier > line) return false;
    }
    return false;
  }

  /// The old block holding [line], its index and where it ends now: a kept
  /// one after the edit, where it is now; or the last one [edit] touched,
  /// when it runs on past the edit — read where it was, so its end is moved
  /// by the edit's delta. A null block when neither holds [line].
  (int, Block?, int) _hintAt(
    int line,
    int tailStart,
    int headEnd,
    SourceEdit? edit,
  ) {
    final index = _firstIndexWhere(tailStart, (b) => b.startLine > line) - 1;
    if (index >= tailStart) {
      final block = _at(index);
      return (index, block, block.endLine);
    }
    final touched = tailStart - 1;
    if (edit == null || touched < headEnd || touched < 0) return (-1, null, 0);
    final block = _at(touched);
    final end = block.endLine + edit.lineDelta;
    if (block.endLine < edit.firstUntouchedLine ||
        line >= end ||
        block.startLine >= line) {
      return (-1, null, 0);
    }
    return (touched, block, end);
  }

  /// Whether the rebuild can stop before [line] — whose entering state is
  /// the one it had, as is the line before it — and, when it can, the index
  /// of the first old block to keep; -1 when it cannot.
  ///
  /// The state being the same says every line from here on is entered as it
  /// was. What it does not say is which block [line] is in, because that is
  /// the pair's question: whether [line] goes on with the block the rebuild
  /// has open, or starts one. So the old block holding [line] is looked up,
  /// and the rebuild stops only when the fresh scan would make the same one:
  ///
  /// * the old block starts at [line], and [line] does not go on with the
  ///   open block — then the old blocks from here on are kept whole;
  /// * the old block started above, and [line] goes on with an open block of
  ///   the same shape — then that block is the old one, and it ends where the
  ///   old one did (whether a line goes on with a block asks only the block's
  ///   kind, its depths and the line). An open paragraph going on into an old
  ///   setext heading is that heading's paragraph: the same lines take it to
  ///   the same underline, so it is the heading, and ends where it did.
  ///
  /// Not a blank run, nor an item that counts differently: the block after a
  /// blank run counts its items from the block *before* it, which is the
  /// rebuild's, so a kept list there would keep numbers that are not its own.
  int _convergesAt(
    int line,
    BlockBuilder builder,
    int tailStart,
    int headEnd,
    SourceEdit? edit,
  ) {
    final (index, old, oldEnd) = _hintAt(line, tailStart, headEnd, edit);
    if (old == null || old.kind == BlockKind.blank) return -1;
    final open = builder.open;
    final goesOn = open != null && _blockRules.mergesInto(open, line);
    if (old.startLine == line) {
      if (goesOn) return -1;
      if (old.kind == BlockKind.listItem &&
          _blockRules.ordinalOf(
                line,
                old.listDepth,
                old.quoteDepth,
                builder.previous,
              ) !=
              old.listOrdinal) {
        return -1;
      }
      return index;
    }
    if (!goesOn) return -1;
    if (!open.sameShape(old)) {
      // A heading that started above [line] is a setext one: an ATX
      // heading is its own line alone. Its open block is a paragraph, or an
      // item whose first paragraph the underline heads.
      final setext =
          (open.kind == BlockKind.paragraph ||
              open.kind == BlockKind.listItem) &&
          (old.kind == BlockKind.heading ||
              (old.kind == BlockKind.listItem && old.headingLevel > 0)) &&
          open.quoteDepth == old.quoteDepth &&
          open.listDepth == old.listDepth &&
          // An item's number counts the items after it on.
          open.listOrdinal == old.listOrdinal;
      if (!setext) return -1;
      builder.headOpen(old.headingLevel);
    }
    builder.openEnd = oldEnd;
    return index + 1;
  }

  /// [block], at index [index], cut at [end] to be taken open again: a
  /// setext heading cut short of its underline is the block it was before
  /// the underline reached it, and goes on as one. That is a paragraph, or
  /// an item whose first paragraph the underline headed — so it is read
  /// again from its first line, which the edit did not touch, rather than
  /// assumed: taken for a paragraph, `- item` / `  ---` with its underline
  /// gone was a paragraph to the rescan and an item to a fresh scan.
  Block _reopened(Block block, int index, int end) {
    final headed =
        block.kind == BlockKind.heading ||
        (block.kind == BlockKind.listItem && block.headingLevel > 0);
    if (!headed || end >= block.endLine) {
      return block.cutAt(end);
    }
    return _blockRules
        .blockStarting(block.startLine, _nonBlankBefore(index))
        .cutAt(end);
  }

  /// The first block index at or after [fromIndex] whose `test` holds, or the
  /// list's length when none does.
  ///
  /// The block list is sorted by line, so this is a binary search — the point
  /// of the whole method being that a keystroke must not walk 22 000 blocks.
  int _firstIndexWhere(int fromIndex, bool Function(Block block) test) {
    var low = fromIndex;
    var high = _blocks.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (test(_at(middle))) {
        high = middle;
      } else {
        low = middle + 1;
      }
    }
    return low;
  }

  /// Whether a *surviving* block already starts at [line].
  ///
  /// Only the blocks from [fromIndex] on count: everything before it is either
  /// before the edit or inside it, and a boundary from a block that is about to
  /// be rebuilt is not a boundary the kept tail has.
  bool _hasBoundaryAt(int line, int fromIndex) {
    if (line == 0) return true;
    final at = _firstIndexWhere(fromIndex, (block) => block.startLine >= line);
    return at < _blocks.length && _at(at).startLine == line;
  }

  /// Replaces [removed] line states from [first] with [inserted] fresh ones.
  ///
  /// In place: a keystroke replaces a line with a line, and removing and
  /// inserting it moved the whole list twice — a note's worth of states per
  /// key, the most of a keystroke's cost on a 246 MB note.
  void _replaceStates(int first, int removed, int inserted) {
    final kept = removed < inserted ? removed : inserted;
    for (var at = first; at < first + kept; at++) {
      _entering[at] = LineState.initial;
    }
    if (removed > inserted) {
      _entering.removeRange(first + inserted, first + removed);
    } else if (inserted > removed) {
      final at = first + removed;
      final more = inserted - removed;
      final length = _entering.length;
      _entering.addAll(List<LineState>.filled(more, LineState.initial));
      // One move of the tail, overlapping ranges copied as the list promises.
      _entering.setRange(at + more, length + more, _entering, at);
      for (var fill = at; fill < at + more; fill++) {
        _entering[fill] = LineState.initial;
      }
    }
  }

  /// Records [state] as entering [line], growing the list as it goes.
  void _setEntering(int line, LineState state) {
    while (_entering.length <= line) {
      _entering.add(LineState.initial);
    }
    _entering[line] = state;
  }

  /// Whether a block can end at [line]: the state is top level and the line
  /// before it is blank, so nothing is continuing across it.
  ///
  /// Unless [line] is blank too: blank lines are one block however many there
  /// are, so the second of two was never a boundary — and a rescan that
  /// stopped on it split the run in two. Nor when [line] opens a list item:
  /// an ordered item counts on from the block before the blank, which is the
  /// rebuilt one, so a kept item there would keep a number that is no longer
  /// its own.
  bool _isBlockBoundary(int line, LineState state) {
    if (!state.isPlain || state.quoteDepth != 0 || state.listIndent >= 0) {
      return false;
    }
    if (state.table) return false;
    if (line == 0) return true;
    final text = _rules.lineText(line);
    return _rules.lineText(line - 1).trim().isEmpty &&
        text.trim().isNotEmpty &&
        LineSyntax.listMarker(text) == null;
  }

  /// The last block before index [end] that is not a blank run, or null.
  ///
  /// Blank lines merge into one block, so this looks back one block or two.
  Block? _nonBlankBefore(int end) {
    for (var at = end - 1; at >= 0; at--) {
      final block = _at(at);
      if (block.kind != BlockKind.blank) return block;
    }
    return null;
  }
}
