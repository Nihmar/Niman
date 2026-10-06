/// Source mode's colours, from the engine the read view draws with.
///
/// The source view used to colour a note with a tokenizer of its own — a
/// line-state machine inherited from the legacy editor — while the read view
/// parsed the same note with the block scanner and the Markdown package. Two
/// readings of one text can disagree, and did: an emphasis the preview drew
/// was plain in the editor, a quoted list was a quote there and a list here.
/// This is the one reading, put on the source view's lines:
///
/// * **the block** a line is in comes from the [BlockScanner] — kept current
///   by the edits, O(change) — and says what the line's structure is: a
///   fence, a heading, a quote's marks, a list item's marker;
/// * **the inline constructs** come from the read view's own reading of that
///   block ([ReadParser]: the tree, our inline parser), each node put back
///   on its line through its leaf's map to the note, its markers apart from
///   its text — what `live` mode hides ([LiveInlines]).
///
/// A parse is kept by the block's *content*, not its position: a keystroke
/// parses the block it landed in, and every other block on screen — moved
/// down a line or not — is the parse it was.
///
/// What comes out is the tokenizer's vocabulary, [Token]s of a [TokenKind],
/// disjoint and sorted, so everything that reads a line's tokens — the
/// painter, the Ctrl+click, the spelling's skip ranges, the fold arrows —
/// reads these the same way. Nesting flattens to the innermost construct.
library;

import 'dart:collection';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/live_inlines.dart';
import 'package:niman/src/markdown/note_reference_cache.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// A note's lines, coloured by the engine's reading of them.
final class SourceStyler {
  /// Reads [buffer] here, now.
  new(this.buffer) : _scanner = BlockScanner(buffer) {
    final holdings = _holdingsOf(
      buffer,
      0,
      buffer.lineCount,
      runningBody: false,
    );
    _definers.addAll(holdings.lines);
    _opensBody.addAll(holdings.running);
    _scope = DocumentScope.ofLines(buffer, buffer.revision, _definers);
  }

  new _adopt(
    this.buffer,
    this._scanner,
    this._scope,
    List<int> definers,
    List<bool> opensBody,
  ) {
    _definers.addAll(definers);
    _opensBody.addAll(opensBody);
  }

  /// Reads [buffer] in an isolate: the scan is O(note), 2 s on a 246 MB one.
  ///
  /// The isolate reads a copy taken by the call, so the answer is of the
  /// revision [buffer] had then; a caller whose buffer moved on since drops
  /// it ([revision] says which it is).
  ///
  /// A note read this way is one long enough for its references to be kept
  /// block by block ([references]), and the isolate reads them too: the
  /// note's first save then hands the index what the edits changed rather
  /// than the whole note's worth of reading.
  static Future<SourceStyler> inBackground(SourceBuffer buffer) async {
    final revision = buffer.revision;
    final (scanner, scope, definers, opensBody, references) = await Isolate.run(
      () {
        final holdings = _holdingsOf(
          buffer,
          0,
          buffer.lineCount,
          runningBody: false,
        );
        final scanner = BlockScanner(buffer);
        final scope = DocumentScope.ofLines(buffer, revision, holdings.lines);
        return (
          scanner,
          scope,
          holdings.lines,
          holdings.running,
          NoteReferenceCache.readAll(scanner.index.blocks, buffer, scope),
        );
      },
    );
    final styler = SourceStyler._adopt(
      buffer,
      BlockScanner.rebound(scanner, buffer),
      scope.on(buffer, revision),
      definers,
      opensBody,
    ).._revision = revision;
    styler._references.adopt(references);
    // The record of what the edits do to the list starts at the list read.
    styler._scanner.takeChanges(styler);
    return styler;
  }

  /// The note's references, block by block, while they are kept: for a
  /// note read in the background ([inBackground]), the long ones whose
  /// reindex they spare.
  final NoteReferenceCache _references = NoteReferenceCache();

  /// The cache behind [references], for the tests that count its reads.
  @visibleForTesting
  NoteReferenceCache get referenceCache => _references;

  /// The parser the references read their blocks with: the colours' own
  /// keeps a count a test reads, of the blocks drawn.
  final BlockParser _referenceParser = BlockParser();

