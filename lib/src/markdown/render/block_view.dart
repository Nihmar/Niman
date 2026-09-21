/// One block, drawn.
///
/// The renderer is a mapping, not an engine: the parser has already said what
/// each block is and what its inline runs are, the masker has said what is
/// drawn rather than typed, and `VisibleText` has said which characters a
/// reader sees. What is left is which widget to use — and that is all this file
/// does, so it can be read in one sitting and compared against the preview it
/// replaces.
///
/// What each kind becomes:
///
/// | block | drawn as |
/// |---|---|
/// | paragraph, heading | rich text over the visible segments |
/// | list item | the marker, then the item's own text, indented by its depth |
/// | quote | a bar and the indented content |
/// | fenced or indented code | a filled box of monospace lines |
/// | math | the display typesetter |
/// | table | a real table, cells from the source rows |
/// | thematic break | a rule |
/// | frontmatter | nothing: it is metadata, and the preview hides it too |
/// | blank | the space a blank line takes |
///
/// The kinds not yet drawn as they will be: an embed is not yet an image and a
/// table cell does not yet render its inline markup, because both need the
/// image resolution the preview owns. They are named in the Phase 2 issue
/// rather than silently rendered wrong.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/parsed_block.dart';
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/visible_text.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';
import 'package:niman/src/preview/code_highlight.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

/// Draws one block of a note.
final class BlockView extends StatelessWidget {
  /// Creates a view over [parsed], whose block is [ParsedBlock.block].
  const new({
    required this.parsed,
    required this.theme,
    required this.mathCache,
    this.onTapLink,
    this.onTapWikiLink,
    this.embedResolver,
    super.key,
  });

  /// The block, parsed and ready.
  final ParsedBlock parsed;

  /// The typography and metrics it is drawn with.
  final MarkdownTheme theme;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// Called when a link is tapped.
  final void Function(String text, String? href)? onTapLink;

  /// Called when a wikilink is tapped.
  final void Function(ExtensionSpan span)? onTapWikiLink;

  /// Resolves an embed's target, for the round that draws images.
  final Future<String?> Function(String target)? embedResolver;

