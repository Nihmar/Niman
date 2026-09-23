/// The block scanner: what each line is, and where one block ends.
///
/// Two ideas, both taken from what this repo already does and generalized
/// (`docs/dev/unified-surface.md` §8.5):
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

import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// Reads a note's lines into blocks, and keeps up with edits.
final class BlockScanner {
  /// Scans [buffer] from the top, all of it.
  ///
  /// An edit's rescan reads at most [budget] lines past the edit before it
  /// leaves the rest to [advance] (see [edited]).
  new(this.buffer, {this.budget = defaultBudget}) {
    _rebuild(start: 0, headEnd: 0, tailStart: 0, settledFrom: 0, budget: null);
  }

  /// [scanned]'s answer, for [buffer]: a scan made of a copy of the note —
  /// in an isolate — taken over by the note itself, without scanning again.
  ///
  /// The two must hold the same lines, which is the caller's to promise.
  new rebound(BlockScanner scanned, this.buffer) : budget = scanned.budget {
    scanned.settle();
    scanned._settle(scanned._blocks.length);
    _entering.addAll(scanned._entering);
    _blocks.addAll(scanned._blocks);
    _lineCount = scanned._lineCount;
    _shiftFrom = _blocks.length;
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

  /// The blocks of the scanned prefix, in line order.
  ///
  /// Final, and spliced in place: the list is the one structure here whose size
  /// is the document's, so an edit replaces a range of it rather than building
  /// a new one.
  ///
  /// The blocks from [_shiftFrom] on are stored [_shift] lines above where
  /// they are: read them through [_at].
  final List<Block> _blocks = <Block>[];

  /// Where the blocks still owed a shift start, and by how many lines.
  ///
  /// An edit that adds or removes lines moves every block after it, and
  /// moving them — a new block each — was an Enter's cost on a note of
  /// millions of blocks: 170 ms on a 246 MB one. So the move is owed rather
  /// than made: one shift for everything past a point, paid only over the
  /// blocks between that point and the next edit's, which for a writer is
  /// the few blocks between two keystrokes.
  int _shiftFrom = 0;
  int _shift = 0;

  /// Block [index] where it is now.
  Block _at(int index) {
    final block = _blocks[index];
    return index >= _shiftFrom && _shift != 0 ? block.shifted(_shift) : block;
  }

  /// Pays the owed shift on the blocks before [upTo].
  void _settle(int upTo) {
    if (_shift != 0) {
      for (var at = _shiftFrom; at < upTo; at++) {
        _blocks[at] = _blocks[at].shifted(_shift);
      }
    }
    if (upTo > _shiftFrom) _shiftFrom = upTo;
  }

  /// Owes [delta] more lines to every block from [from] on.
  void _owe(int from, int delta) {
    if (from >= _shiftFrom) {
      _settle(from);
    } else {
      // These are where they are; stored against the shift owed from [from]
      // on, so that reading them adds [delta] and nothing else.
      if (_shift != 0) {
        for (var at = from; at < _shiftFrom; at++) {
          _blocks[at] = _blocks[at].shifted(-_shift);
        }
      }
      _shiftFrom = from;
    }
    _shift += delta;
  }

  /// The blocks as of [SourceBuffer.revision], for a reader that wants them.
  ///
  /// All of them, so a scan still owed is finished first ([settle]): O(the
  /// rest of the note) once after an edit that changed it, which is why the
  /// readers on a keystroke's path ask [blockAt] instead.
  BlockIndex get index {
    settle();
    _settle(_blocks.length);
    return BlockIndex(
      blocks: List<Block>.unmodifiable(_blocks),
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
  /// Why a rescan stops short at all is `docs/dev/huge-notes.md` item 3: an
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
    // many lines the document gained or lost — owed, not moved ([_owe]):
    // everything below reads them where they are now.
    if (edit.lineDelta != 0) _owe(tailStart, edit.lineDelta);
    var start = edit.firstLine;
    // The line before the edit reads the edited line when it asks whether
    // it heads a table (the delimiter row is the line under it), so it is
    // not the line it was: the rebuild takes in its whole block.
    if (start > 0 &&
        start - 1 < buffer.lineCount &&
        _hasPipe(_text(start - 1))) {
      start = _blockHolding(start - 1)?.startLine ?? 0;
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
  /// (`docs/dev/huge-notes.md` item 3): a block can be the whole note — a
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
        ? _cut(_at(headEnd), start)
        : null;
    final builder = _BlockBuilder(
      this,
      open: open,
      before: _nonBlankBefore(headEnd),
    );
    final stopAt = budget == null
        ? buffer.lineCount
        : (settledFrom > start ? settledFrom : start) + budget;

    var line = start;
    var state = start == 0 ? LineState.initial : _exitOf(start - 1);
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
      state = _exitOf(line);
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
        rebuilt.add(_cutFront(block, line, end));
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
    // The dropped blocks are the ones between the head and the kept tail;
    // anything owed a shift among them is paid first, so what is owed after
    // the splice is owed from the kept tail on, exactly.
    if (_shiftFrom < keepFrom) _settle(keepFrom);
    _blocks.replaceRange(headEnd, keepFrom, rebuilt);
    _shiftFrom += rebuilt.length - (keepFrom - headEnd);
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

  /// [block] from [start] on, to [end]: what is left of a block a scan
  /// stopped inside.
  static Block _cutFront(Block block, int start, int end) => Block(
    kind: block.kind,
    startLine: start,
    endLine: end,
    quoteDepth: block.quoteDepth,
    listDepth: block.listDepth,
    listOrdinal: block.listOrdinal,
    headingLevel: block.headingLevel,
    fenceInfo: block.fenceInfo,
  );

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
  ///   kind and the line).
  ///
  /// Not a blank run, nor an item that counts differently: the block after a
  /// blank run counts its items from the block *before* it, which is the
  /// rebuild's, so a kept list there would keep numbers that are not its own.
  int _convergesAt(
    int line,
    _BlockBuilder builder,
    int tailStart,
    int headEnd,
    SourceEdit? edit,
  ) {
    final (index, old, oldEnd) = _hintAt(line, tailStart, headEnd, edit);
    if (old == null || old.kind == BlockKind.blank) return -1;
    final open = builder.open;
    final goesOn = open != null && _mergesInto(open.kind, open.startLine, line);
    if (old.startLine == line) {
      if (goesOn) return -1;
      if (old.kind == BlockKind.listItem &&
          _ordinalOf(line, old.listDepth, old.quoteDepth, builder.previous) !=
              old.listOrdinal) {
        return -1;
      }
      return index;
    }
    if (!goesOn || !open.sameShape(old)) return -1;
    builder.openEnd = oldEnd;
    return index + 1;
  }

  /// [block] as it was before [end]: the run it covered up to a line inside
  /// it, which is what an edit leaves of the block it landed in.
  static Block _cut(Block block, int end) => Block(
    kind: block.kind,
    startLine: block.startLine,
    endLine: end,
    quoteDepth: block.quoteDepth,
    listDepth: block.listDepth,
    listOrdinal: block.listOrdinal,
    headingLevel: block.headingLevel,
    fenceInfo: block.fenceInfo,
    entering: block.entering,
  );

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
    final text = _text(line);
    return _text(line - 1).trim().isEmpty &&
        text.trim().isNotEmpty &&
        _listMarker(text) == null;
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

  /// The block that starts on [line], one line long: the builder extends it.
  ///
  /// [previous] is the last non-blank block before it, which an ordered item
  /// counts on from.
  Block _blockStarting(int line, Block? previous) {
    final kind = _kindOf(line);
    final text = _text(line);
    // The depth *on* the line, not the one entering it: a quote's first line
    // has no depth before its own `>`, so taking the entering state left
    // every quote block at depth 0 — which made the renderer draw it as an
    // unnested quote and the parser read the `>` as text.
    final quoteDepth = _quoteDepthAfter(line, text, _entering[line]);
    // The depth *on* the line, like the quote's: the state entering a marker
    // line describes the item before it, so a block that took its depth from
    // there was drawn at the previous item's indent — siblings at different
    // indents, the item after a sublist pushed right (device report,
    // 2026-09-21).
    final listStack = _listAfter(text, _entering[line]);
    final listDepth = listStack.isEmpty ? -1 : listStack.length - 1;
    return Block(
      kind: kind,
      startLine: line,
      endLine: line + 1,
      quoteDepth: quoteDepth,
      listDepth: listDepth,
      // An ordered list counts from its first item on, wherever the list
      // starts; a list written `1. 1. 1.` renders 1, 2, 3, which is CommonMark
      // and what the preview draws. The count lives here because this is where
      // the *list* is still visible: a block knows only its own item.
      listOrdinal: kind == BlockKind.listItem
          ? _ordinalOf(line, listDepth, quoteDepth, previous)
          : 0,
      headingLevel: kind == BlockKind.heading ? _headingLevel(text) : 0,
      fenceInfo: kind == BlockKind.fencedCode ? _fenceInfo(line) : null,
      entering: _entering[line],
    );
  }

  /// Whether line [end] belongs to the block that started on [start].
  bool _mergesInto(BlockKind kind, int start, int end) {
    switch (kind) {
      case BlockKind.heading:
      case BlockKind.thematicBreak:
        return false;
      case BlockKind.listItem:
        // A new marker starts a new item, and a blank line ends this one; a
        // line with neither continues it, which keeps a wrapped item whole.
        return _text(end).trim().isNotEmpty && _listMarker(_text(end)) == null;
      case BlockKind.quote:
        // A blank line ends the quoted run; a line that is still a quote line —
        // with a marker or lazily without one — continues it.
        return _kindOf(end) == BlockKind.quote;
      case BlockKind.paragraph:
      case BlockKind.fencedCode:
      case BlockKind.indentedCode:
      case BlockKind.frontmatter:
      case BlockKind.html:
      case BlockKind.table:
      case BlockKind.blank:
        return _kindOf(end) == kind;
      case BlockKind.math:
        // A display block runs while it is open, and the state entering the
        // line is the only thing that knows: the line that *closes* a block
        // starts with `$$` as much as the line that opens one does. Asking
        // the line instead of the state stitched two neighbouring formulas
        // into one block whose tex was both of them (#252).
        return _entering[end].math;
    }
  }

  /// Whether [line] is display math — either form — rather than code.
  ///
  /// Two rules, both of them the preview's rather than the scanner's own:
  ///
  /// * **The shared rule says what a display line is** (`math_rule.dart`):
  ///   a `$$…$$` that opens and closes on one line is a display block too.
  ///   Keeping a private copy here is what made `$$x$$` a paragraph in the
  ///   read view and a centered block in the preview (#252).
  /// * **An indented `$$` line is code.** The preview's parser runs its
  ///   indented-code syntax before the math one, so a `$$` line indented four
  ///   spaces never opens a formula; display math is otherwise indent-blind.
  bool _isDisplayLineAt(int line, String text, LineState state) =>
      !_indentedCodeContinues(line, text, state) && isDisplayLine(text.trim());

  /// What line [line] is.
  BlockKind _kindOf(int line) {
    final state = _entering[line];
    final text = _text(line);
    if (state.fence != null || _fenceOpen(text) != null) {
      return BlockKind.fencedCode;
    }
    if (state.math || _isDisplayLineAt(line, text, state)) {
      return BlockKind.math;
    }
    if (state.frontmatter || _opensFrontmatter(line, text)) {
      return BlockKind.frontmatter;
    }
    if (state.html != null &&
        !(text.trim().isEmpty &&
            (state.html == HtmlBlockKind.blockTag ||
                state.html == HtmlBlockKind.completeTag))) {
      return BlockKind.html;
    }
    if (_htmlOpen(text) != null) return BlockKind.html;
    if (text.trim().isEmpty) return BlockKind.blank;
    if (_isTableRow(line)) return BlockKind.table;
    if (_hr.hasMatch(text)) return BlockKind.thematicBreak;
    if (_headingLevel(text) > 0) return BlockKind.heading;
    if (state.indentedCode || _opensIndentedCode(line, text)) {
      return BlockKind.indentedCode;
    }
    // Containers, innermost first: a line with its own quote marker is a quote
    // line, a line with a list marker starts an item, and a line with neither
    // either continues the item it is indented into or the quote it is lazily
    // part of.
    if (_quoteDepth(text) > 0) return BlockKind.quote;
    if (_listMarker(text) != null) return BlockKind.listItem;
    if (text.trim().isNotEmpty && state.listIndent >= 0) {
      return BlockKind.paragraph;
    }
    if (text.trim().isNotEmpty && state.quoteDepth > 0) return BlockKind.quote;
    return BlockKind.paragraph;
  }

  /// The state after line [line], given the state entering it.
  LineState _exitOf(int line) {
    final state = _entering[line];
    final text = _text(line);
    if (state.fence != null) {
      return _isFenceClose(text, state.fence!) ? LineState.initial : state;
    }
    if (state.math) {
      return _closesMath(text) ? LineState.initial : state;
    }
    if (state.frontmatter) {
      return _closesFrontmatter(text) ? LineState.initial : state;
    }
    if (state.html != null) {
      return _closesHtml(text, state) ? LineState.initial : state;
    }
    if (_opensFrontmatter(line, text)) {
      return const LineState(frontmatter: true);
    }
    final fence = _fenceOpen(text);
    if (fence != null) return LineState(fence: fence);
    // Only the multi-line form opens a state: a `$$…$$` written on one line
    // is over on that line, and leaving the state open swallowed whatever
    // followed it.
    if (_isDisplayLineAt(line, text, state) && isDisplayOpen(text.trim())) {
      return const LineState(math: true);
    }
    final html = _htmlOpen(text);
    if (html != null) {
      return LineState(html: html.$1, htmlClosing: html.$2);
    }
    final quoteDepth = _quoteDepthAfter(line, text, state);
    final listStack = _listAfter(text, state);
    return LineState(
      quoteDepth: quoteDepth,
      listStack: listStack,
      table: _tableContinues(line, state),
      indentedCode: _indentedCodeContinues(line, text, state),
    );
  }

  /// The line's text, without a byte-order mark on the first line.
  String _text(int line) {
    final text = buffer.lineAt(line);
    if (line == 0 && text.startsWith('\uFEFF')) return text.substring(1);
    return text;
  }

  // ---------------------------------------------------------------- constructs

  /// The list marker [text] opens with — its start, its width and where the
  /// item's text begins — or null: the scanner's own rule, for a reader
  /// that colours the marker.
  static (int, int, int)? listMarkerOf(String text) => _listMarker(text);

  /// How many `#` open a heading on [text], or 0.
  static int headingLevelOf(String text) => _headingLevel(text);

  /// How many `#` open a heading on [text], or 0.
  static int _headingLevel(String text) {
    var hashes = 0;
    while (hashes < text.length && text.codeUnitAt(hashes) == 0x23) {
      hashes++;
    }
    if (hashes >= 1 &&
        hashes <= 6 &&
        (hashes == text.length || _isSpace(text.codeUnitAt(hashes)))) {
      return hashes;
    }
    return 0;
  }

  /// The fence a line opens, or null.
  static FenceMarker? _fenceOpen(String text) {
    var indent = 0;
    while (indent < 3 &&
        indent < text.length &&
        _isSpace(text.codeUnitAt(indent))) {
      indent++;
    }
    if (indent >= text.length) return null;
    final char = text.codeUnitAt(indent);
    if (char != 0x60 && char != 0x7E) return null;
    var length = 0;
    while (indent + length < text.length &&
        text.codeUnitAt(indent + length) == char) {
      length++;
    }
    if (length < 3) return null;
    final rest = text.substring(indent + length);
    // A backtick fence's info string may not contain a backtick.
    if (char == 0x60 && rest.contains('`')) return null;
    return FenceMarker(char: char, length: length, indent: indent);
  }

  /// Whether [text] closes [fence].
  static bool _isFenceClose(String text, FenceMarker fence) {
    var indent = 0;
    while (indent < 3 &&
        indent < text.length &&
        _isSpace(text.codeUnitAt(indent))) {
      indent++;
    }
    var length = 0;
    while (indent + length < text.length &&
        text.codeUnitAt(indent + length) == fence.char) {
      length++;
    }
    if (length < fence.length) return false;
    return text.substring(indent + length).trim().isEmpty;
  }

  /// The fence's info string: the first word after the fence run, which is the
  /// language a highlighter wants.
  String? _fenceInfo(int line) {
    final text = _text(line);
    final fence = _fenceOpen(text);
    if (fence == null) return null;
    final rest = text.substring(fence.indent + fence.length).trim();
    return rest.isEmpty ? null : rest.split(RegExp(r'\s+')).first;
  }

  /// Whether [text] closes a `$$` block.
  static bool _closesMath(String text) => isDisplayClose(text.trim());

  /// Whether line [line] opens the frontmatter block: only the first line can.
  static bool _opensFrontmatter(int line, String text) =>
      line == 0 && (text.trim() == '---' || text.trim() == '...');

  /// Whether [text] closes the frontmatter.
  static bool _closesFrontmatter(String text) {
    final trimmed = text.trim();
    return trimmed == '---' || trimmed == '...';
  }

  /// The HTML block a line opens, or null.
  static (HtmlBlockKind, String?)? _htmlOpen(String text) {
    final trimmed = text.trimLeft();
    if (!trimmed.startsWith('<')) return null;
    final lower = trimmed.toLowerCase();
    for (final tag in _rawTextTags) {
      if (lower.startsWith('<$tag') &&
          (lower.length == tag.length + 1 ||
              _isSpaceOrEnd(lower.codeUnitAt(tag.length + 1)) ||
              lower.codeUnitAt(tag.length + 1) == 0x3E)) {
        return (HtmlBlockKind.rawText, tag);
      }
    }
    if (trimmed.startsWith('<!--')) return (HtmlBlockKind.comment, null);
    if (trimmed.startsWith('<?')) {
      return (HtmlBlockKind.processingInstruction, null);
    }
    if (trimmed.startsWith('<![CDATA[')) return (HtmlBlockKind.cdata, null);
    if (trimmed.length > 2 &&
        trimmed.startsWith('<!') &&
        _isAsciiLetter(trimmed.codeUnitAt(2))) {
      return (HtmlBlockKind.declaration, null);
    }
    final name = _tagName(trimmed);
    if (name != null && _blockTags.contains(name)) {
      return (HtmlBlockKind.blockTag, null);
    }
    if (name != null && _isCompleteTag(trimmed)) {
      return (HtmlBlockKind.completeTag, null);
    }
    return null;
  }

  /// Whether [text] closes the HTML block [state] opened.
  static bool _closesHtml(String text, LineState state) {
    switch (state.html!) {
      case HtmlBlockKind.rawText:
        return text.toLowerCase().contains('</${state.htmlClosing}>');
      case HtmlBlockKind.comment:
        return text.contains('-->');
      case HtmlBlockKind.processingInstruction:
        return text.contains('?>');
      case HtmlBlockKind.declaration:
        return text.contains('>');
      case HtmlBlockKind.cdata:
        return text.contains(']]>');
      case HtmlBlockKind.blockTag:
      case HtmlBlockKind.completeTag:
        return text.trim().isEmpty;
    }
  }

  /// The tag name a line starts with, lowercased, or null.
  static String? _tagName(String trimmed) {
    var at = 1;
    if (at < trimmed.length && trimmed.codeUnitAt(at) == 0x2F) at++;
    final start = at;
    while (at < trimmed.length) {
      final char = trimmed.codeUnitAt(at);
      if (!_isAsciiLetter(char) && !_isDigit(char)) break;
      at++;
    }
    if (at == start) return null;
    return trimmed.substring(start, at).toLowerCase();
  }

  /// Whether the line is one complete tag and nothing else.
  static bool _isCompleteTag(String trimmed) {
    if (!trimmed.endsWith('>')) return false;
    final name = _tagName(trimmed);
    if (name == null) return false;
    if (_rawTextTags.contains(name)) return false;
    return !trimmed.contains('<', 1);
  }

  /// How deep in blockquotes a line sits, by its own markers.
  static int _quoteDepth(String text) {
    var at = 0;
    var depth = 0;
    while (at < text.length) {
      var spaces = 0;
      while (at + spaces < text.length &&
          spaces < 3 &&
          _isSpace(text.codeUnitAt(at + spaces))) {
        spaces++;
      }
      if (at + spaces >= text.length || text.codeUnitAt(at + spaces) != 0x3E) {
        break;
      }
      depth++;
      at += spaces + 1;
      if (at < text.length && _isSpace(text.codeUnitAt(at))) at++;
    }
    return depth;
  }

  /// The quote depth after [line], keeping a lazily continued paragraph in its
  /// quote.
  static int _quoteDepthAfter(int line, String text, LineState state) {
    final own = _quoteDepth(text);
    if (own > 0) return own;
    if (state.quoteDepth > 0 && text.trim().isNotEmpty) return state.quoteDepth;
    return 0;
  }

  /// Where the item starting at [line] sits in its list.
  ///
  /// A continuation of the list already in progress — the previous block was an
  /// item at the same indent, and both are written as ordered items — keeps
  /// counting. Anything else starts a list, and starts it at the number the
  /// note wrote.
  int _ordinalOf(int line, int listDepth, int quoteDepth, Block? previous) {
    final written = _writtenOrdinal(_text(line));
    // The same list is the same depth in the same quote: an item after a
    // quote's list is a list of its own, not the quote's list counted on.
    if (previous != null &&
        previous.kind == BlockKind.listItem &&
        previous.listDepth == listDepth &&
        previous.quoteDepth == quoteDepth &&
        previous.listOrdinal > 0 &&
        written > 0) {
      return previous.listOrdinal + 1;
    }
    return written;
  }

  /// The number an ordered marker was written with, or 0 for an unordered one.
  static int _writtenOrdinal(String text) {
    final marker = _listMarker(text);
    if (marker == null) return 0;
    final (start, width, _) = marker;
    final slice = text.substring(start, start + width).trim();
    final digits = int.tryParse(slice.replaceAll(RegExp('[^0-9]'), ''));
    return digits ?? 0;
  }

  /// The list marker on [text], or null: its start, width and content indent.
  static (int, int, int)? _listMarker(String text) {
    var at = 0;
    while (at < 3 && at < text.length && _isSpace(text.codeUnitAt(at))) {
      at++;
    }
    if (at >= text.length) return null;
    final char = text.codeUnitAt(at);
    var width = 0;
    if (char == 0x2D || char == 0x2B || char == 0x2A) {
      width = 1;
    } else if (_isDigit(char)) {
      var digits = 0;
      while (at + digits < text.length &&
          digits < 9 &&
          _isDigit(text.codeUnitAt(at + digits))) {
        digits++;
      }
      if (digits == 0 || at + digits >= text.length) return null;
      final delimiter = text.codeUnitAt(at + digits);
      if (delimiter != 0x2E && delimiter != 0x29) return null;
      width = digits + 1;
    } else {
      return null;
    }
    final after = at + width;
    if (after >= text.length) return (at, width, after);
    if (!_isSpace(text.codeUnitAt(after))) return null;
    var padding = 0;
    while (after + padding < text.length &&
        padding < 4 &&
        _isSpace(text.codeUnitAt(after + padding))) {
      padding++;
    }
    if (padding == 0) padding = 1;
    return (at, width, after + padding);
  }

  /// The open list items after [text], given those entering it.
  ///
  /// A marker opens an item: it keeps every open item whose content column it
  /// starts at or past, and closes the rest — an item written to the left of
  /// an open one's content is outside it. What survives is its parents.
  static List<({int marker, int content})> _listAfter(
    String text,
    LineState state,
  ) {
    final marker = _listMarker(text);
    if (marker != null) {
      final (start, _, content) = marker;
      final open = <({int marker, int content})>[];
      for (final item in state.listStack) {
        if (item.content > start) break;
        open.add(item);
      }
      open.add((marker: start, content: content));
      return open;
    }
    if (text.trim().isEmpty) return state.listStack;
    if (state.listStack.isEmpty) return const <({int marker, int content})>[];
    final indent = text.length - text.trimLeft().length;
    return indent >= state.listIndent
        ? state.listStack
        : const <({int marker, int content})>[];
  }

  /// Whether [line] is inside a GFM table.
  bool _isTableRow(int line) {
    final text = _text(line);
    if (text.trim().isEmpty) return false;
    if (_entering[line].table) return _hasPipe(text);
    if (line + 1 >= buffer.lineCount) return false;
    return _hasPipe(text) && _isDelimiterRow(_text(line + 1));
  }

  bool _tableContinues(int line, LineState state) {
    final text = _text(line);
    if (text.trim().isEmpty) return false;
    if (state.table) return _hasPipe(text);
    if (line + 1 >= buffer.lineCount) return false;
    return _hasPipe(text) && _isDelimiterRow(_text(line + 1));
  }

  /// Whether [text] is a table's delimiter row: only `-`, `:`, `|` and spaces,
  /// with at least one `-`.
  static bool _isDelimiterRow(String text) {
    final trimmed = text.trim();
    if (!trimmed.contains('-') || !trimmed.contains('|')) return false;
    if (!_hasPipe(trimmed)) return false;
    for (final rune in trimmed.codeUnits) {
      final ok = rune == 0x2D || rune == 0x3A || rune == 0x7C || _isSpace(rune);
      if (!ok) return false;
    }
    return true;
  }

  static bool _hasPipe(String text) => text.contains('|');

  /// Whether an indented code block opens: four spaces, after a blank line.
  bool _opensIndentedCode(int line, String text) {
    if (text.trim().isEmpty) return false;
    if (text.length - text.trimLeft().length < 4) return false;
    if (_entering[line].listIndent >= 0) return false;
    if (line == 0) return false;
    return _text(line - 1).trim().isEmpty;
  }

  /// Whether an indented code block runs on after [text].
  bool _indentedCodeContinues(int line, String text, LineState state) {
    if (!state.indentedCode) return _opensIndentedCode(line, text);
    if (text.trim().isEmpty) return true;
    return text.length - text.trimLeft().length >= 4;
  }

  static bool _isSpace(int char) => char == 0x20 || char == 0x09;

  static bool _isSpaceOrEnd(int char) => _isSpace(char) || char == 0x0A;

  static bool _isDigit(int char) => char >= 0x30 && char <= 0x39;

  static bool _isAsciiLetter(int char) =>
      (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A);

  static final RegExp _hr = RegExp(
    r'^\s{0,3}((?:-{3,})|(?:\*{3,})|(?:_{3,}))\s*$',
  );

  /// The tags whose content runs to their own closing tag.
  static const Set<String> _rawTextTags = <String>{
    'pre',
    'script',
    'style',
    'textarea',
  };

  /// The block-level tags of HTML block type 6, from the CommonMark spec.
  static const Set<String> _blockTags = <String>{
    'address',
    'article',
    'aside',
    'base',
    'basefont',
    'blockquote',
    'body',
    'caption',
    'center',
    'col',
    'colgroup',
    'dd',
    'details',
    'dialog',
    'dir',
    'div',
    'dl',
    'dt',
    'fieldset',
    'figcaption',
    'figure',
    'footer',
    'form',
    'frame',
    'frameset',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'head',
    'header',
    'hr',
    'html',
    'iframe',
    'legend',
    'li',
    'link',
    'main',
    'menu',
    'menuitem',
    'nav',
    'noframes',
    'ol',
    'optgroup',
    'option',
    'p',
    'param',
    'search',
    'section',
    'summary',
    'table',
    'tbody',
    'td',
    'tfoot',
    'th',
    'thead',
    'title',
    'tr',
    'track',
    'ul',
  };
}

/// Blocks built line by line, as a scan reaches each line.
///
/// A block is a run of lines: the first line says what it is, and each line
/// after it either goes on with it or starts the next one. Built as the scan
/// goes rather than after it, so the scan can ask at any line which block is
/// open — which is what deciding that it has converged needs.
final class _BlockBuilder {
  new(this._scanner, {Block? open, this._before})
    : _open = open,
      openEnd = open?.endLine ?? 0;

  final BlockScanner _scanner;
  final List<Block> _blocks = <Block>[];

  /// The block the next line may go on with. Its own end is not kept up:
  /// the run is [openEnd], and the block is cut there when it closes — a
  /// block a line would be an allocation per line of the note.
  Block? _open;

  /// Where the open block runs to: one past the last line added to it, or
  /// wherever the scan found the old block it turned out to be ending.
  int openEnd;

  /// The last non-blank block before the ones built here.
  final Block? _before;

  /// The block the next line may go on with (its end is not its end).
  Block? get open => _open;

  /// The last non-blank block before the next line: what an item starting
  /// there would count on from.
  Block? get previous {
    final open = _open;
    if (open != null && open.kind != BlockKind.blank) return open;
    for (var at = _blocks.length - 1; at >= 0; at--) {
      if (_blocks[at].kind != BlockKind.blank) return _blocks[at];
    }
    return _before;
  }

  /// Adds [line], whose entering state is recorded.
  void add(int line) {
    final open = _open;
    if (open != null && _scanner._mergesInto(open.kind, open.startLine, line)) {
      openEnd = line + 1;
      return;
    }
    final before = previous;
    _close();
    _open = _scanner._blockStarting(line, before);
    openEnd = line + 1;
  }

  /// The blocks built, the open one closed.
  List<Block> finish() {
    _close();
    return _blocks;
  }

  void _close() {
    final open = _open;
    if (open == null) return;
    _blocks.add(
      open.endLine == openEnd ? open : BlockScanner._cut(open, openEnd),
    );
    _open = null;
  }
}
