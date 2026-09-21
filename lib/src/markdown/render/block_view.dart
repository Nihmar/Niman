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
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/visible_text.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';
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
  Widget _rich(BuildContext context, {TextStyle? style}) {
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
  Widget _listItem(BuildContext context) {
    final visible = VisibleText.of(parsed);
    final marker = _listMarker(visible.text);
    final indent = parsed.block.listIndent;
    final offset = indent < 0 ? 0.0 : indent * theme.body.fontSize! * 0.5;
    return Padding(
      padding: EdgeInsets.only(left: offset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: theme.listIndentPerLevel,
            child: Text(marker.$1, style: theme.marker),
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

  /// A code block: a filled box of monospace lines, the fence taken out.
  Widget _code(BuildContext context, String? language) {
    final text = _fenceContent(parsed.text);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.codeBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: EdgeInsets.all(theme.codePadding),
      child: Text(text, style: theme.code),
    );
  }

  /// A display formula.
  Widget _blockMath(BuildContext context) => BlockMathView(
    cache: mathCache,
    tex: _displayTex(parsed.text),
    style: MathStyle(
      fontSize: theme.body.fontSize ?? 14,
      color: theme.body.color,
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

  /// The list marker and its trailing space, from the item's first line.
  static (String, int) _listMarker(String text) {
    final line = text.split('\n').first;
    var at = 0;
    while (at < line.length && (line[at] == ' ' || line[at] == '\t')) {
      at++;
    }
    final start = at;
    if (at < line.length && '+-*'.contains(line[at])) {
      at++;
    } else {
      while (at < line.length &&
          line[at].compareTo('0') >= 0 &&
          line[at].compareTo('9') <= 0) {
        at++;
      }
      if (at < line.length && (line[at] == '.' || line[at] == ')')) at++;
    }
    if (at == start) return ('', 0);
    // A task box is part of the marker: `- [x] item`.
    final rest = line.substring(at).trimLeft();
    if (rest.startsWith('[') && rest.length > 2 && rest[2] == ']') {
      return (rest.substring(0, 3), at);
    }
    return (line.substring(start, at), at);
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
      case ExtensionKind.embed || ExtensionKind.displayMath:
        // Drawn for real in the round that resolves images and display boxes
        // inside a paragraph; until then the alt text is shown rather than
        // nothing, so a note never silently loses a line.
        return TextSpan(text: span.inner, style: theme.marker);
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