  @override
  Widget build(BuildContext context) {
    final block = parsed.block;
    final child = switch (block.kind) {
      BlockKind.paragraph => _rich(context),
      BlockKind.heading => _rich(
        context,
        style: theme.heading(block.headingLevel),
      ),
      BlockKind.listItem => _listItem(context),
      BlockKind.quote => _quote(context),
      BlockKind.fencedCode ||
      BlockKind.indentedCode => _code(context, block.fenceInfo),
      BlockKind.math => _blockMath(context),
      BlockKind.table => _table(context),
      BlockKind.thematicBreak => _rule(context),
      BlockKind.blank => SizedBox(height: theme.blockSpacing),
      BlockKind.frontmatter => const SizedBox.shrink(),
      BlockKind.html => _code(context, null),
    };
    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing),
      child: child,
    );
  }

  /// The block's visible text as rich text.
  ///
  /// A block the parser consumed and gave nothing back draws nothing — a link
  /// reference definition and a footnote definition are syntax, not prose, and
  /// the parser files them elsewhere and returns an empty node list. Drawing
  /// "the text it did not cover" instead put `[^1]: fetch free fog national.`
  /// on screen where the preview draws a footnote.
  Widget _rich(BuildContext context, {TextStyle? style}) {
    if (parsed.runs.isEmpty && parsed.extensions.isEmpty) {
      return const SizedBox.shrink();
    }
    final visible = VisibleText.of(parsed);
    final spans = _InlineBuilder(
      visible: visible,
      theme: theme,
      mathCache: mathCache,
      onTapLink: onTapLink,
      onTapWikiLink: onTapWikiLink,
      embedResolver: embedResolver,
    ).build();
    return Text.rich(
      TextSpan(children: spans, style: style ?? theme.body),
      textAlign: TextAlign.start,
    );
  }

  /// A list item: its marker, then its content at the item's own indent.
  /// A list item: its marker, then its content at the item's own indent.
  ///
  /// The marker is drawn, not read from the text, and it agrees with the
  /// preview on purpose: a bullet is `\u2022` whatever the note wrote (`-`, `*`
  /// or `+`), an ordered item keeps its number, and a task item is a box rather
  /// than the `[x]` it was written as — the text says what the note said, the
  /// screen shows what it means.
  Widget _listItem(BuildContext context) {
    final marker = _listMarker(parsed.text, parsed.block.listOrdinal);
    final depth = parsed.block.listDepth;
    // One marker column per level, so a sublist's marker sits exactly where its
    // parent's text starts.
    final offset = depth <= 0 ? 0.0 : depth * theme.listIndentPerLevel;
    return Padding(
      padding: EdgeInsets.only(left: offset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: theme.listIndentPerLevel,
            child: marker.isTask
                ? Padding(
                    padding: EdgeInsets.only(top: theme.body.fontSize! * 0.15),
                    child: Icon(
                      marker.checked
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                      size: theme.body.fontSize! * 0.95,
                      color: theme.marker.color,
                    ),
                  )
                : Text(marker.display, style: theme.marker),
          ),
          Expanded(child: _rich(context, style: theme.body)),
        ],
      ),
    );
  }

  /// A blockquote: a bar, and its content indented by the depth.
  Widget _quote(BuildContext context) {
    final depth = parsed.block.quoteDepth;
    final style = depth > 1 ? theme.quote : theme.quote;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.quoteBar, width: theme.quoteBarWidth),
        ),
      ),
      padding: EdgeInsets.only(left: theme.quoteIndentPerLevel),
      child: Text.rich(
        TextSpan(
          children: _InlineBuilder(
            visible: VisibleText.of(parsed),
            theme: theme,
            mathCache: mathCache,
            onTapLink: onTapLink,
            onTapWikiLink: onTapWikiLink,
            embedResolver: embedResolver,
          ).build(),
        ),
        style: style,
      ),
    );
  }

  /// A code block: a filled box of monospace lines, the fence taken out, the
  /// code coloured by the language the fence names.
  ///
  /// The tokens come from the same `highlight` core the preview's highlighter
  /// uses, one block at a time and only for the blocks a frame draws. The
  /// engine's own line-state lexer (§8.8.2) is the design's replacement when
  /// the whole-block regex stops being enough.
  Widget _code(BuildContext context, String? language) {
    final text = _fenceContent(parsed.text);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.codeBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: EdgeInsets.all(theme.codePadding),
      child: language == null || language.isEmpty
          ? Text(text, style: theme.code)
          : Text.rich(
              CodeHighlighter(
                language: language,
                theme: theme.codeHighlight,
              ).format(text),
              // A fence with no palette (the fallback theme, before the first
              // build) still gets the monospace metrics.
              style: theme.code,
            ),
    );
  }

  /// A display formula, centered like the preview's.
  ///
  /// The [Center] is load-bearing, not decoration. A block is laid out on the
  /// sliver's cross axis with a **tight** width, so a bare [BlockMathView] is
  /// stretched to the whole column — and the katex painter starts its ink at
  /// the canvas origin whatever size it is handed, which put every formula at
  /// the column's left edge (#252). Center hands the view its own width back.
  Widget _blockMath(BuildContext context) => Center(
    child: BlockMathView(
      cache: mathCache,
      tex: _displayTex(parsed.text),
      style: MathStyle(
        fontSize: theme.body.fontSize ?? 14,
        color: theme.body.color,
      ),
    ),
  );

  /// A thematic break.
  Widget _rule(BuildContext context) =>
      Container(height: theme.ruleThickness, color: theme.rule);

  /// A table, its cells read from the source rows.
  Widget _table(BuildContext context) {
    final rows = _tableRows(parsed.text);
    if (rows.isEmpty) return const SizedBox.shrink();
    final border = TableBorder.all(color: theme.tableBorder, width: 0.5);
    return Table(
      border: border,
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: <TableRow>[
        for (var at = 0; at < rows.length; at++)
          TableRow(
            children: <Widget>[
              for (final cell in rows[at])
                Padding(
                  padding: theme.tableCellPadding,
                  child: _cell(
                    cell,
                    at == 0 ? theme.tableHeader : theme.tableCell,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// A table cell, with its own inline markup rendered.
  ///
  /// A cell is a block's worth of Markdown that the scanner never sees as one:
  /// it lives inside a line, between pipes, so it is parsed here, on its own,
  /// through the same engine everything else goes through. Doing it any other
  /// way — a second inline scanner inside the renderer — is how two surfaces
  /// start disagreeing about what `**bold**` means.
  ///
  /// The cost is a scan and a parse per cell, which matters only because a
  /// table can have many; a cell is one line, and a note's tables are small.
  /// Anything larger belongs in the block scanner, which is where a cell would
  /// become a block if it ever needs to.
  Widget _cell(String text, TextStyle style) {
    if (text.isEmpty) return Text('', style: style);
    final buffer = SourceBuffer.fromText(text);
    final scanner = BlockScanner(buffer);
    if (scanner.index.blocks.isEmpty) return Text(text, style: style);
    final cell = BlockParser().parse(scanner.index.blocks.first, buffer);
    final spans = _InlineBuilder(
      visible: VisibleText.of(cell),
      theme: theme,
      mathCache: mathCache,
      onTapLink: onTapLink,
      onTapWikiLink: onTapWikiLink,
      embedResolver: embedResolver,
    ).build();
    return Text.rich(TextSpan(children: spans, style: style));
  }

  /// What to draw in a list item's marker column.
  ///
  /// The `display` field is the text of the marker, and a task item has none:
  /// it draws a box. The indent the item was written at is not this function's
  /// business: the block carries it and the caller applies it.
  static ({String display, bool isTask, bool checked}) _listMarker(
    String text,
    int ordinal,
  ) {
    final line = text.split('\n').first;
    var at = 0;
    while (at < line.length && (line[at] == ' ' || line[at] == '\t')) {
      at++;
    }
    final start = at;
    var ordered = false;
    if (at < line.length && '+-*'.contains(line[at])) {
      at++;
    } else {
      while (at < line.length &&
          line[at].compareTo('0') >= 0 &&
          line[at].compareTo('9') <= 0) {
        at++;
      }
      if (at < line.length && (line[at] == '.' || line[at] == ')')) {
        at++;
        ordered = true;
      }
    }
    if (at == start) return (display: '', isTask: false, checked: false);
    final rest = line.substring(at).trimLeft();
    if (rest.startsWith('[') && rest.length > 2 && rest[2] == ']') {
      return (
        display: '',
        isTask: true,
        checked: rest[1] == 'x' || rest[1] == 'X',
      );
    }
    // An ordered item shows its *position* in the list, not the number the note
    // happened to write: `1. 1. 1.` is a list of three. The delimiter the note
    // used is kept, because `.` and `)` are the author's choice and the number
    // is the list's.
    final delimiter = ordered && at > start ? line[at - 1] : '.';
    return (
      display: ordered
          ? '${ordinal > 0 ? ordinal : line.substring(start, at - 1)}$delimiter'
          : '\u2022',
      isTask: false,
      checked: false,
    );
  }

  /// The lines inside a fence, or the block's own text for indented code.
  static String _fenceContent(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return text;
    if (!lines.first.trimLeft().startsWith('```') &&
        !lines.first.trimLeft().startsWith('~~~')) {
      // Indented code: four spaces come off each line.
      return lines
          .map((line) => line.startsWith('    ') ? line.substring(4) : line)
          .join('\n');
    }
    final last = lines.length > 1 ? lines.last.trim() : '';
    final closed = last.startsWith('```') || last.startsWith('~~~');
    return lines
        .sublist(1, closed ? lines.length - 1 : lines.length)
        .join('\n');
  }

  /// The tex of a display block, markers out.
  static String _displayTex(String text) {
    final lines = text.split('\n');
    final body = <String>[];
    for (var at = 0; at < lines.length; at++) {
      final trimmed = lines[at].trim();
      if (trimmed.startsWith(r'$$')) {
        final inner = trimmed.replaceAll(r'$$', '').trim();
        if (inner.isNotEmpty) body.add(inner);
        continue;
      }
      body.add(lines[at]);
    }
    return body.join('\n').trim();
  }

  /// The rows and cells of a GFM table, delimiter row dropped.
  static List<List<String>> _tableRows(String text) {
    final rows = <List<String>>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.contains('|')) continue;
      if (RegExp(r'^[|\s:-]+$').hasMatch(trimmed) && trimmed.contains('-')) {
        continue; // the delimiter row
      }
      var body = trimmed;
      if (body.startsWith('|')) body = body.substring(1);
      if (body.endsWith('|')) body = body.substring(0, body.length - 1);
      rows.add(<String>[
        for (final cell in body.split(RegExp(r'(?<!\\)\|')))
          cell.replaceAll(r'\|', '|').trim(),
      ]);
    }
    return rows;
  }
}

/// Turns visible segments and drawn spans into an inline span tree.
final class _InlineBuilder {
  new({
    required this.visible,
    required this.theme,
    required this.mathCache,
    this.onTapLink,
    this.onTapWikiLink,
    this.embedResolver,
  });

  final VisibleText visible;
  final MarkdownTheme theme;
  final MathCache mathCache;
  final void Function(String text, String? href)? onTapLink;
  final void Function(ExtensionSpan span)? onTapWikiLink;
  final Future<String?> Function(String target)? embedResolver;

  /// The spans of the block, in offset order.
  List<InlineSpan> build() {
    final spans = <InlineSpan>[];
    var drawn = 0;
    for (final segment in visible.segments) {
      while (drawn < visible.replaced.length &&
          visible.replaced[drawn].start < segment.start) {
        spans.add(_drawnSpan(visible.replaced[drawn]));
        drawn++;
      }
      spans.add(_textSpan(segment));
    }
    while (drawn < visible.replaced.length) {
      spans.add(_drawnSpan(visible.replaced[drawn]));
      drawn++;
    }
    return spans;
  }

  /// A visible run, styled by the construct it belongs to.
  InlineSpan _textSpan(VisibleSegment segment) {
    final text = visible.text.substring(segment.start, segment.end);
    final style = switch (segment.kind) {
      StyleKind.emphasis => theme.body.copyWith(fontStyle: FontStyle.italic),
      StyleKind.strong => theme.body.copyWith(fontWeight: FontWeight.w700),
      StyleKind.strikethrough => theme.body.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
      StyleKind.code => theme.code,
      StyleKind.link => theme.link,
      StyleKind.image => theme.marker,
      StyleKind.heading => theme.body,
      StyleKind.plain || StyleKind.hardBreak => theme.body,
    };
    if (segment.kind == StyleKind.image && segment.href != null) {
      // A Markdown image is a picture, and its alt text is what stands in for
      // it when there is no picture — the same two rules the embed follows,
      // because they are the same problem. Without a resolver there is nothing
      // to resolve and the alt text is the honest thing to draw.
      if (embedResolver == null) {
        return TextSpan(text: text, style: theme.marker);
      }
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: EmbedView(
          target: segment.href!,
          display: text,
          // The construct as the note wrote it. For the inline form this is
          // exact; a reference image shows the inline spelling instead, which
          // is a smaller lie than showing nothing.
          placeholder: '![$text](${segment.href})',
          onResolve: embedResolver,
        ),
      );
    }
    if (segment.kind == StyleKind.link && segment.href != null) {
      return TextSpan(
        text: text,
        style: style,
        recognizer: TapGestureRecognizer()
          ..onTap = () => onTapLink?.call(text, segment.href),
      );
    }
    return TextSpan(text: text, style: style);
  }

  /// A span that is drawn rather than typed.
  InlineSpan _drawnSpan(ExtensionSpan span) {
    switch (span.kind) {
      case ExtensionKind.inlineMath:
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InlineMathView(
            cache: mathCache,
            tex: span.inner,
            style: MathStyle(
              fontSize: theme.body.fontSize ?? 14,
              color: theme.body.color,
            ),
          ),
        );
      case ExtensionKind.wikilink:
        return TextSpan(
          text: _wikiDisplay(span),
          style: theme.wikilink,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onTapWikiLink?.call(span),
        );
      case ExtensionKind.tag:
        return TextSpan(text: span.text, style: theme.tag);
      case ExtensionKind.codeSpan:
        return TextSpan(text: span.inner, style: theme.code);
      case ExtensionKind.embed:
        // An embed is a picture in the middle of a line, so it is a widget
        // span rather than text. Without a resolver there is nothing to
        // resolve, and the note's own words stand in for the picture.
        if (embedResolver == null) {
          return TextSpan(text: '![[${span.inner}]]', style: theme.marker);
        }
        // `![[target|alias]]`: the alias is what the reader asked to see, and
        // it is what the preview drew when a binary or a missing target had to
        // stand in for itself (`preview/wikilink.dart`). The read view passed
        // the raw inner instead, so the same note read `![[book.epub|The
        // book]]` in one surface and `![[The book]]` in the other.
        final pipe = span.inner.indexOf('|');
        final target = pipe >= 0 ? span.inner.substring(0, pipe) : span.inner;
        final alias = pipe >= 0 ? span.inner.substring(pipe + 1).trim() : '';
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: EmbedView(
            target: target,
            display: alias.isEmpty ? target : alias,
            onResolve: embedResolver,
          ),
        );
      case ExtensionKind.displayMath:
        // A display box inside a paragraph: the same typesetter, laid out as
        // its own line rather than inline.
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: BlockMathView(
            cache: mathCache,
            tex: span.inner,
            style: MathStyle(
              fontSize: theme.body.fontSize ?? 14,
              color: theme.body.color,
            ),
          ),
        );
    }
  }

  /// What a wikilink shows: its alias, or its target.
  static String _wikiDisplay(ExtensionSpan span) {
    final inner = span.inner;
    final pipe = inner.indexOf('|');
    if (pipe >= 0) {
      final alias = inner.substring(pipe + 1).trim();
      if (alias.isNotEmpty) return alias;
    }
    final target = pipe >= 0 ? inner.substring(0, pipe) : inner;
    final hash = target.indexOf('#');
    return (hash >= 0 ? target.substring(0, hash) : target).trim().isEmpty
        ? inner
        : (hash >= 0 ? target.substring(0, hash) : target).trim();
  }
}