  /// The note's tags and links as of the buffer's revision, for its save
  /// to hand the index — or null when they are not kept (a short note,
  /// whose reindex reads them in no time), or the scan behind them is not
  /// current ([settled]).
  ///
  /// O(blocks) to gather, and the blocks the edits changed since the last
  /// call are read: a save of the 247 MB stress note reads the few blocks
  /// written into, where the reindex read the note (5.1 s, item 8 of
  /// `docs/records/huge-notes.md`).
  NoteReferences? references() {
    if (!_references.kept || revision != buffer.revision || !settled) {
      return null;
    }
    _references.follow(_scanner.takeChanges(this));
    return _references.references(
      _scanner.index.blocks,
      buffer,
      _referenceParser,
      () => _scope,
    );
  }

  /// The text being coloured.
  final SourceBuffer buffer;

  final BlockScanner _scanner;
  late DocumentScope _scope;
  final ReadParser _reader = ReadParser();

  /// How many blocks have been read, for the test that proves a keystroke
  /// reads the block it landed in rather than the screen.
  int get parses => _reader.parseCount;

  /// How many blocks have had their text joined to find their parse, for
  /// the test that proves a frame made after an Enter re-joins none of the
  /// blocks it read on the frame before (#362): a hit in [_byStart] is what
  /// spares the join and the hash of the whole block per line.
  int get blockTextReads => _blockTextReads;
  int _blockTextReads = 0;

  /// The buffer revision the blocks are of.
  int get revision => _revision ?? buffer.revision;
  int? _revision;

  /// Parses by block content, the least recently used dropped past
  /// [_parseCacheSize]: the parse a block has wherever it moved to.
  final LinkedHashMap<String, _Parsed> _parses =
      LinkedHashMap<String, _Parsed>();

  /// Parses by block start line, for the current revision only: the lookup a
  /// frame does per line, without joining the block's text to find it.
  final Map<int, _Parsed> _byStart = <int, _Parsed>{};

  /// The lines that may hold a link or footnote definition, cite a footnote or
  /// run its body on, in order: what an edit is checked against, and all that
  /// is read again when it touches one.
  ///
  /// The citations are here as much as the definitions: their order is the
  /// footnotes' numbering and the order of the section a note ends with, and
  /// a `[^1]` typed mid-sentence left a scope that said otherwise. The
  /// continuation lines are here as much as the definition's own: a footnote
  /// is read across lines (#361). Only a line a footnote definition runs on
  /// to is one — an indented code, verse or list line continues nothing
  /// ([DocumentScope.continuesFootnote]), and holding all of them made every
  /// keystroke in an indented note rescan the note (#496).
  final List<int> _definers = <int>[];

  /// Whether each line of [_definers] leaves a footnote's body running on to
  /// the line under it: a definition that opens one, or a line it runs on
  /// to. What the next line's own membership is read from, in O(log n).
  final List<bool> _opensBody = <bool>[];

  /// How many definition lines the edits have read again here, for the test
  /// that proves a keystroke in indented code rescans none (#496).
  int get definitionLinesRescanned => _definitionLinesRescanned;
  int _definitionLinesRescanned = 0;

  static const int _parseCacheSize = 4096;

  /// A block past this many characters is not inline-parsed: its lines get
  /// their structure and nothing more. A block is read whole whenever it
  /// changes, and a pasted table of this size is one block: a keystroke in
  /// it would read more than a frame affords.
  static const int _inlineLimit = 64 * 1024;

  /// The note's footnotes, in the order they are cited: the section the
  /// read view ends the note with, and `live` too.
  List<Footnote> get footnotes => _scope.footnotes;

  /// The note's link and footnote definitions, for what a footnote's body
  /// cites.
  DocumentScope get scope => _scope;

  /// Whether [block] is nothing but definitions — link references or
  /// footnotes — which the read view does not draw where they stand: a
  /// block of a footnote definition, whatever its kind but blank — blank
  /// lines are the note's spacing — or a paragraph whose parse gave nothing
  /// back. False for a block too long to parse, which is drawn as it is.
  bool definesOnly(Block block) {
    if (block.footnote != 0) return block.kind != BlockKind.blank;
    if (block.kind != BlockKind.paragraph) return false;
    final parsed = _parsedOf(block);
    if (parsed == null) return false;
    final read = parsed.read;
    final node = read.node;
    return node is LeafNode && (read.leaf(node).inline?.isEmpty ?? true);
  }

