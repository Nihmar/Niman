/// Where a block of the scanner's stands in the containers around it: how
/// much of each of its lines its quote marks, its items' indents and a
/// footnote definition take off — what the tree reads a container's content
/// with (`BlockTree`), and what `live` puts a line's marks by — and the
/// note's definitions ([DocumentScope]).
///
/// It was the bridge to `package:markdown` too: the package parsed each
/// block given in its container's coordinates, and its runs were found back
/// in the source. The read view and `live` read blocks with the tree and our
/// own inline parser now (`docs/dev/block-tree.md`, phases 5 and 6).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/footnote_syntax.dart';
import 'package:niman/src/markdown/inline/link_references.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/link_definition_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The prefixes a block's lines carry in the note.
abstract final class BlockParser {
  /// How many spaces past its quote marks and its parent items the parse
  /// takes off [line], line [index] of [block], whose first line is
  /// [firstLine]: none for a block the scanner made ([linePrefix]), and 0
  /// for any block that is not an item's.
  ///
  /// A block built without the scanner's state cannot be read in its
  /// parent's coordinates, and an item three levels down stands four spaces
  /// in — which alone is an indented code block. Its marker's indent comes
  /// off its own line ([listIndentOf]), and the item's content column off
  /// the lines after it, the spaces the parse reads them without.
  static int listStripOf(
    Block block,
    String firstLine,
    int index,
    String line,
  ) {
    if (block.kind != BlockKind.listItem || _inParent(block)) return 0;
    final indent = listIndentOf(block, firstLine);
    if (index == 0) return indent;
    final from = quotePrefixLength(firstLine, block.quoteDepth);
    final marker = LineSyntax.listMarkerOf(firstLine.substring(from));
    return marker?.$3 ?? indent;
  }

  /// The indent a list item's marker stands at, past its quote marks, on the
  /// item's [firstLine] — what the parse takes off each of its lines — or 0
  /// for any other block.
  static int listIndentOf(Block block, String firstLine) {
    if (block.kind != BlockKind.listItem) return 0;
    final from = quotePrefixLength(firstLine, block.quoteDepth);
    var at = from;
    while (at < firstLine.length &&
        LineSyntax.isSpace(firstLine.codeUnitAt(at))) {
      at++;
    }
    return at - from;
  }

  /// How much of [line], a line of [block], the parse takes off: its quote
  /// marks, and up to [listStrip] spaces after them ([listStripOf]). A
  /// reader puts the parse's offsets back on the line by adding this.
  static int linePrefixLength(Block block, String line, int listStrip) =>
      linePrefix(block, line, listStrip).$1;

  /// [linePrefixLength], and the columns of a tab it ended inside that are
  /// left over before the text after it: what the text stands in, as
  /// spaces that are no characters of the line (`- foo` / `\t\tbar`: the
  /// item takes two of the first tab's four columns, and `bar` is code two
  /// columns in).
  static (int, int) linePrefix(Block block, String line, int listStrip) {
    final (items, itemsLeft) = itemPrefix(block, line);
    final (quote, quoteLeft) = quotePrefix(line, block.quoteDepth, items);
    var at = quote;
    while (at - quote < listStrip &&
        at < line.length &&
        LineSyntax.isSpace(line.codeUnitAt(at))) {
      at++;
    }
    return (at, quote > items ? quoteLeft : itemsLeft);
  }

  /// How much of [line] its [depth] quote marks take — each `>` with the up
  /// to three spaces before it and the one after — as far as the line has
  /// them: what the parse takes off a quote's lines, so a reader can put the
  /// parse's offsets back on the line.
  ///
  /// Counted from [start]: a block in a list item stands where its items
  /// leave the line ([itemPrefixLength]), and its quote marks are three
  /// spaces in from *there*. Counted from the margin, `- a` / `    > b` — a
  /// quote in the item — kept its `>`, and its inside was read as indented
  /// code.
  ///
  /// The three spaces are columns, a tab to the next stop of four, as the
  /// scanner reads them: `\t>` is four columns in, indented code and no
  /// quote mark.
  static int quotePrefixLength(String line, int depth, [int start = 0]) =>
      quotePrefix(line, depth, start).$1;

