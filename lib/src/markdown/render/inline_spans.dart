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

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/links/block_anchors.dart' show withoutTrailingBlockId;
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/links/parser.dart' show parseWikiRef, wikiDisplayText;
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/link_references.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

/// What the links a leaf draws tell the link preview (#846): the pointer came
/// onto one (with where it is, globally) or left it, and — on a touch screen,
/// where nothing hovers — a long press on one.
typedef LinkPreviewHooks = ({
  void Function(PreviewLink link, Offset at) onEnter,
  VoidCallback onExit,
  void Function(PreviewLink link)? onLongPress,
});

/// What a tap on a drawn construct calls.
typedef InlineTaps = ({
  void Function(String text, String? href)? onTapLink,
  void Function(String inner)? onTapWikiLink,
  Future<String?> Function(String target)? embedResolver,
  Map<String, ui.Image>? embedImages,

  /// The links of the note that name nothing (#847), drawn muted; null draws
  /// every link as a live one.
  ValueListenable<DeadLinks>? deadLinks,

  /// What the links tell the link preview; null draws links that preview
  /// nothing.
  LinkPreviewHooks? linkPreview,
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
    this.deadLinks = DeadLinks.none,
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

  /// The links of the note that name nothing (#847): drawn in the muted
  /// colour of a link that is not there yet.
  final DeadLinks deadLinks;

  /// [nodes] with the ` ^id` that ends their text taken off: the id and the
  /// space before it, nothing when the text is the id alone.
  static List<InlineNode> _withoutBlockId(List<InlineNode> nodes) {
    if (nodes.isEmpty) return nodes;
    final last = nodes.last;
    if (last is! TextNode) return nodes;
    final shown = withoutTrailingBlockId(last.text);
    if (shown == last.text) return nodes;
    return [
      ...nodes.take(nodes.length - 1),
      if (shown.isNotEmpty)
        TextNode(shown, start: last.start, end: last.start + shown.length),
    ];
  }

  /// The spans of [inline], in order.
  ///
  /// With [hideBlockId] a ` ^id` that ends the text is left out, as Obsidian's
  /// reading view leaves it (#844): the id names the block for a link, and
  /// the note keeps it — `live` and `source` show it, and nothing here
  /// changes the file.
  List<InlineSpan> of(ReadInline inline, {bool hideBlockId = false}) {
    final spans = <InlineSpan>[];
    final nodes = hideBlockId ? _withoutBlockId(inline.nodes) : inline.nodes;
    final stack = <_Frame>[
      for (final node in nodes.reversed) _Frame(node, const _Style(), null),
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
          _push(
            stack,
            children,
            style.and(link: true, dead: deadLinks.hrefIsDead(destination)),
            link,
          );
        case ImageNode():
          spans.add(_image(node, style));
        case TextNode(:final text):
          spans.add(_text(text, style, frame.link));
        case CodeNode(:final code):
          spans.add(_text(code, style.and(code: true), frame.link));
        // A comment is the writer's, not the reader's: nothing shows, as
        // in any Markdown renderer (#595 keeps a line's place on a scan
        // in one).
        case HtmlNode(:final html) when html.startsWith('<!--'):
          break;
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
    final preview = PreviewLink.markdown(link.href);
    return _linkSpan(
      text,
      drawn,
      preview,
      () => taps.onTapLink?.call(link.text, link.href),
    );
  }

  /// The span of a link: tapped it follows, and it tells the link preview
  /// where the pointer is and what a long press on it asks for (#846).
  TextSpan _linkSpan(
    String text,
    TextStyle style,
    PreviewLink link,
    VoidCallback onTap,
  ) {
    final hooks = taps.linkPreview;
    final longPress = hooks?.onLongPress;
    return TextSpan(
      text: text,
      style: style,
      recognizer: longPress == null
          ? (TapGestureRecognizer()..onTap = onTap)
          : (_LinkTapRecognizer(() => longPress(link))..onTap = onTap),
      onEnter: hooks == null
          ? null
          : (event) => hooks.onEnter(link, event.position),
      onExit: hooks == null ? null : (_) => hooks.onExit(),
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

  InlineSpan _wikilink(String inner, _Style style) => _linkSpan(
    wikiDisplayText(inner),
    _tinted(
      style.apply(this),
      deadLinks.wikiIsDead(parseWikiRef(inner))
          ? theme.deadWikilink
          : theme.wikilink,
    ),
    PreviewLink.wiki(inner),
    () => taps.onTapWikiLink?.call(inner),
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

/// A tap that is also a long press: a link on a touch screen follows on a tap
/// and previews on a press and hold (#846). The two compete in the gesture
/// arena as they do under any widget that takes both.
final class _LinkTapRecognizer extends TapGestureRecognizer {
  new(VoidCallback onLongPress) {
    _longPress = LongPressGestureRecognizer()..onLongPress = onLongPress;
  }

  late final LongPressGestureRecognizer _longPress;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _longPress.addPointer(event);
  }

  @override
  void dispose() {
    _longPress.dispose();
    super.dispose();
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
    this.dead = false,
    this.shift,
  });

  final bool italic;
  final bool bold;
  final bool struck;
  final bool marked;
  final bool underlined;
  final bool code;
  final bool link;

  /// Whether the link names nothing (#847).
  final bool dead;

  /// `sup` or `sub`, the innermost.
  final String? shift;

  _Style and({
    bool italic = false,
    bool bold = false,
    bool struck = false,
    bool marked = false,
    bool code = false,
    bool link = false,
    bool dead = false,
    String? tag,
  }) => _Style(
    italic: this.italic || italic,
    bold: this.bold || bold,
    struck: this.struck || struck,
    marked: this.marked || marked,
    underlined: underlined || tag == 'u',
    code: this.code || code,
    link: this.link || link,
    dead: this.dead || dead,
    shift: tag == 'sup' || tag == 'sub' ? tag : shift,
  );

  /// The text style it makes of [spans]' base.
  TextStyle apply(InlineSpans spans) {
    var style = code ? spans._code : spans.base;
    if (link) {
      style = spans._tinted(
        style,
        dead ? spans.theme.deadLink : spans.theme.link,
      );
    }
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