  /// The lines `[start, end)` of the run of definitions [block] is in, or
  /// null when it is no definition ([definesOnly]): the blocks of
  /// definitions next to it, no blank line between. A footnote definition
  /// ends where a link reference starts, as the parser reads them, and the
  /// caret in one of a run written together still shows the run.
  (int, int)? definitionRunOf(Block block) {
    if (!definesOnly(block)) return null;
    var start = block.startLine;
    var end = block.endLine;
    for (
      var before = blockOf(start - 1);
      before != null && before.endLine == start && definesOnly(before);
      before = blockOf(start - 1)
    ) {
      start = before.startLine;
    }
    for (
      var after = blockOf(end);
      after != null && after.startLine == end && definesOnly(after);
      after = blockOf(end)
    ) {
      end = after.endLine;
    }
    return (start, end);
  }

  /// The line footnote [label]'s definition is on, or null when no line
  /// defines it: where a tap on the footnote puts the caret.
  int? definitionLineOf(String label) {
    final opening = '[^$label]:';
    for (final line in _definers) {
      if (line >= buffer.lineCount) continue;
      if (buffer.lineAt(line).trimLeft().startsWith(opening)) return line;
    }
    return null;
  }

  /// Follows [edit], already made to [buffer].
  void edited(SourceEdit edit) {
    _revision = null;
    _scanner.edited(edit);
    _byStart.clear();
    if (_touchesDefinitions(edit)) {
      _definitionLinesRescanned += _definers.length;
      final scope = DocumentScope.ofLines(buffer, buffer.revision, _definers);
      if (!_sameDefinitions(scope, _scope)) {
        _parses.clear();
        if (_references.kept) {
          // By block index, so on the list as it is now.
          _references
            ..follow(_scanner.takeChanges(this))
            ..definitionsChanged();
        }
      }
      _scope = scope;
    }
  }

  /// The note's headings, read off the scan this styler already keeps.
  ///
  /// What the note view publishes as its outline, from the blocks the
  /// colouring is drawn by rather than from a second walk of the text: see
  /// [outlineOfBlocks]. O(blocks), so it is the note's heading count and
  /// never its length.
  ///
  /// Null while the scan still owes part of the note ([settled]): the outline
  /// is the whole note's, and finishing the scan for it would put back on one
  /// frame the work an edit that changed the rest of the note was spared. The
  /// note view keeps the outline it has, and asks again.
  List<OutlineEntry>? get headings =>
      _scanner.settled ? outlineOfBlocks(_scanner.index, buffer.lineAt) : null;

  /// Whether every line's block is current. An edit that changes the rest of
  /// the note — a `$$` opened, a fence — scans a budget of lines past itself
  /// and leaves the rest to [advance] (`BlockScanner.edited`).
  bool get settled => _scanner.settled;

  /// Carries the scan on for a budget of lines; the lines drawn never wait
  /// for it, because [tokensOf] catches the scan up to the line it colours.
  void advance() => _scanner.advance();

  /// The note's blocks, as the scan behind the colours has them, or null
  /// when the scan is of a revision the buffer has moved on from, or still
  /// owes part of the note ([settled]).
  ///
  /// The same answer the colours are drawn from, for a caller that wants the
  /// blocks themselves. O(blocks): [BlockScanner.index] copies its list.
  ///
  /// Null while the scan still owes the note, the rule [headings] and
  /// [handOver] hold: the reader is a tap on a task box
  /// (`MarkdownSourceViewState._toggleTaskAt`), which asks for the blocks to
  /// decide whether ticking the box carries down its branch, and settling
  /// here would put the rest of the note — the work an edit that changed what
  /// follows was spared — on the tap's frame. The tap falls back to ticking
  /// the one box, and the cascade applies on a later tap, once the scan has
  /// caught up.
  ///
  /// A null [_revision] is the *current* one, as [revision] reads it: a
  /// styler built here has read the buffer as it is, and [edited] follows
  /// every edit into the scan. Testing `_revision` for null answered "not
  /// scanned" for exactly those, so every note small enough to be read here —
  /// and every note after its first keystroke — had no blocks to give.
  List<Block>? get blocks => revision == buffer.revision && _scanner.settled
      ? _scanner.index.blocks
      : null;

  /// How many lines the scan behind the colours has read, for the test that
  /// holds a tap on a task box to the work the tap may do: one that settled
  /// the scan read the rest of the note, and the count says so.
  int get scannedLines => _scanner.scannedLineTotal;

