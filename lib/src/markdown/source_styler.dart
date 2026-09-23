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
/// * **the inline runs** come from the [BlockParser]'s parse of that block,
///   the read view's own, put back on the line through the quote marks the
///   parse took off; each run already knows its markers from its text, so
///   they come out as tokens of their own — what `live` mode hides.
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

import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/parsed_block.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/style_run.dart';

/// A picture on a line: where its source is, in the line's coordinates, what
/// it points at, what stands in for it, and the source as written.
typedef LinePicture = ({
  int start,
  int end,
  String target,
  String display,
  String source,
});

/// A note's lines, coloured by the engine's reading of them.
final class SourceStyler {
  /// Reads [buffer] here, now.
  new(this.buffer)
    : _scanner = BlockScanner(buffer),
      _scope = DocumentScope.scan(buffer, buffer.revision) {
    _definers.addAll(_definersOf(buffer));
  }

  new _adopt(this.buffer, this._scanner, this._scope, List<int> definers) {
    _definers.addAll(definers);
  }

  /// Reads [buffer] in an isolate: the scan is O(note), 2 s on a 246 MB one.
  ///
  /// The isolate reads a copy taken by the call, so the answer is of the
  /// revision [buffer] had then; a caller whose buffer moved on since drops
  /// it ([revision] says which it is).
  static Future<SourceStyler> inBackground(SourceBuffer buffer) async {
    final revision = buffer.revision;
    final (scanner, scope, definers) = await Isolate.run(
      () => (
        BlockScanner(buffer),
        DocumentScope.scan(buffer, revision),
        _definersOf(buffer),
      ),
    );
    return SourceStyler._adopt(
      buffer,
      BlockScanner.rebound(scanner, buffer),
      scope.on(buffer, revision),
      definers,
    ).._revision = revision;
  }

  /// The text being coloured.
  final SourceBuffer buffer;

  final BlockScanner _scanner;
  DocumentScope _scope;
  final BlockParser _parser = BlockParser();

  /// How many blocks have been parsed, for the test that proves a keystroke
  /// parses the block it landed in rather than the screen.
  int get parses => _parser.parseCount;

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

  /// The lines that may hold a link or footnote definition, in order: what
  /// an edit is checked against before the note is scanned for definitions
  /// again.
  final List<int> _definers = <int>[];

  static const int _parseCacheSize = 4096;

  /// A block past this many characters is not inline-parsed: its lines get
  /// their structure and nothing more. The parse is super-linear on some
  /// shapes, and a pasted table of this size is one block.
  static const int _inlineLimit = 64 * 1024;