  /// [quotePrefixLength], and the columns of the tab after the last `>`
  /// left over: a `>` takes one column of white space after it, and a tab
  /// there has more (`>\t\tfoo` is code two columns in).
  static (int, int) quotePrefix(String line, int depth, [int start = 0]) {
    var leftOver = 0;
    var from = start;
    var column = 0;
    for (var at = 0; at < start && at < line.length; at++) {
      column += line.codeUnitAt(at) == 0x09 ? 4 - column % 4 : 1;
    }
    for (var level = 0; level < depth; level++) {
      var at = from;
      var reached = column;
      while (at < line.length && LineSyntax.isSpace(line.codeUnitAt(at))) {
        final width = line.codeUnitAt(at) == 0x09 ? 4 - reached % 4 : 1;
        if (reached + width - column > 3) break;
        reached += width;
        at++;
      }
      if (at >= line.length || line.codeUnitAt(at) != 0x3E) {
        return (from, leftOver);
      }
      at++;
      reached++;
      leftOver = 0;
      if (at < line.length && LineSyntax.isSpace(line.codeUnitAt(at))) {
        if (line.codeUnitAt(at) == 0x09) leftOver = 4 - reached % 4 - 1;
        reached += line.codeUnitAt(at) == 0x09 ? 4 - reached % 4 : 1;
        at++;
      }
      from = at;
      column = reached;
    }
    return (from, leftOver);
  }

  /// How much of [line], a line of [block], the list items [block] stands
  /// in take off it before the block's own text: what the parse — given the
  /// block alone — must not read as indent. A paragraph four spaces into
  /// `- a` / `  - b` is the second item's text, and four spaces of it were
  /// an indented code block to the parse.
  ///
  /// Each item, outermost first, takes its indent off a line that reaches
  /// it; a line that does not is that item's lazily ([lazyInItems]), the
  /// innermost paragraph's text as it stands, and no item inside takes its
  /// indent off it either: `    1. w` short of an item at six is no item
  /// of the one at eight inside it. Taking the whole column off every line
  /// made `    ---`, a lazy line four spaces into an item of five, the
  /// underline of a heading.
  ///
  /// An item's own block is read in its parent, so its parents' indents
  /// come off it and not its own. 0 for a block in no item, and for a block
  /// the scanner did not make, which carries no state.
  ///
  /// A footnote definition around them takes its part first
  /// ([footnotePrefixLength]).
  static int itemPrefixLength(Block block, String line) =>
      itemPrefix(block, line).$1;

  /// [itemPrefixLength], and the columns of a tab the last item's indent
  /// ended inside of, left over (`LineSyntax.dedent`).
  static (int, int) itemPrefix(Block block, String line) {
    final (length, remaining, _) = _itemWalk(block, line);
    return (length, remaining);
  }

  /// Whether [line], a line of [block], falls short of one of the items
  /// [block] is read inside: theirs lazily, as [itemPrefixLength] reads it.
  static bool lazyInItems(Block block, String line) =>
      _itemWalk(block, line).$3;

  /// [itemPrefix], and whether an item's indent was not reached.
  static (int, int, bool) _itemWalk(Block block, String line) {
    final (footnote, footnoteLeft) = footnotePrefix(block, line);
    final items = _itemsOf(block);
    if (items == null) return (footnote, footnoteLeft, false);
    // Each item takes its indent off as the parser does
    // (`LineSyntax.dedent`): a tab whole once the indent is reached in it,
    // its columns past the indent counting toward the next item's.
    var rest = line.substring(footnote);
    var remaining = footnoteLeft;
    for (var level = 0; level < _levelsOf(block); level++) {
      final indent = items[level].indent;
      if (LineSyntax.columnsOf(rest, remaining) < indent) {
        // A blank line short of it is the item's all the same, to its end.
        if (LineSyntax.indentOf(rest) == rest.length) {
          return (line.length, 0, false);
        }
        return (line.length - rest.length, remaining, true);
      }
      (rest, remaining) = LineSyntax.dedent(rest, indent, remaining);
    }
    return (line.length - rest.length, remaining, false);
  }

  /// What, beside its kind, depths and text, decides what [linePrefix]
  /// makes of [block]: the indents of the items it stands in — empty for a
  /// block in none. A cache of parses keyed without it handed a block the
  /// parse of the same text in another item, offsets and all.
  static String itemKeyOf(Block block) {
    final items = _itemsOf(block);
    final indents = StringBuffer();
    if (block.footnote != 0) indents.write('f${block.footnote};');
    if (items == null) return indents.toString();
    for (var level = 0; level < _levelsOf(block); level++) {
      indents
        ..write(items[level].indent)
        ..write(',');
    }
    return indents.toString();
  }

  /// How much of [line], a line of [block], the footnote definition it
  /// stands in takes off: the label on the definition's own line, four
  /// columns on a line indented into it, nothing on a lazy one.
  static int footnotePrefixLength(Block block, String line) =>
      footnotePrefix(block, line).$1;

  /// [footnotePrefixLength], and the columns of a tab its four ended inside
  /// of, left over toward an item inside it.
  static (int, int) footnotePrefix(Block block, String line) {
    if (block.footnote == 0) return (0, 0);
    if (block.footnote == Block.opensFootnote) {
      final opening = FootnoteSyntax.opening(line);
      if (opening != null) return (opening.$2, 0);
    }
    if (!FootnoteSyntax.indented(line)) return (0, 0);
    final (rest, columns) = FootnoteSyntax.content(line);
    return (line.length - rest.length, columns);
  }