  /// The note's blocks and definitions as of the buffer's revision, for a
  /// reader that would otherwise scan the note for them — or null when this
  /// styler does not have them whole: a scan of a revision the buffer has
  /// moved on from, or one an edit left owed ([settled]), which finishing
  /// here would put the rest of the note on the caller's frame.
  ///
  /// O(blocks): the list is copied, never the note read.
  ///
  /// Each hand-over carries what the edits did to the block list since the
  /// one before ([DocumentScan.changes]), so a reader that keeps something
  /// per block — the read pane's heights — updates what it has. Asking is
  /// therefore taking: the next hand-over counts from this one.
  DocumentScan? handOver() {
    if (revision != buffer.revision || !settled) return null;
    final since = _handedOver;
    final token = _handedOver = Object();
    return DocumentScan(
      blocks: _scanner.index.blocks,
      scope: _scope.on(buffer, buffer.revision),
      revision: buffer.revision,
      changes: (
        since: since,
        token: token,
        stretches: _scanner.takeChanges().stretches,
      ),
    );
  }

  /// The mark of the last hand-over, or null before the first.
  Object? _handedOver;

  /// The block holding [line], scanned up to it when the scan still owes it.
  Block? blockOf(int line) => _scanner.blockAt(line);

  /// The pictures on line [line] — each `![[embed]]` and `![alt](src)` — in
  /// the line's own coordinates, read off the reading its colours come from.
  List<LinePicture> picturesOf(int line) {
    final block = _scanner.blockAt(line);
    if (block == null) return const <LinePicture>[];
    final parsed = _parsedOf(block);
    if (parsed == null) return const <LinePicture>[];
    return parsed.inlines.picturesOn(line - block.startLine);
  }

  /// The target the link covering local offset [start] of [line] resolved
  /// to — the destination the parse gave it, so a reference link
  /// (`[text][label]`, whose own source spells no `](href)`) is followed
  /// from the editor as the read view follows it — or null when no link
  /// covers [start].
  String? linkHrefAt(int line, int start) {
    final block = _scanner.blockAt(line);
    if (block == null) return null;
    final parsed = _parsedOf(block);
    if (parsed == null) return null;
    for (final link in parsed.inlines.linksOn(line - block.startLine)) {
      if (start >= link.start && start <= link.end) return link.href;
    }
    return null;
  }

  /// Line [line]'s tokens, disjoint and sorted.
  List<Token> tokensOf(int line) {
    final block = _scanner.blockAt(line);
    if (block == null) return const <Token>[];
    final text = buffer.lineAt(line);
    final tokens = <InlinePiece>[];
    switch (block.kind) {
      case BlockKind.fencedCode:
        return _fenceTokens(block, line, text);
      case BlockKind.indentedCode:
        return <Token>[Token(TokenKind.codeBlock, 0, text.length)];
      case BlockKind.math:
        return <Token>[Token(TokenKind.mathBlock, 0, text.length)];
      case BlockKind.frontmatter:
        return <Token>[Token(TokenKind.frontmatter, 0, text.length)];
      case BlockKind.thematicBreak:
        return <Token>[Token(TokenKind.horizontalRule, 0, text.length)];
      case BlockKind.blank:
      case BlockKind.html:
        return const <Token>[];
      case BlockKind.heading:
      case BlockKind.paragraph:
      case BlockKind.listItem:
      case BlockKind.quote:
      case BlockKind.table:
        break;
    }
    final prefix = BlockParser.quotePrefixLength(
      text,
      block.quoteDepth,
      BlockParser.itemPrefixLength(block, text),
    );
    final structural = _structure(block, line, text, prefix, tokens);
    final parsed = _parsedOf(block);
    if (parsed != null) {
      tokens.addAll(parsed.inlines.piecesOn(line - block.startLine));
    }
    return _flatten(tokens, structural);
  }

  // ----------------------------------------------------------------- structure

