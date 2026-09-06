import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// The windowed Markdown preview (M2 T-M2-04).
///
/// Parses the whole document once per change (using flutter_markdown_plus's
/// MarkdownBuilder, which builds a widget per AST block) but lays out
/// **only the blocks the viewport shows** via a [SliverList]. This is the
/// design's windowing rule: the package's own `Markdown` view hands the
/// whole document to an eager `Column`/`ListView` (measured ~2.1 s for a
/// 200 KB buffer) — never do that.
///
/// The parsed block widgets are rebuilt on every data/style change (the
/// caller debounces the source); widget construction is ~O(doc), layout is
/// O(visible). Tables, task lists, footnotes, strikethrough and links come
/// from the GFM extension set + the package's own builders; code blocks are
/// highlighted by [syntaxHighlighter].
final class MarkdownPreview extends StatefulWidget {
  /// Creates a preview over [data].
  const MarkdownPreview({
    required this.data,
    this.styleSheet,
    this.syntaxHighlighter,
    this.imageBuilder,
    this.checkboxBuilder,
    this.bulletBuilder,
    this.builders = const {},
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.onTapLink,
    super.key,
  });

  /// The Markdown source to render.
  final String data;

  /// Style overrides merged over the theme-derived defaults.
  final MarkdownStyleSheet? styleSheet;

  /// Code-block highlighter (use the `PreviewCodeHighlighter` from
  /// `code_highlight.dart`).
  final SyntaxHighlighter? syntaxHighlighter;

  /// Image builder (defaults to the package's own; library-relative image
  /// wiring arrives with T-M2-09).
  final MarkdownImageBuilder? imageBuilder;

  /// Task checkbox builder.
  final MarkdownCheckboxBuilder? checkboxBuilder;

  /// List bullet builder.
  final MarkdownBulletBuilder? bulletBuilder;

  /// Per-element builders; see [MarkdownBuilder].
  final Map<String, MarkdownElementBuilder> builders;

  /// Inset for the content.
  final EdgeInsets padding;

  /// Scroll controller (scroll-sync, T-M2-06, reuses it).
  final ScrollController? controller;

  /// Link callback (M3 link handling).
  final MarkdownTapLinkCallback? onTapLink;

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

final class _MarkdownPreviewState extends State<MarkdownPreview>
    implements MarkdownBuilderDelegate {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  List<Widget>? _children;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parse();
  }

  @override
  void didUpdateWidget(MarkdownPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.styleSheet != widget.styleSheet ||
        oldWidget.builders != widget.builders) {
      _parse();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _parse() {
    final styleSheet = MarkdownStyleSheet.fromTheme(
      Theme.of(context),
    ).merge(widget.styleSheet);
    _disposeRecognizers();
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    final nodes = document.parseLines(
      const LineSplitter().convert(widget.data),
    );
    final builder = MarkdownBuilder(
      delegate: this,
      selectable: false,
      styleSheet: styleSheet,
      imageDirectory: null,
      imageBuilder: widget.imageBuilder,
      checkboxBuilder: widget.checkboxBuilder,
      bulletBuilder: widget.bulletBuilder,
      builders: widget.builders,
      paddingBuilders: const {},
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.baseline,
    );
    _children = builder.build(nodes);
  }

  @override
  GestureRecognizer createLink(String text, String? href, String title) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onTapLink?.call(text, href, title);
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  TextSpan formatText(MarkdownStyleSheet styleSheet, String code) {
    final highlighter = widget.syntaxHighlighter;
    if (highlighter != null) return highlighter.format(code);
    return TextSpan(style: styleSheet.code, text: code);
  }

  @override
  Widget build(BuildContext context) {
    final children = _children ?? const <Widget>[];
    return CustomScrollView(
      controller: widget.controller,
      slivers: <Widget>[
        SliverPadding(
          padding: widget.padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => children[index],
              childCount: children.length,
            ),
          ),
        ),
      ],
    );
  }
}
