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

  /// The text being scanned.
  final SourceBuffer buffer;

  /// The state entering each scanned line.
  final List<LineState> _entering = <LineState>[];

  /// The blocks of the scanned prefix, in line order.
  ///
  /// Final, and spliced in place: the list is the one structure here whose size
  /// is the document's, so an edit replaces a range of it rather than building
  /// a new one.
  final List<Block> _blocks = <Block>[];

  /// The blocks as of [SourceBuffer.revision], for a reader that wants them.
  BlockIndex get index => BlockIndex(
    blocks: List<Block>.unmodifiable(_blocks),
    revision: buffer.revision,
  );

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
    var from = edit.firstLine;
    for (final block in _blocks) {
      if (block.contains(edit.firstLine)) {
        from = block.startLine;
        break;
      }
    }
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
        _entering.removeRange(
          edit.firstLine,
          untouched > _entering.length ? _entering.length : untouched,
        );
        if (edit.insertedLines > 0) {
          _entering.insertAll(
            edit.firstLine,
            List<LineState>.filled(edit.insertedLines, LineState.initial),
          );
        }
      }
      headEnd = _firstIndexWhere(0, (block) => block.endLine > edit.firstLine);
      tailStart = _firstIndexWhere(0, (block) => block.startLine >= untouched);
      // The survivors after the edit are the same blocks, moved by however
      // many lines the document gained or lost. They are shifted in place:
      // everything below compares line numbers.
      if (edit.lineDelta != 0) {
        for (var at = tailStart; at < _blocks.length; at++) {
          _blocks[at] = _blocks[at].shifted(edit.lineDelta);
        }
      }
    }

    // The block that ends where the rebuild begins has to be rebuilt too.
    // Whether two adjacent lines are one block or two depends on the pair — a
    // paragraph that runs on, a quote continued lazily — so a rebuild that
    // starts at a block's end would produce a second block where the first
    // belongs. Widening by one block costs one block's lines and removes the
    // whole class of boundary bugs.
    var start = from;
    if (headEnd > 0 && _blocks[headEnd - 1].endLine == from) {
      headEnd--;
      start = _blocks[headEnd].startLine;
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

    final rebuilt = _buildBlocks(start, line);
    // Everything from the convergence point on is what it was, so the
    // survivors are spliced back in place instead of being copied into a new
    // list: one range replacement, and the blocks inside the edit — the ones
    // between the head and the tail — are what it drops.
    final keepFrom = _firstIndexWhere(
      tailStart,
      (block) => block.startLine >= line,
    );
    _blocks.replaceRange(headEnd, keepFrom, rebuilt);
    // The states recorded after the convergence point are *kept*: convergence
    // means they are what they were, and a later edit down there needs the
    // state entering its block. Only the entries past the document's end go,
    // which is what a deletion leaves behind.
    if (_entering.length > buffer.lineCount) {
      _entering.removeRange(buffer.lineCount, _entering.length);
    }
    _lineCount = buffer.lineCount;
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
      if (test(_blocks[middle])) {
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
    return at < _blocks.length && _blocks[at].startLine == line;
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
      final quoteDepth = _entering[line].quoteDepth;
      final listIndent = _entering[line].listIndent;
      var end = line + 1;
      while (end < to && _mergesInto(kind, line, end)) {
        end++;
      }
      blocks.add(
        Block(
          kind: kind,
          startLine: line,
          endLine: end,
          quoteDepth: quoteDepth,
          listIndent: listIndent,
          headingLevel: kind == BlockKind.heading
              ? _headingLevel(_text(line))
              : 0,
          fenceInfo: kind == BlockKind.fencedCode ? _fenceInfo(line) : null,
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
      case BlockKind.math:
      case BlockKind.frontmatter:
      case BlockKind.html:
      case BlockKind.table:
      case BlockKind.blank:
        return _kindOf(end) == kind;
    }
  }

  /// What line [line] is.
  BlockKind _kindOf(int line) {
    final state = _entering[line];
    final text = _text(line);
    if (state.fence != null || _fenceOpen(text) != null) {
      return BlockKind.fencedCode;
    }
    if (state.math || _opensMath(text)) return BlockKind.math;
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
    if (_opensMath(text)) return const LineState(math: true);
    final html = _htmlOpen(text);
    if (html != null) {
      return LineState(html: html.$1, htmlClosing: html.$2);
    }
    final quoteDepth = _quoteDepthAfter(line, text, state);
    final listIndent = _listIndentAfter(text, state);
    return LineState(
      quoteDepth: quoteDepth,
      listIndent: listIndent,
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

  /// Whether a `$$` block opens on [text].
  static bool _opensMath(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith(r'$$') && !_isSingleLineMath(trimmed);
  }

  /// Whether [text] closes a `$$` block.
  static bool _closesMath(String text) => text.trim().startsWith(r'$$');

  /// A `$$…$$` that opens and closes on one line is inline, not a block.
  static bool _isSingleLineMath(String trimmed) =>
      trimmed.length > 4 &&
      trimmed.endsWith(r'$$') &&
      !trimmed.substring(2, trimmed.length - 2).contains(r'$$');

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

  /// The list item's content indentation after the line, or -1.
  static int _listIndentAfter(String text, LineState state) {
    final marker = _listMarker(text);
    if (marker != null) return marker.$3;
    if (text.trim().isEmpty) return state.listIndent;
    if (state.listIndent < 0) return -1;
    final indent = text.length - text.trimLeft().length;
    return indent >= state.listIndent ? state.listIndent : -1;
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
