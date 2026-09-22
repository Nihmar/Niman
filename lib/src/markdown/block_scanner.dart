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
  /// Scans [buffer] from the top.
  new(this.buffer) {
    _rescanFrom(0);
  }

  /// [scanned]'s answer, for [buffer]: a scan made of a copy of the note —
  /// in an isolate — taken over by the note itself, without scanning again.
  ///
  /// The two must hold the same lines, which is the caller's to promise.
  new rebound(BlockScanner scanned, this.buffer) {
    scanned._settle(scanned._blocks.length);
    _entering.addAll(scanned._entering);
    _blocks.addAll(scanned._blocks);
    _lineCount = scanned._lineCount;
    _shiftFrom = _blocks.length;
  }

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
  BlockIndex get index {
    _settle(_blocks.length);
    return BlockIndex(
      blocks: List<Block>.unmodifiable(_blocks),
      revision: buffer.revision,
    );
  }

  /// How many lines have a recorded state. Everything up to here is current.
  int get scannedLines => _entering.length;

  /// The line count at the last scan.
  int _lineCount = 0;

  /// How many lines the last scan covered.
  int get scannedLineCount => _lineCount;

  /// How many times a line's state has been computed, for the tests that prove
  /// an edit is O(change) rather than O(document).
  int get scannedLineTotal => _scannedLineTotal;
  int _scannedLineTotal = 0;

  /// The state entering [line]. O(1), and only valid below [scannedLines].
  LineState stateEntering(int line) => _entering[line];

  /// The block holding [line], or null past the note's end. O(log blocks),
  /// and without the copy [index] makes.
  Block? blockAt(int line) {
    if (_blocks.isEmpty || line < 0) return null;
    final at = _firstIndexWhere(0, (block) => block.startLine > line) - 1;
    if (at < 0) return null;
    final block = _at(at);
    return block.contains(line) ? block : null;
  }

  /// Re-scans after [edit].
  ///
  /// Blocks entirely before the edit are kept, blocks entirely after the
  /// converged boundary are kept, and the region between is rebuilt. The
  /// boundary is the first line past the edit whose entering state is unchanged
  /// and which the previous line's blankness makes a block boundary, so no
  /// block can span it.
  void edited(SourceEdit edit) {
    // Back up to the start of the block the edit landed in: the block list is
    // rebuilt from there, and a block spanning the edit would otherwise lose
    // the part of itself before it.
    // By binary search: a walk over the blocks was a keystroke's cost on a
    // note of millions of them.
    final from = blockAt(edit.firstLine)?.startLine ?? edit.firstLine;
    _rescanFrom(from, edit);
  }

  /// Re-scans from [from], given what [edit] did (or nothing, for the first
  /// scan).
  ///
  /// The kept states and blocks are brought into the new line coordinates
  /// first: an edit that removed lines leaves every line number after it
  /// stale, and comparing stale numbers with fresh ones is exactly how a
  /// scanner ends up with blocks that overlap themselves.
  void _rescanFrom(int from, [SourceEdit? edit]) {
    // Which blocks survive, and where the survivors are, found by binary
    // search rather than by walking the list: the block list is the one
    // structure here whose size is the document's, so a pass over it per
    // keystroke is the difference between a screen-shaped cost and a
    // document-shaped one.
    var headEnd = 0;
    var tailStart = _blocks.length;
    if (edit != null) {
      final untouched = edit.firstUntouchedLine;
      if (edit.firstLine < _entering.length) {
        _replaceStates(
          edit.firstLine,
          (untouched > _entering.length ? _entering.length : untouched) -
              edit.firstLine,
          edit.insertedLines,
        );
      }
      headEnd = _firstIndexWhere(0, (block) => block.endLine > edit.firstLine);
      tailStart = _firstIndexWhere(0, (block) => block.startLine >= untouched);
      // The survivors after the edit are the same blocks, moved by however
      // many lines the document gained or lost — owed, not moved ([_owe]):
      // everything below reads them where they are now.
      if (edit.lineDelta != 0) _owe(tailStart, edit.lineDelta);
    }

    // The block that ends where the rebuild begins has to be rebuilt too.
    // Whether two adjacent lines are one block or two depends on the pair — a
    // paragraph that runs on, a quote continued lazily — so a rebuild that
    // starts at a block's end would produce a second block where the first
    // belongs. Widening by one block costs one block's lines and removes the
    // whole class of boundary bugs.
    // The rebuild begins at the first line of the block the edit is in, since
    // starting at the edit would make the rest of that block a block of its
    // own. Unless the block holds one state throughout: then the lines
    // between its first line and the edit are the same lines still entered in
    // that state, their states are recomputed rather than walked, and the
    // rebuild starts at the edit — with the block's prefix kept and joined to
    // what the rebuild makes, so the list goes on tiling the note
    // (docs/dev/huge-notes.md item 3: a keystroke inside a 137 k-line `$$…$$`
    // block re-scanned all 137 k).
    var start = from;
    Block? prefix;
    var narrowed = false;
    if (headEnd > 0) {
      final candidate = _at(headEnd - 1);
      if (candidate.endLine == from) {
        headEnd--;
        start = candidate.startLine;
        final inside =
            edit != null &&
            edit.lineDelta == 0 &&
            start < from &&
            _holdsOneState(candidate.kind);
        if (inside) {
          // The lines between the block's first line and the edit, given the
          // state each of them is entered in. The result has to be the state
          // the note recorded for the edit's own line — that is what says the
          // lines before the edit really are the same lines, and it is the
          // only check that can catch a block whose shape the edit changed
          // without the block being rebuilt.
          var probing = _exitOf(start);
          for (var at = start + 1; at < from; at++) {
            _setEntering(at, probing);
            probing = _exitOf(at);
          }
          if (from < _entering.length && _entering[from] == probing) {
            prefix = candidate;
            start = from;
            narrowed = true;
          } else if (from > 0) {
            _setEntering(from, probing);
          }
        }
      }
    }

    var line = start;
    var state = start == 0 ? LineState.initial : _exitOf(start - 1);

    while (line < buffer.lineCount) {
      final previous = line < _entering.length ? _entering[line] : null;
      if (line > start &&
          previous == state &&
          _isBlockBoundary(line, state) &&
          _hasBoundaryAt(line, tailStart)) {
        // Converged: the state is what it was, nothing is continuing across
        // this line, and the block list already has a boundary here — so the
        // blocks after it are untouched and can be kept as they are.
        break;
      }
      _setEntering(line, state);
      state = _exitOf(line);
      line++;
    }
    _scannedLineTotal += line - start;

    var rebuilt = _buildBlocks(start, line);
    // The block that was already there before the edit, joined to what the
    // rebuild made of the rest when the two make one block — a paragraph's
    // second line, a quote's lazy continuation. The splice takes the old
    // block's place either way, so the list keeps tiling the note.
    if (narrowed && prefix != null) {
      if (rebuilt.isNotEmpty) {
        final first = rebuilt.first;
        if (first.kind == prefix.kind &&
            _mergesInto(prefix.kind, from - 1, from)) {
          rebuilt = <Block>[
            Block(
              kind: prefix.kind,
              startLine: prefix.startLine,
              endLine: first.endLine,
              quoteDepth: prefix.quoteDepth,
              listDepth: prefix.listDepth,
              listOrdinal: prefix.listOrdinal,
              headingLevel: prefix.headingLevel,
              fenceInfo: prefix.fenceInfo,
              entering: prefix.entering,
            ),
            ...rebuilt.skip(1),
          ];
        } else {
          rebuilt = <Block>[_prefixOf(prefix, from), ...rebuilt];
        }
      } else {
        rebuilt = <Block>[_prefixOf(prefix, from)];
      }
    }

    // Everything from the convergence point on is what it was, so the
    // survivors are spliced back in place instead of being copied into a new
    // list: one range replacement, and the blocks inside the edit — the ones
    // between the head and the tail — are what it drops.
    final keepFrom = _firstIndexWhere(
      tailStart,
      (block) => block.startLine >= line,
    );
    // The dropped blocks are the ones between the head and the kept tail;
    // anything owed a shift among them is paid first, so what is owed after
    // the splice is owed from the kept tail on, exactly.
    if (_shiftFrom < keepFrom) _settle(keepFrom);
    _blocks.replaceRange(headEnd, keepFrom, rebuilt);
    _shiftFrom += rebuilt.length - (keepFrom - headEnd);
    // The states recorded after the convergence point are *kept*: convergence
    // means they are what they were, and a later edit down there needs the
    // state entering its block. Only the entries past the document's end go,
    // which is what a deletion leaves behind.
    if (_entering.length > buffer.lineCount) {
      _entering.removeRange(buffer.lineCount, _entering.length);
    }
    _lineCount = buffer.lineCount;
  }

  /// Whether every line of a [kind] block is entered in the state the block
  /// was: the shapes whose merge rule is "the next line is the same kind".
  ///
  /// A quote counts its depth per line and a list item its own marker, so a
  /// line inside one of those is not the block's state and a rebuild cannot
  /// give it one.
  static bool _holdsOneState(BlockKind kind) => switch (kind) {
    BlockKind.quote || BlockKind.listItem => false,
    _ => true,
  };

  /// [block] as it was before [end]: the run it covered up to a line inside
  /// it, which is what an edit leaves of the block it landed in.
  static Block _prefixOf(Block block, int end) => Block(
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
  bool _isBlockBoundary(int line, LineState state) {
    if (!state.isPlain || state.quoteDepth != 0 || state.listIndent >= 0) {
      return false;
    }
    if (state.table) return false;
    if (line == 0) return true;
    return _text(line - 1).trim().isEmpty;
  }

  /// The blocks covering `[from, to)`.
  List<Block> _buildBlocks(int from, int to) {
    final blocks = <Block>[];
    var line = from;
    while (line < to) {
      final kind = _kindOf(line);
      // The depth *on* the line, not the one entering it: a quote's first line
      // has no depth before its own `>`, so taking the entering state left
      // every quote block at depth 0 — which made the renderer draw it as an
      // unnested quote and the parser read the `>` as text.
      final quoteDepth = _quoteDepthAfter(line, _text(line), _entering[line]);
      // The depth *on* the line, like the quote's: the state entering a marker
      // line describes the item before it, so a block that took its depth from
      // there was drawn at the previous item's indent — siblings at different
      // indents, the item after a sublist pushed right (device report,
      // 2026-09-21).
      final listStack = _listAfter(_text(line), _entering[line]);
      final listDepth = listStack.isEmpty ? -1 : listStack.length - 1;
      var end = line + 1;
      while (end < to && _mergesInto(kind, line, end)) {
        end++;
      }
      // An ordered list counts from its first item on, wherever the list
      // starts; a list written `1. 1. 1.` renders 1, 2, 3, which is CommonMark
      // and what the preview draws. The count lives here because this is where
      // the *list* is still visible: a block knows only its own item.
      // The previous *item*, not merely the previous block: a blank line
      // between two items is a `blank` block, and looking only one back would
      // reset the count on every loose list — which is exactly the shape a
      // numbered list takes in a note written with air in it.
      Block? previous;
      for (var back = blocks.length - 1; back >= 0; back--) {
        if (blocks[back].kind != BlockKind.blank) {
          previous = blocks[back];
          break;
        }
      }
      final ordinal = kind == BlockKind.listItem
          ? _ordinalOf(line, listDepth, previous)
          : 0;
      blocks.add(
        Block(
          kind: kind,
          startLine: line,
          endLine: end,
          quoteDepth: quoteDepth,
          listDepth: listDepth,
          listOrdinal: ordinal,
          headingLevel: kind == BlockKind.heading
              ? _headingLevel(_text(line))
              : 0,
          fenceInfo: kind == BlockKind.fencedCode ? _fenceInfo(line) : null,
          entering: _entering[line],
        ),
      );
      line = end;
    }
    return blocks;
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
  int _ordinalOf(int line, int listDepth, Block? previous) {
    final written = _writtenOrdinal(_text(line));
    if (previous != null &&
        previous.kind == BlockKind.listItem &&
        previous.listDepth == listDepth &&
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