  /// A fence's line: all of it code, and the opening line's language.
  ///
  /// Disjoint, as every line's tokens are: the language cuts the fence line
  /// in three rather than lying on top of it.
  static List<Token> _fenceTokens(Block block, int line, String text) {
    final whole = <Token>[Token(TokenKind.codeFence, 0, text.length)];
    if (line != block.startLine) {
      // The code itself, unless this is the fence that closes the block.
      final closing =
          line == block.endLine - 1 && _closesFence(text.trimLeft());
      return closing
          ? whole
          : <Token>[Token(TokenKind.codeBlock, 0, text.length)];
    }
    final info = block.fenceInfo;
    if (info == null) return whole;
    final at = text.indexOf(info);
    if (at < 0) return whole;
    final end = at + info.length;
    return <Token>[
      Token(TokenKind.codeFence, 0, at),
      Token(TokenKind.codeLanguage, at, end),
      if (end < text.length) Token(TokenKind.codeFence, end, text.length),
    ];
  }

  /// Whether [text], a code block's last line trimmed, is its closing fence
  /// rather than code: a block the note did not close ends on its code.
  static bool _closesFence(String text) =>
      text.startsWith('```') || text.startsWith('~~~');

  /// A quote depth no line reaches: how far a line's own quote marks go.
  static const int _anyDepth = 1 << 16;

  /// The structural marks at the start of [text] — quote marks, a list
  /// marker and its task box, a heading's hashes — added to [out]; answers
  /// where they end, before which no inline token is put.

  static int _structure(
    Block block,
    int line,
    String text,
    int prefix,
    List<InlinePiece> out,
  ) {
    // Every quote mark the line has, not only the block's: a quote that
    // opens at one level and goes a level deeper — `> a` then `> > b` — is one
    // block at the first level, and the second `>` is as much syntax as the
    // first (`live` drew it as text).
    final own = BlockParser.quotePrefixLength(text, _anyDepth);
    final marks = own > prefix ? own : prefix;
    for (var at = 0; at < marks; at++) {
      if (text.codeUnitAt(at) == 0x3E) {
        out.add(InlinePiece(TokenKind.blockquote, at, at + 1, _structural));
      }
    }
    var from = marks;
    final rest = marks == 0 ? text : text.substring(marks);
    final opensItem =
        (block.kind == BlockKind.listItem && line == block.startLine) ||
        block.kind == BlockKind.quote;
    final marker = opensItem ? LineSyntax.listMarkerOf(rest) : null;
    if (marker != null) {
      final (start, width, content) = marker;
      out.add(
        InlinePiece(
          TokenKind.listMarker,
          prefix + start,
          prefix + start + width,
          _structural,
        ),
      );
      from = prefix + content;
      if (from + 3 <= text.length &&
          text.codeUnitAt(from) == 0x5B &&
          _isBoxMark(text.codeUnitAt(from + 1)) &&
          text.codeUnitAt(from + 2) == 0x5D &&
          (from + 3 == text.length || _isSpace(text.codeUnitAt(from + 3)))) {
        out.add(InlinePiece(TokenKind.taskBox, from, from + 3, _structural));
        from += 3;
      }
    }
    // A heading block is one the scanner decided; a quote's inside is not,
    // and a `#` four spaces into it is code, not a heading.
    final heading = LineSyntax.headingMarkerOf(
      from == 0 ? text : text.substring(from),
      block.kind == BlockKind.quote ? 3 : null,
    );
    if (heading != null &&
        (block.kind == BlockKind.heading || block.kind == BlockKind.quote)) {
      // The `#`s where they stand: a heading may be indented, in an item or
      // up to three spaces from the margin, and the spaces are not marker.
      final (start, hashes) = heading;
      out.add(
        InlinePiece(
          TokenKind.headingMarker,
          from + start,
          from + start + hashes,
          _structural,
        ),
      );
      from += start + hashes;
    }
    return from;
  }

  static bool _isBoxMark(int char) =>
      char == 0x20 || char == 0x78 || char == 0x58;

  static bool _isSpace(int char) => char == 0x20 || char == 0x09;

  // -------------------------------------------------------------------- inline

