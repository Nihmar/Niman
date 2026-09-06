import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/preview/html_table.dart';
import 'package:copist/src/preview/math_cache.dart';
import 'package:copist/src/preview/math_syntax.dart';
import 'package:copist/src/preview/math_widget.dart';
import 'package:copist/src/preview/preview_work.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as p;

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
    this.mathStyle = const MathStyle(),
    this.mathCache,
    this.scrollMap,
    this.imageDirectory,
    super.key,
  });

  /// The Markdown source to render.
  final String data;

  /// Style overrides merged over the theme-derived defaults.
  final MarkdownStyleSheet? styleSheet;

  /// Code-block highlighter (use the `PreviewCodeHighlighter` from
  /// `code_highlight.dart`).
  final SyntaxHighlighter? syntaxHighlighter;

  /// Image builder (overrides the default resolution described under
  /// [imageDirectory]).
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

  /// Math visual style (size/color); see [MathStyle].
  final MathStyle mathStyle;

  /// The math render cache; one is created per widget when not injected
  /// (tests inject their own with a synchronous renderer).
  final MathCache? mathCache;

  /// The scroll map (T-M2-06); when given, the preview rebuilds it per
  /// render pass (structure → block start lines) and reports every block's
  /// measured height.
  final ScrollMap? scrollMap;

  /// The base directory for relative image links (the library root, T-M2-09):
  /// `![alt](assets/…png)` resolves to a file under it and renders as an
  /// `Image.file`; null = the package's network default. The package's own
  /// resolver concatenates `imageDirectory + uri` with no separator, so
  /// MarkdownPreview wires its own builder when a directory is given
  /// (see [_imageFor]).
  final String? imageDirectory;

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

final class _MarkdownPreviewState extends State<MarkdownPreview>
    implements MarkdownBuilderDelegate {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  List<Widget>? _children;
  late final MathCache _mathCache = widget.mathCache ?? MathCache();

  /// Bumped per parse so a stale isolate result is dropped.
  int _parseRevision = 0;

  /// Below this size the parse stays synchronous (the divide is a single
  /// frame's cost); above it the whole parse runs on a background isolate
  /// so a 931K note never janks the UI (the measured 418 ms whole-doc
  /// parse, T-M2-05).
  static const int _syncParseLimit = 64 * 1024;

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
    if (widget.mathCache == null) _mathCache.dispose();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _parse() {
    final revision = ++_parseRevision;
    final source = stripFrontmatter(widget.data);

    if (source.length <= _syncParseLimit) {
      _applyParse(revision, source, _parseSyncSource(source));
      return;
    }
    // Large document: parse off the UI isolate (the AST is plain data).
    unawaited(
      PreviewWork.run('parse', source).then((result) {
        if (!mounted || revision != _parseRevision) return;
        if (result is! List<md.Node>) {
          const AppLogger(name: 'preview').error(
            'async parse failed (${source.length} chars): $result',
          );
          return;
        }
        _applyParse(revision, source, result);
      }),
    );
  }

  static List<md.Node> _parseSyncSource(String source) {
    final document = md.Document(
      blockSyntaxes: <md.BlockSyntax>[
        const MathBlockSyntax(),
        ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      ],
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    return splitHtmlTables(
      splitInlineMath(
        document.parseLines(const LineSplitter().convert(source)),
      ),
    );
  }

  void _applyParse(int revision, String source, List<md.Node> nodes) {
    if (!mounted || revision != _parseRevision) return;
    final styleSheet = MarkdownStyleSheet.fromTheme(
      Theme.of(context),
    ).merge(widget.styleSheet);
    final builder = MarkdownBuilder(
      delegate: this,
      selectable: false,
      styleSheet: styleSheet,
      imageDirectory: widget.imageDirectory,
      imageBuilder: widget.imageBuilder ??
          (widget.imageDirectory == null
              ? null
              : (uri, title, alt) =>
                  _imageFor(uri, widget.imageDirectory)),
      checkboxBuilder: widget.checkboxBuilder,
      bulletBuilder: widget.bulletBuilder,
      builders: <String, MarkdownElementBuilder>{
        ...widget.builders,
        'math': MathInlineBuilder(cache: _mathCache, style: widget.mathStyle),
        'mathblock': MathBlockBuilder(
          cache: _mathCache,
          style: widget.mathStyle,
        ),
        'htmlblock': HtmlTableBuilder(),
      },
      paddingBuilders: const {},
      listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.baseline,
    );
    setState(() {
      _children = builder.build(nodes);
    });
    widget.scrollMap?.rebuild(source);
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
    final map = widget.scrollMap;
    return CustomScrollView(
      controller: widget.controller,
      slivers: <Widget>[
        SliverPadding(
          padding: widget.padding,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => map == null
                  ? children[index]
                  : _BlockMeasure(
                      onHeight: (height) => map.measure(index, height),
                      child: children[index],
                    ),
              childCount: children.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reports its child's height after layout (the scroll map's per-block
/// measurement — the mapping table's pixel side).
final class _BlockMeasure extends SingleChildRenderObjectWidget {
  const _BlockMeasure({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _BlockMeasureRender(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _BlockMeasureRender renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

final class _BlockMeasureRender extends RenderProxyBox {
  _BlockMeasureRender(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}

/// Resolves an image URI (T-M2-09). Relative links (`scheme` empty, e.g.
/// `assets/pic.png`) load from [directory] — the library root — via
/// `Image.file`; absolute http(s)/data/resource URIs keep the package's
/// behavior. A missing/unreadable file renders as an empty box.
Widget _imageFor(Uri uri, String? directory) {
  final scheme = uri.scheme;
  if (scheme == 'http' || scheme == 'https') {
    return Image.network(uri.toString(), errorBuilder: _imageError);
  }
  if (scheme == 'data') {
    final mime = uri.data?.mimeType ?? '';
    if (mime.startsWith('image/')) {
      return Image.memory(
        uri.data!.contentAsBytes(),
        errorBuilder: _imageError,
      );
    }
  }
  if (scheme == 'resource') {
    return Image.asset(uri.path, errorBuilder: _imageError);
  }
  if (scheme.isEmpty && directory != null) {
    return Image.file(
      File(p.join(directory, uri.path)),
      errorBuilder: _imageError,
    );
  }
  return Image.network(uri.toString(), errorBuilder: _imageError);
}

Widget _imageError(BuildContext context, Object error, StackTrace? stackTrace) {
  return const SizedBox();
}