  /// The items [block] is read inside ([_levelsOf]), from the state
  /// entering it, or null for a block in none and a block built by hand.
  static List<OpenItem>? _itemsOf(Block block) {
    final levels = _levelsOf(block);
    if (levels <= 0) return null;
    final items = block.entering?.listStack;
    if (items == null || items.length < levels) return null;
    return items;
  }

  /// How many of the items [block] stands in it is read inside: all of
  /// them, but for an item's own block, which is read in its parent.
  static int _levelsOf(Block block) =>
      block.kind == BlockKind.listItem ? block.listDepth : block.listDepth + 1;

  /// Whether [block] carries the scanner's state for the items around it,
  /// so it can be read in its container's coordinates.
  static bool _inParent(Block block) {
    final items = block.entering?.listStack;
    return items != null && items.length >= _levelsOf(block);
  }

  /// The block's own text, its lines joined with `\n`.
  static String blockText(Block block, SourceBuffer buffer) {
    final parts = <String>[];
    for (var line = block.startLine; line < block.endLine; line++) {
      parts.add(buffer.lineAt(line));
    }
    return parts.join('\n');
  }
}

/// The definitions a note makes that no single block can resolve.
///
/// A link reference (`[label]: destination`) and a footnote (`[^label]: text`
/// with `[^label]` where it is cited) are written in one place and used in
/// another, and a block is read on its own — deliberately, so that a long
/// note is not read again to scroll it. Scanning the note once per revision
/// and reading every block with the result is what keeps the block-by-block
/// reading honest without giving up the windowing.
///
/// The scan is over the note's text, not over its blocks, because it must be
/// complete: a definition on the last line resolves a reference on the first.
final class DocumentScope {
  /// Wraps an already-scanned scope.
  const new({
    required this.references,
    required this.footnoteKeys,
    required this.footnoteCounts,
    required this.footnoteLabels,
    required this.footnotes,
    required this.source,
    required this.revision,
  });

  /// Scans [source]'s lines for both kinds of definition.
  ///
  /// Line by line, and only the lines that can hold one: a definition opens
  /// with `[` after at most three spaces, a reference contains `[^`. The
  /// scan used to run three multi-line patterns over the note's joined text
  /// — 8.5 s on the first frame of a 246 MB note's preview (0.0.9 stress
  /// test) — for definitions a few lines of it make.
  factory scan(SourceBuffer source, int revision) => DocumentScope.ofLines(
    source,
    revision,
    Iterable<int>.generate(source.lineCount),
  );

  /// Scans [lines] of [source], in ascending order, for both kinds of
  /// definition: the same answer as [DocumentScope.scan] when they include
  /// every line a scope is read from — every definition, every footnote
  /// citation, and every line a footnote's body runs on to.
  ///
  /// What a reader that keeps track of those lines rescans after an edit,
  /// instead of the note.
  factory ofLines(SourceBuffer source, int revision, Iterable<int> lines) {
    final references = <String, LinkReference>{};
    final counts = <String, int>{};
    final bodies = <String, String>{};
    final labels = <String>[];
    final cited = <String>{};
    for (final at in lines) {
      final line = source.lineAt(at);
      if (line.contains('[^')) {
        for (final match in _footnoteReference.allMatches(line)) {
          final label = match.group(1)!;
          if (cited.add(label)) labels.add(label);
        }
      }
      if (!_opensWithBracket(line)) continue;
      final footnote = _footnoteDefinition.firstMatch(line);
      if (footnote != null) {
        final label = footnote.group(1)!;
        counts[label] = (counts[label] ?? 0) + 1;
        final body = _footnoteBody(source, at, footnote.group(2) ?? '');
        if (body.isNotEmpty) bodies.putIfAbsent(label, () => body);
        continue;
      }
      _readDefinition(source, at, references);
    }
    // The section a note ends with, in the order the references are cited —
    // which is the order `cmark-gfm` numbers them in, and the order a reader
    // meets them.
    final notes = <Footnote>[];
    for (final label in labels) {
      if (!counts.containsKey(label)) continue;
      notes.add(Footnote(label: label, body: bodies[label] ?? ''));
    }
    return DocumentScope(
      references: references,
      footnoteKeys: {
        for (final label in counts.keys) LinkReferences.normalize(label),
      },
      footnoteCounts: counts,
      footnoteLabels: labels,
      footnotes: notes,
      source: source,
      revision: revision,
    );
  }

