/// A leaf's inline nodes, drawn: the spans of a rich text.
///
/// Our inline parser has said what each piece of the text is
/// (`inline_node.dart`), with its markers already apart from its text: a
/// node of emphasis holds the words it stresses, not the asterisks. So
/// drawing is a walk of the nodes, each piece of text in the style of every
/// construct around it — bold inside italic is both — and the app's own
/// constructs drawn rather than typed: a formula typeset, a wikilink by its
/// display text, an embed as its picture.
///
/// The spans come out flat, one per piece of text or drawn construct, each
/// with its whole style: a span tree as deep as the nesting would be as
/// deep as a pathological note's emphasis, thousands of levels.
library;

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/links/parser.dart' show wikiDisplayText;
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/link_references.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

/// What a tap on a drawn construct calls.
typedef InlineTaps = ({
  void Function(String text, String? href)? onTapLink,
  void Function(String inner)? onTapWikiLink,
  Future<String?> Function(String target)? embedResolver,
  Map<String, ui.Image>? embedImages,
});

/// Draws inline nodes as spans.
final class InlineSpans {
  /// Spans in [base], the style the leaf's text is drawn in — the body's,
  /// a heading's, a table header's — and [theme]'s accents.
  new({
    required this.theme,
    required this.base,
    required this.mathCache,
    required this.taps,
    this.availableWidth,
    this.footnoteNumbers = const <String, int>{},
  });

  /// The typography and colours.
  final MarkdownTheme theme;

  /// The style every construct adds to: runs drawn in the body's put a
  /// heading's words back at the body's size.
  final TextStyle base;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// What the drawn constructs call when tapped.
  final InlineTaps taps;

  /// The pane's width, for a display formula that has to be broken (#257).
  final double? availableWidth;

  /// The number each footnote is cited as, by its normalized label.
  final Map<String, int> footnoteNumbers;

  /// The spans of [inline], in order.
  List<InlineSpan> of(ReadInline inline) {
    final spans = <InlineSpan>[];
    final stack = <_Frame>[
      for (final node in inline.nodes.reversed)
        _Frame(node, const _Style(), null),
    ];
    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      final node = frame.node;
      final style = frame.style;
      switch (node) {
        case EmphasisNode(:final children):
          _push(stack, children, style.and(italic: true), frame.link);
        case StrongNode(:final children):
          _push(stack, children, style.and(bold: true), frame.link);
        case StrikethroughNode(:final children):
          _push(stack, children, style.and(struck: true), frame.link);
        case HighlightNode(:final children):
          _push(stack, children, style.and(marked: true), frame.link);
        case StyledNode(:final tag, :final children):
          _push(stack, children, style.and(tag: tag), frame.link);
        case LinkNode(:final destination, :final children):
          final link = _Link(destination, ReadInline.plainOf(children));
          _push(stack, children, style.and(link: true), link);
        case ImageNode():
          spans.add(_image(node, style));
        case TextNode(:final text):
          spans.add(_text(text, style, frame.link));
        case CodeNode(:final code):
          spans.add(_text(code, style.and(code: true), frame.link));
        case HtmlNode(:final html):
          spans.add(_text(html, style, frame.link));
        case SoftBreakNode() || HardBreakNode():
          // A line of the note is a row of the page, as `live` draws it: the
          // two modes are one page, and a word does not move when it flips.
          spans.add(_text('\n', style, null));
        case FootnoteRefNode(:final label):
          final number = footnoteNumbers[LinkReferences.normalize(label)];
          spans.add(
            _text(
              '${number ?? label}',
              style.and(tag: 'sup', link: true),
              null,
            ),
          );
        case MathNode(:final tex, :final display):
          spans.add(_math(tex, display: display));
        case WikiLinkNode(:final inner, :final embed):
          spans.add(embed ? _embed(inner) : _wikilink(inner, style));
        case TagNode(:final name):
          spans.add(
            TextSpan(
              text: '#$name',
              style: _tinted(style.apply(this), theme.tag),
            ),
          );
      }
    }
    return spans;
  }

  static void _push(
    List<_Frame> stack,
    List<InlineNode> children,
    _Style style,
    _Link? link,
  ) {
    for (var at = children.length - 1; at >= 0; at--) {
      stack.add(_Frame(children[at], style, link));
    }
  }

  /// [text] in [style], a link's when it is in [link].
  InlineSpan _text(String text, _Style style, _Link? link) {
    final drawn = style.apply(this);
    if (link == null) return TextSpan(text: text, style: drawn);
    return TextSpan(
      text: text,
      style: drawn,
      recognizer: TapGestureRecognizer()
        ..onTap = () => taps.onTapLink?.call(link.text, link.href),
    );
  }

  /// [accent]'s colour and decoration, on [style]'s size and weight.
  TextStyle _tinted(TextStyle style, TextStyle accent) => style.copyWith(
    color: accent.color,
    backgroundColor: accent.backgroundColor,
    decoration: accent.decoration,
    decorationColor: accent.decorationColor,
    decorationStyle: accent.decorationStyle,
  );

  /// The code face, scaled as the leaf is to the body.
  TextStyle get _code {
    final body = theme.body.fontSize;
    final size = base.fontSize;
    final code = theme.code.fontSize;
    if (body == null || size == null || code == null || size == body) {
      return theme.code;
    }
    return theme.code.copyWith(fontSize: code * size / body);
  }

  InlineSpan _math(String tex, {required bool display}) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: display
        // A display box inside a paragraph: the same typesetter, laid out
        // as its own line rather than inline.
        ? BlockMathView(
            cache: mathCache,
            maxWidth: availableWidth,
            tex: tex,
            style: mathStyleFor(base),
          )
        : InlineMathView(cache: mathCache, tex: tex, style: mathStyleFor(base)),
  );

  InlineSpan _wikilink(String inner, _Style style) => TextSpan(
    text: wikiDisplayText(inner),
    style: _tinted(style.apply(this), theme.wikilink),
    recognizer: TapGestureRecognizer()
      ..onTap = () => taps.onTapWikiLink?.call(inner),
  );

  /// `![[target|alias]]`: the picture, or the note's own words for it.
  ///
  /// The alias is what the reader asked to see, and it is what stands in
  /// when a binary or a missing target has to stand in for itself.
  InlineSpan _embed(String inner) {
    final pipe = inner.indexOf('|');
    final target = pipe >= 0 ? inner.substring(0, pipe) : inner;
    final alias = pipe >= 0 ? inner.substring(pipe + 1).trim() : '';
    final display = alias.isEmpty ? target : alias;
    final decoded = taps.embedImages?[target];
    if (decoded != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: EmbedView(target: target, display: display, image: decoded),
      );
    }
    final resolve = taps.embedResolver;
    // Without a resolver there is nothing to resolve, and the note's own
    // words stand in for the picture.
    if (resolve == null) {
      return TextSpan(text: '![[$inner]]', style: _tinted(base, theme.marker));
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: EmbedView(target: target, display: display, onResolve: resolve),
    );
  }

  /// A Markdown image: a picture, and its description what stands in for
  /// it when there is none — the embed's two rules, for the same problem.
  InlineSpan _image(ImageNode node, _Style style) {
    final alt = ReadInline.plainOf(node.children);
    final target = node.destination;
    final decoded = taps.embedImages?[target];
    if (decoded != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: EmbedView(target: target, display: alt, image: decoded),
      );
    }
    final resolve = taps.embedResolver;
    if (resolve == null) {
      return TextSpan(
        text: alt,
        style: _tinted(style.apply(this), theme.marker),
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: EmbedView(
        target: target,
        display: alt,
        placeholder: '![$alt]($target)',
        onResolve: resolve,
      ),
    );
  }
}