  /// Follows [edit], already made to [buffer].
  void edited(SourceEdit edit) {
    _revision = null;
    _scanner.edited(edit);
    _byStart.clear();
    if (_touchesDefinitions(edit)) {
      final scope = DocumentScope.scan(buffer, buffer.revision);
      if (!_sameDefinitions(scope, _scope)) _parses.clear();
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
  /// when the scan is of a revision the buffer has moved on from.
  ///
  /// The same answer the colours are drawn from, for a caller that wants the
  /// blocks themselves. O(blocks): [BlockScanner.index] copies its list.
  ///
  /// A null [_revision] is the *current* one, as [revision] reads it: a
  /// styler built here has read the buffer as it is, and [edited] follows
  /// every edit into the scan. Testing `_revision` for null answered "not
  /// scanned" for exactly those, so every note small enough to be read here —
  /// and every note after its first keystroke — had no blocks to give.
  List<Block>? get blocks =>
      revision == buffer.revision ? _scanner.index.blocks : null;

  /// The block holding [line], scanned up to it when the scan still owes it.
  Block? blockOf(int line) => _scanner.blockAt(line);

  /// The pictures on line [line] — each `![[embed]]` and `![alt](src)` — in
  /// the line's own coordinates, read off the parse its colours come from.
  List<LinePicture> picturesOf(int line) {
    final block = _scanner.blockAt(line);
    if (block == null) return const <LinePicture>[];
    final parsed = _parsedOf(block);
    if (parsed == null) return const <LinePicture>[];
    final index = line - block.startLine;
    if (index < 0 || index >= parsed.lineStarts.length) {
      return const <LinePicture>[];
    }
    final start = parsed.lineStarts[index];
    final end = index + 1 < parsed.lineStarts.length
        ? parsed.lineStarts[index + 1] - 1
        : parsed.parse.text.length;
    final prefix = BlockParser.quotePrefixLength(
      buffer.lineAt(line),
      block.quoteDepth,
    );
    final text = parsed.parse.text;
    final out = <LinePicture>[];
    for (final span in parsed.parse.extensions) {
      if (span.kind != ExtensionKind.embed) continue;
      if (span.start < start || span.end > end) continue;
      final inner = span.inner;
      final pipe = inner.indexOf('|');
      final target = (pipe >= 0 ? inner.substring(0, pipe) : inner).trim();
      final alias = pipe >= 0 ? inner.substring(pipe + 1).trim() : '';
      out.add((
        start: span.start - start + prefix,
        end: span.end - start + prefix,
        target: target,
        display: alias.isEmpty ? target : alias,
        source: span.text,
      ));
    }
    for (final run in parsed.parse.runs) {
      final href = run.href;
      if (run.kind != StyleKind.image || href == null) continue;
      if (run.start < start || run.end > end) continue;
      out.add((
        start: run.start - start + prefix,
        end: run.end - start + prefix,
        target: href,
        display: text.substring(run.innerStart, run.innerEnd),
        source: text.substring(run.start, run.end),
      ));
    }
    out.sort((a, b) => a.start.compareTo(b.start));
    return out;
  }

  /// Line [line]'s tokens, disjoint and sorted.
  List<Token> tokensOf(int line) {
    final block = _scanner.blockAt(line);
    if (block == null) return const <Token>[];
    final text = buffer.lineAt(line);
    final tokens = <_Piece>[];
    switch (block.kind) {
      case BlockKind.fencedCode:
        return _fenceTokens(block, line, text);
      case BlockKind.indentedCode:
        return <Token>[Token(TokenKind.codeFence, 0, text.length)];
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
    final prefix = BlockParser.quotePrefixLength(text, block.quoteDepth);
    final structural = _structure(block, line, text, prefix, tokens);
    final parsed = _parsedOf(block);
    if (parsed != null) _inline(parsed, line - block.startLine, prefix, tokens);
    return _flatten(tokens, structural);
  }

  // ----------------------------------------------------------------- structure

  /// A fence's line: all of it code, and the opening line's language.
  ///
  /// Disjoint, as every line's tokens are: the language cuts the fence line
  /// in three rather than lying on top of it.
  static List<Token> _fenceTokens(Block block, int line, String text) {
    final whole = <Token>[Token(TokenKind.codeFence, 0, text.length)];
    if (line != block.startLine) return whole;
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
    List<_Piece> out,
  ) {
    // Every quote mark the line has, not only the block's: a quote that
    // opens at one level and goes a level deeper — `> a` then `> > b` — is one
    // block at the first level, and the second `>` is as much syntax as the
    // first (`live` drew it as text).
    final own = BlockParser.quotePrefixLength(text, _anyDepth);
    final marks = own > prefix ? own : prefix;
    for (var at = 0; at < marks; at++) {
      if (text.codeUnitAt(at) == 0x3E) {
        out.add(_Piece(TokenKind.blockquote, at, at + 1, _structural));
      }
    }
    var from = marks;
    final rest = marks == 0 ? text : text.substring(marks);
    final opensItem =
        (block.kind == BlockKind.listItem && line == block.startLine) ||
        block.kind == BlockKind.quote;
    final marker = opensItem ? BlockScanner.listMarkerOf(rest) : null;
    if (marker != null) {
      final (start, width, content) = marker;
      out.add(
        _Piece(
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
        out.add(_Piece(TokenKind.taskBox, from, from + 3, _structural));
        from += 3;
      }
    }
    final hashes = BlockScanner.headingLevelOf(
      from == 0 ? text : text.substring(from),
    );
    if (hashes > 0 &&
        (block.kind == BlockKind.heading || block.kind == BlockKind.quote)) {
      out.add(
        _Piece(TokenKind.headingMarker, from, from + hashes, _structural),
      );
      from += hashes;
    }
    return from;
  }

  static bool _isBoxMark(int char) =>
      char == 0x20 || char == 0x78 || char == 0x58;

  static bool _isSpace(int char) => char == 0x20 || char == 0x09;

  // -------------------------------------------------------------------- inline

  /// The parse of [block], or null for one too long to parse.
  _Parsed? _parsedOf(Block block) {
    final cached = _byStart[block.startLine];
    if (cached != null && identical(cached.block, block)) return cached;
    final raw = BlockParser.blockText(block, buffer);
    if (raw.length > _inlineLimit) return null;
    final key = '${block.kind.index}:${block.quoteDepth}|$raw';
    var parsed = _parses.remove(key);
    if (parsed == null || parsed.block.kind != block.kind) {
      parsed = _Parsed(block, _parser.parseText(block, raw, () => _scope));
    } else if (!identical(parsed.block, block)) {
      parsed = _Parsed(block, parsed.parse);
    }
    _parses[key] = parsed;
    if (_parses.length > _parseCacheSize) _parses.remove(_parses.keys.first);
    _byStart[block.startLine] = parsed;
    return parsed;
  }

  /// The runs and the masked spans of [parsed] that fall on its line [index],
  /// added to [out] in the line's coordinates.
  static void _inline(_Parsed parsed, int index, int prefix, List<_Piece> out) {
    final start = parsed.lineStarts[index];
    final end = index + 1 < parsed.lineStarts.length
        ? parsed.lineStarts[index + 1] - 1
        : parsed.parse.text.length;
    void add(
      TokenKind kind,
      int from,
      int to,
      int depth, {
      bool marker = false,
    }) {
      final a = from < start ? start : from;
      final b = to > end ? end : to;
      if (a >= b) return;
      out.add(
        _Piece(
          kind,
          a - start + prefix,
          b - start + prefix,
          depth,
          marker: marker,
        ),
      );
    }

    for (final run in parsed.parse.runs) {
      final kind = _tokenKindOf(run.kind);
      if (kind == null) continue;
      if (run.end <= start || run.start >= end) continue;
      add(kind, run.start, run.innerStart, run.depth, marker: true);
      add(kind, run.innerStart, run.innerEnd, run.depth);
      add(kind, run.innerEnd, run.end, run.depth, marker: true);
    }
    for (final span in parsed.parse.extensions) {
      if (span.end <= start || span.start >= end) continue;
      final kind = _extensionKindOf(span.kind);
      final (open, close) = _extensionMarkers(span);
      add(kind, span.start, span.start + open, _extension, marker: true);
      add(kind, span.start + open, span.end - close, _extension);
      add(kind, span.end - close, span.end, _extension, marker: true);
    }
  }

  static TokenKind? _tokenKindOf(StyleKind kind) => switch (kind) {
    StyleKind.emphasis => TokenKind.italic,
    StyleKind.strong => TokenKind.bold,
    StyleKind.strikethrough => TokenKind.strike,
    StyleKind.underline => TokenKind.underline,
    StyleKind.superscript => TokenKind.superscript,
    StyleKind.subscript => TokenKind.subscript,
    StyleKind.code => TokenKind.codeInline,
    StyleKind.link => TokenKind.link,
    StyleKind.image => TokenKind.image,
    StyleKind.plain || StyleKind.heading || StyleKind.hardBreak => null,
  };

  static TokenKind _extensionKindOf(ExtensionKind kind) => switch (kind) {
    ExtensionKind.inlineMath => TokenKind.mathInline,
    ExtensionKind.displayMath => TokenKind.mathInline,
    ExtensionKind.wikilink || ExtensionKind.embed => TokenKind.wikilink,
    ExtensionKind.tag => TokenKind.tag,
    ExtensionKind.codeSpan => TokenKind.codeInline,
  };

  /// How many characters open and close [span]: its backticks, its dollars,
  /// its brackets. A tag has none — its `#` is what makes it read as one.
  static (int, int) _extensionMarkers(ExtensionSpan span) {
    final text = span.text;
    switch (span.kind) {
      case ExtensionKind.codeSpan:
        var ticks = 0;
        while (ticks < text.length && text.codeUnitAt(ticks) == 0x60) {
          ticks++;
        }
        return ticks * 2 <= text.length ? (ticks, ticks) : (0, 0);
      case ExtensionKind.displayMath:
        return (2, 2);
      case ExtensionKind.inlineMath:
        return text.length >= 2 ? (1, 1) : (0, 0);
      case ExtensionKind.wikilink:
        return (2, 2);
      case ExtensionKind.embed:
        return (3, 2);
      case ExtensionKind.tag:
        return (0, 0);
    }
  }

  // ------------------------------------------------------------------- flatten

  /// The depth a structural mark wins at: nothing inline overlaps one.
  static const int _structural = 1 << 20;

  /// The depth a masked span wins at: the parser saw placeholders there, so
  /// no run of its own is inside one, and the run around it is outside it.
  static const int _extension = 1 << 16;

  /// [pieces], which may nest, as disjoint tokens: each stretch of the line
  /// takes the deepest piece over it. Inline pieces before [structural] are
  /// dropped — the parse sees no marks there.
  static List<Token> _flatten(List<_Piece> pieces, int structural) {
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
      _Piece? best;
      for (final piece in pieces) {
        if (piece.start > from || piece.end < to) continue;
        if (piece.depth < _structural && from < structural) continue;
        if (best == null || piece.depth >= best.depth) best = piece;
      }
      if (best == null) continue;
      final last = tokens.isEmpty ? null : tokens.last;
      if (last != null &&
          last.end == from &&
          last.kind == best.kind &&
          last.marker == best.marker &&
          best.depth < _structural) {
        tokens[tokens.length - 1] = Token(
          last.kind,
          last.start,
          to,
          marker: last.marker,
        );
      } else {
        tokens.add(Token(best.kind, from, to, marker: best.marker));
      }
    }
    return tokens;
  }

  // --------------------------------------------------------------- definitions

  /// Whether [line] can be a link or footnote definition: `[` after at most
  /// three spaces, which is where [DocumentScope.scan] looks.
  static bool _mayDefine(String line) {
    var at = 0;
    while (at < 3 && at < line.length && line.codeUnitAt(at) == 0x20) {
      at++;
    }
    return at < line.length && line.codeUnitAt(at) == 0x5B;
  }

  static List<int> _definersOf(SourceBuffer buffer) => <int>[
    for (var line = 0; line < buffer.lineCount; line++)
      if (_mayDefine(buffer.lineAt(line))) line,
  ];

  /// Whether [edit] removed or wrote a line that can be a definition, with
  /// [_definers] moved to the lines after it.
  bool _touchesDefinitions(SourceEdit edit) {
    final first = edit.firstLine;
    final untouched = edit.firstUntouchedLine;
    var low = 0;
    var high = _definers.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_definers[middle] < first) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    var past = low;
    while (past < _definers.length && _definers[past] < untouched) {
      past++;
    }
    var touched = past > low;
    final written = <int>[
      for (var line = first; line < first + edit.insertedLines; line++)
        if (_mayDefine(buffer.lineAt(line))) line,
    ];
    if (written.isNotEmpty) touched = true;
    final delta = edit.lineDelta;
    if (delta != 0) {
      for (var at = past; at < _definers.length; at++) {
        _definers[at] += delta;
      }
    }
    _definers.replaceRange(low, past, written);
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
    return true;
  }
}

/// A block's parse, with where each of its lines starts in the parsed text.
final class _Parsed {
  new(this.block, this.parse) : lineStarts = _lineStartsOf(parse.text);

  final Block block;
  final ParsedBlock parse;
  final List<int> lineStarts;

  static List<int> _lineStartsOf(String text) {
    final starts = <int>[0];
    for (var at = 0; at < text.length; at++) {
      if (text.codeUnitAt(at) == 0x0A) starts.add(at + 1);
    }
    return starts;
  }
}

/// A token before flattening: it may overlap others, and [depth] says which
/// one a stretch of the line goes to.
final class _Piece {
  new(this.kind, this.start, this.end, this.depth, {this.marker = false});

  final TokenKind kind;
  final int start;
  final int end;
  final int depth;
  final bool marker;
}