  /// The parse of [block], or null for one too long to parse.
  _Parsed? _parsedOf(Block block) {
    // What the cached parse was made of, not the object it was made from:
    // a block read back from a chunk that carries a shift is a fresh
    // `Block` every time (`BlockList.operator []`), so `identical` never
    // hit below an edit that changed the line count — every visible line
    // re-joined its whole block and hashed it, per frame (#362, #316).
    // Within one revision a block's text is its kind, its depths and its
    // lines, and the map is cleared by every edit.
    final cached = _byStart[block.startLine];
    if (cached != null &&
        cached.block.endLine == block.endLine &&
        cached.block.sameShape(block)) {
      return cached;
    }
    _blockTextReads++;
    final raw = BlockParser.blockText(block, buffer);
    if (raw.length > _inlineLimit) return null;
    // The items' indents too: what the reading makes of a block in a list
    // depends on them (`BlockParser.contentText`); and whether a table goes
    // on with one above, whose head it then has none of.
    final key =
        '${block.kind.index}:${block.quoteDepth}:'
        '${BlockParser.itemKeyOf(block)}:'
        '${block.entering?.table ?? false}|$raw';
    var parsed = _parses.remove(key);
    if (parsed == null || parsed.block.kind != block.kind) {
      final read = _reader.read(block, buffer, scope: _scope);
      parsed = _Parsed(block, read, LiveInlines.of(read, block.startLine));
    } else if (!identical(parsed.block, block)) {
      parsed = _Parsed(block, parsed.read, parsed.inlines);
    }
    _parses[key] = parsed;
    if (_parses.length > _parseCacheSize) _parses.remove(_parses.keys.first);
    _byStart[block.startLine] = parsed;
    return parsed;
  }

  // ------------------------------------------------------------------- flatten

  /// The depth a structural mark wins at: nothing inline overlaps one.
  static const int _structural = 1 << 20;

  /// [pieces], which may nest, as disjoint tokens: each stretch of the line
  /// takes the deepest piece over it. Inline pieces before [structural] are
  /// dropped — the parse sees no marks there.
  static List<Token> _flatten(List<InlinePiece> pieces, int structural) {
    if (pieces.isEmpty) return const <Token>[];
    final cuts = <int>{};
    for (final piece in pieces) {
      cuts
        ..add(piece.start)
        ..add(piece.end);
    }
    final points = cuts.toList()..sort();
    final tokens = <Token>[];
    for (var at = 0; at + 1 < points.length; at++) {
      final from = points[at];
      final to = points[at + 1];
      InlinePiece? best;
      for (final piece in pieces) {
        if (piece.start > from || piece.end < to) continue;
        if (piece.depth < _structural && from < structural) continue;
        if (best == null || piece.depth >= best.depth) best = piece;
      }
      if (best == null) continue;
      final outer = best.depth < _structural
          ? _outerOf(pieces, best, from, to)
          : const <TokenKind>[];
      final last = tokens.isEmpty ? null : tokens.last;
      if (last != null &&
          last.end == from &&
          last.kind == best.kind &&
          last.marker == best.marker &&
          _sameKinds(last.outer, outer) &&
          best.depth < _structural) {
        tokens[tokens.length - 1] = Token(
          last.kind,
          last.start,
          to,
          marker: last.marker,
          outer: last.outer,
        );
      } else {
        tokens.add(
          Token(best.kind, from, to, marker: best.marker, outer: outer),
        );
      }
    }
    return tokens;
  }

  /// The inline constructs around [inner] over `[from, to)`, outermost
  /// first: the text of the pieces shallower than it that cover the stretch,
  /// each kind once. A construct's markers are its own syntax and style
  /// nothing inside it, so a marker piece is none of them.
  static List<TokenKind> _outerOf(
    List<InlinePiece> pieces,
    InlinePiece inner,
    int from,
    int to,
  ) {
    final around = <InlinePiece>[
      for (final piece in pieces)
        if (!identical(piece, inner) &&
            !piece.marker &&
            piece.depth < inner.depth &&
            piece.start <= from &&
            piece.end >= to)
          piece,
    ];
    if (around.isEmpty) return const <TokenKind>[];
    around.sort((a, b) => a.depth.compareTo(b.depth));
    final kinds = <TokenKind>[];
    for (final piece in around) {
      if (piece.kind != inner.kind && !kinds.contains(piece.kind)) {
        kinds.add(piece.kind);
      }
    }
    return kinds.isEmpty ? const <TokenKind>[] : List.unmodifiable(kinds);
  }