/// A node to draw, the style of the constructs around it, and the link it
/// is in.
final class _Frame {
  const new(this.node, this.style, this.link);

  final InlineNode node;
  final _Style style;
  final _Link? link;
}

/// A link's target, and its text as a reader sees it.
final class _Link {
  const new(this.href, this.text);

  final String href;
  final String text;
}

/// What the constructs around a piece of text add to it.
final class _Style {
  const new({
    this.italic = false,
    this.bold = false,
    this.struck = false,
    this.marked = false,
    this.underlined = false,
    this.code = false,
    this.link = false,
    this.shift,
  });

  final bool italic;
  final bool bold;
  final bool struck;
  final bool marked;
  final bool underlined;
  final bool code;
  final bool link;

  /// `sup` or `sub`, the innermost.
  final String? shift;

  _Style and({
    bool italic = false,
    bool bold = false,
    bool struck = false,
    bool marked = false,
    bool code = false,
    bool link = false,
    String? tag,
  }) => _Style(
    italic: this.italic || italic,
    bold: this.bold || bold,
    struck: this.struck || struck,
    marked: this.marked || marked,
    underlined: underlined || tag == 'u',
    code: this.code || code,
    link: this.link || link,
    shift: tag == 'sup' || tag == 'sub' ? tag : shift,
  );

  /// The text style it makes of [spans]' base.
  TextStyle apply(InlineSpans spans) {
    var style = code ? spans._code : spans.base;
    if (link) style = spans._tinted(style, spans.theme.link);
    final decorations = <TextDecoration>[
      if (style.decoration != null && style.decoration != TextDecoration.none)
        style.decoration!,
      if (struck) TextDecoration.lineThrough,
      if (underlined) TextDecoration.underline,
    ];
    final size = style.fontSize ?? spans.base.fontSize ?? 14;
    return style.copyWith(
      fontStyle: italic ? FontStyle.italic : null,
      fontWeight: bold ? FontWeight.w700 : null,
      backgroundColor: marked ? spans.theme.highlight : null,
      decoration: decorations.isEmpty
          ? null
          : TextDecoration.combine(decorations),
      // Smaller, and raised or lowered by the font's own glyphs where it
      // has them: a text style has no baseline shift of its own.
      fontSize: shift == null ? null : size * 0.75,
      fontFeatures: shift == null
          ? null
          : <FontFeature>[
              if (shift == 'sup')
                const FontFeature.superscripts()
              else
                const FontFeature.subscripts(),
            ],
    );
  }
}