  /// The definitions a paragraph opening on line [at] of [source] starts
  /// with, read as `cmark` reads them into [into]: a destination or a
  /// title on the lines after the label's, escapes and entities resolved.
  ///
  /// Read off the lines, not the blocks: a line in a fence that reads as a
  /// definition is taken for one, as it was by the single-line pattern this
  /// stands beside.
  static void _readDefinition(
    SourceBuffer source,
    int at,
    Map<String, LinkReference> into,
  ) {
    var next = at + 1;
    final count = LinkDefinitionSyntax.linesOf(source.lineAt(at), () {
      if (next >= source.lineCount) return null;
      final line = source.lineAt(next++);
      return line.trim().isEmpty ? null : line;
    });
    if (count == 0) return;
    LinkReferences.parseInto(
      [
        for (var line = at; line < at + count; line++)
          source.lineAt(line).trimLeft(),
      ].join('\n'),
      into,
    );
  }

  /// Whether [line] can be part of what a scope is made of on its own: it
  /// opens with `[` (a definition), or cites a footnote, whose order is the
  /// footnotes' numbering.
  ///
  /// A line a footnote's body runs on to is not here: that depends on the
  /// line above it ([continuesFootnote]), and only a footnote definition
  /// makes one ([definesFootnote]).
  static bool opensDefinition(String line) =>
      _opensWithBracket(line) || line.contains('[^');

  /// Whether [line] defines a footnote: it opens with `[` and carries a
  /// footnote label, the one definition whose body runs on to the lines
  /// indented under it.
  static bool definesFootnote(String line) =>
      _footnoteDefinition.hasMatch(line);

  /// Whether [text] runs on the footnote definition above it: a line with
  /// text, indented four spaces in.
  static bool continuesFootnote(String text) {
    final trimmed = text.trimLeft();
    return trimmed.isNotEmpty && text.length - trimmed.length >= 4;
  }

  /// Whether [line] opens with `[` after at most three spaces: the only
  /// lines a definition can be.
  static bool _opensWithBracket(String line) {
    var at = 0;
    while (at < 3 && at < line.length && line.codeUnitAt(at) == 0x20) {
      at++;
    }
    return at < line.length && line.codeUnitAt(at) == 0x5B;
  }

  /// The body of the footnote whose definition opens on [line]: the text its
  /// own line carries, and the lines under it indented four spaces on — the
  /// continuation the package's footnote reads (`FootnoteDefSyntax`), whose
  /// text runs as long as its indent. Read whole, so a multi-line footnote
  /// exists in the read view and in `live`, not only in the file (#361).
  static String _footnoteBody(SourceBuffer source, int line, String own) {
    final parts = <String>[own.trim()];
    for (var at = line + 1; at < source.lineCount; at++) {
      final text = source.lineAt(at);
      if (!continuesFootnote(text)) break;
      parts.add(text.trim());
    }
    return parts.join('\n').trim();
  }

  /// A footnote definition's opening line: its label, and the text that line
  /// carries; the lines under it are read with it ([_footnoteBody]).
  static final RegExp _footnoteDefinition = RegExp(
    r'^ {0,3}\[\^([^\]]+)\]:[ \t]*(.*)$',
  );

  /// A footnote reference: `[^label]` that is not a definition.
  static final RegExp _footnoteReference = RegExp(r'\[\^([^\]]+)\](?!:)');

  /// The link references, as our inline parser looks them up: by their
  /// normalized label ([LinkReferences.normalize]), the definitions over
  /// more than one line among them.
  final Map<String, LinkReference> references;

  /// The footnote labels defined, normalized: what a `[^label]` is a
  /// reference to.
  final Set<String> footnoteKeys;

  /// How many times each footnote label is defined.
  final Map<String, int> footnoteCounts;

  /// The footnote labels in the order they are first cited, which is the order
  /// they are numbered in.
  final List<String> footnoteLabels;

  /// The definitions, in citation order, for the section a note ends with.
  final List<Footnote> footnotes;

  /// The buffer this was scanned from.
  final SourceBuffer source;

  /// Its revision.
  final int revision;

  /// The same definitions, as scanned from [buffer] at [revision]: a scope
  /// scanned from a copy of the note, in the background, handed to the note
  /// itself.
  DocumentScope on(SourceBuffer buffer, int revision) => DocumentScope(
    references: references,
    footnoteKeys: footnoteKeys,
    footnoteCounts: footnoteCounts,
    footnoteLabels: footnoteLabels,
    footnotes: footnotes,
    source: buffer,
    revision: revision,
  );
}

/// One footnote: the label it was defined with, and its body.
@immutable
final class Footnote {
  /// Creates a footnote.
  const new({required this.label, required this.body});

  /// The label, without its brackets.
  final String label;

  /// What the definition said: its own line's text and the lines indented
  /// under it, joined with `\n`.
  final String body;

  @override
  String toString() => 'Footnote($label: $body)';
}