  static bool _sameKinds(List<TokenKind> a, List<TokenKind> b) {
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at] != b[at]) return false;
    }
    return true;
  }

  // --------------------------------------------------------------- definitions

  /// The definition candidate lines of `[from, to)` in [buffer], in order:
  /// a definition, a footnote citation, or a line a footnote's body runs on
  /// to. The result says, per line, whether it leaves a footnote's body
  /// running (see [_opensBody]), and that state at [to]; `runningBody` is
  /// that state before [from].
  static _Holdings _holdingsOf(
    SourceBuffer buffer,
    int from,
    int to, {
    required bool runningBody,
  }) {
    final lines = <int>[];
    final running = <bool>[];
    var body = runningBody;
    for (var line = from; line < to; line++) {
      final text = buffer.lineAt(line);
      final opens = DocumentScope.opensDefinition(text);
      final opensFootnote = opens && DocumentScope.definesFootnote(text);
      final continues = body && DocumentScope.continuesFootnote(text);
      if (opens || continues) {
        lines.add(line);
        running.add(opensFootnote || continues);
      }
      body = opensFootnote || continues;
    }
    return (lines: lines, running: running, end: body);
  }

  /// Whether the definer at [line] leaves a footnote's body running, or
  /// false when [line] is no definer.
  bool _opensBodyAt(int line) {
    final at = _lowerBound(_definers, line);
    return at < _definers.length && _definers[at] == line && _opensBody[at];
  }

  /// The first index of [lines] whose value is at least [value].
  static int _lowerBound(List<int> lines, int value) {
    var low = 0;
    var high = lines.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (lines[middle] < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  /// Whether [edit] removed or wrote a line that can be a definition, cite a
  /// footnote or run a footnote's body, with [_definers] and [_opensBody]
  /// moved to the lines after it.
  bool _touchesDefinitions(SourceEdit edit) {
    final first = edit.firstLine;
    final delta = edit.lineDelta;
    final untouchedOld = edit.firstUntouchedLine;
    final untouchedNew = first + edit.insertedLines;

    final low = _lowerBound(_definers, first);
    final oldBody = untouchedOld > 0 && _opensBodyAt(untouchedOld - 1);
    final holdings = _holdingsOf(
      buffer,
      first,
      untouchedNew,
      runningBody: first > 0 && _opensBodyAt(first - 1),
    );

    // The lines after the edit keep what they held only when the footnote
    // body the edit starts from is still running at the surviving line; when
    // it is not, the indented run under the edit changed what it holds, and
    // is read to its end — as a run a body is running on to holds all of it,
    // and as one no body runs on to holds only what cites a footnote or
    // defines one on its own (the line an ended body leaves behind may
    // still be a citation).
    var stop = untouchedNew;
    if (holdings.end != oldBody) {
      while (stop < buffer.lineCount &&
          DocumentScope.continuesFootnote(buffer.lineAt(stop))) {
        stop++;
      }
      final run = _holdingsOf(
        buffer,
        untouchedNew,
        stop,
        runningBody: holdings.end,
      );
      holdings.lines.addAll(run.lines);
      holdings.running.addAll(run.running);
    }
    final keepFrom = _lowerBound(_definers, stop - delta);
    final touched = keepFrom > low || holdings.lines.isNotEmpty;
    if (delta != 0) {
      for (var at = keepFrom; at < _definers.length; at++) {
        _definers[at] += delta;
      }
    }
    _definers.replaceRange(low, keepFrom, holdings.lines);
    _opensBody.replaceRange(low, keepFrom, holdings.running);
    return touched;
  }

  static bool _sameDefinitions(DocumentScope a, DocumentScope b) {
    if (a.links.length != b.links.length) return false;
    if (a.footnoteCounts.length != b.footnoteCounts.length) return false;
    for (final entry in a.links.entries) {
      final other = b.links[entry.key];
      if (other == null ||
          other.destination != entry.value.destination ||
          other.title != entry.value.title) {
        return false;
      }
    }
    for (final entry in a.footnoteCounts.entries) {
      if (b.footnoteCounts[entry.key] != entry.value) return false;
    }
    if (a.footnoteLabels.length != b.footnoteLabels.length) return false;
    for (var at = 0; at < a.footnoteLabels.length; at++) {
      if (a.footnoteLabels[at] != b.footnoteLabels[at]) return false;
    }
    return true;
  }
}

/// A run of a note's definition candidate lines: the lines, whether each
/// leaves a footnote's body running, and that state at the run's end.
typedef _Holdings = ({List<int> lines, List<bool> running, bool end});

/// A block's reading, and its constructs line by line, counted from the
/// block's first line: the same wherever the block moved to.
final class _Parsed {
  new(this.block, this.read, this.inlines);

  final Block block;
  final ReadBlock read;
  final LiveInlines inlines;
}
