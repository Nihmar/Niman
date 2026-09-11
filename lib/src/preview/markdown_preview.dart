import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/preview/aspect_image.dart';
import 'package:niman/src/preview/block_parse.dart';
import 'package:niman/src/preview/html_table.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_syntax.dart';
import 'package:niman/src/preview/math_widget.dart';
import 'package:niman/src/preview/preview_work.dart';
import 'package:niman/src/preview/scroll_map.dart';
import 'package:niman/src/preview/wikilink.dart';
import 'package:path/path.dart' as p;

/// The windowed Markdown preview (M2 T-M2-04).
///
/// Parses the document's block phase once per change, and each block's
/// inline content when the block first builds (block_parse.dart — the old
/// whole-document parse split 14 ms of blocks and 378 ms of inlines on the
/// 931K note), laying out **only the blocks the viewport shows** via a
/// [SliverList]. This is the design's windowing rule: the package's own
/// `Markdown` view hands the whole document to an eager `Column`/`ListView`
/// (measured ~2.1 s for a 200 KB buffer) — never do that.
///
/// Tables, task lists, footnotes, strikethrough and links come from the
/// GFM extension set + the package's own builders; code blocks are
/// highlighted by [syntaxHighlighter].
final class MarkdownPreview extends StatefulWidget {
  /// Creates a preview over [data].
  const new({
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
    this.onWikiLink,
    this.embedResolver,
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

  /// Wikilink callback (T-M3-07): called with the parsed `[[…]]` ref (and
  /// its display text) when a wikilink is tapped.
  final void Function(WikiRef ref, String display)? onWikiLink;

  /// Resolves an `![[…]]` embed target to an absolute file path (or null);
  /// images render inline, other targets as muted path text. When null,
  /// embeds render as plain text.
  final Future<String?> Function(String target)? embedResolver;

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

  /// The parsed top-level blocks (null before the first parse completes) —
  /// the block phase only (block_parse.dart): the 4 % of the old
  /// whole-document parse cost, with each block's inline content still raw.
  List<md.Node>? _nodes;

  /// Per-block inline results ([withInlines]), filled when the block first
  /// builds; fresh on every re-parse.
  List<List<md.Node>?>? _inlines;

  /// The per-pass parser state: one document covers every block inlined
  /// this pass (footnote references must number as a whole-document parse
  /// would — blocks build in the viewport's order, not the note's — see
  /// [prepareInlines]).
  late md.Document? _doc;

  /// The [MarkdownBuilder] for this pass (style-dependent; built alongside
  /// [_nodes]).
  late MarkdownBuilder? _builder;

  /// The spacing between two blocks this pass (the style sheet's; read
  /// where the sheet is built in [_applyParse]).
  double _spacing = 8;

  late final MathCache _mathCache = widget.mathCache ?? MathCache();

  /// Bumped per parse so a stale isolate result is dropped.
  int _parseRevision = 0;

  /// Whether the preview is mid-scroll (see [MathDeferScope]).
  bool _scrolling = false;
  Timer? _settleTimer;

  /// Below this size the parse stays synchronous (the divide is a single
  /// frame's cost); above it the block phase runs on a background isolate
  /// so a 931K note never janks the UI (the measured 418 ms whole-doc
  /// parse, T-M2-05 — its inline phase now runs per block as the blocks
  /// build instead). Even the block phase alone is ~3 ms on the 931K note.
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
    _settleTimer?.cancel();
    _disposeRecognizers();
    if (widget.mathCache == null) _mathCache.dispose();
    super.dispose();
  }

  /// Tracks the scroll gesture: the math views below hold their
  /// placeholders until a short settle after the last notification, so a
  /// gesture never pays the typesetting (T-PP-22). Any notification counts
  /// as activity — an interrupted fling that never reports an end must not
  /// leave every formula as a placeholder forever.
  void _onScrollNotification(ScrollNotification notification) {
    _settleTimer?.cancel();
    if (!_scrolling) setState(() => _scrolling = true);
    _settleTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted && _scrolling) setState(() => _scrolling = false);
    });
  }

  /// Takes a block's measured height and asks for one more layout when it
  /// disagrees with the extent the sliver just used. The map keeps the
  /// change until the frame is over (`ScrollMap.applyMeasurements`), so no
  /// block moves under the sliver mid-pass; the next pass then places every
  /// block at its real height. It settles in one extra frame — a block
  /// measured with the same width measures the same.
  void _onBlockMeasured(int index, double height) {
    final map = widget.scrollMap;
    if (map == null) return;
    map.measure(index, height);
    if (_extentSyncScheduled) return;
    _extentSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extentSyncScheduled = false;
      if (!mounted) return;
      if (widget.scrollMap?.applyMeasurements() ?? false) setState(() {});
    });
  }

  /// Whether a post-frame extent sync is already booked.
  bool _extentSyncScheduled = false;

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _parse() {
    final revision = ++_parseRevision;
    // The frontmatter is not parsed, but the map still counts its lines:
    // the editor beside this pane numbers them (T-M2-06).
    final offset = frontmatterLines(widget.data);
    final source = stripFrontmatter(widget.data);
    final clock = Stopwatch()..start();

    if (source.length <= _syncParseLimit) {
      _applyParse(revision, source, parseBlocks(source), offset);
      const AppLogger(name: 'preview').debug(
        'parse sync: ${_nodes?.length} blocks, ${source.length} chars in '
        '${clock.elapsedMilliseconds}ms',
      );
      return;
    }
    // Large document: the block phase off the UI isolate (the nodes are
    // plain data).
    unawaited(
      PreviewWork.run('parse', source).then((result) {
        if (!mounted || revision != _parseRevision) return;
        if (result is! List<md.Node>) {
          const AppLogger(name: 'preview')
              .error('async parse failed (${source.length} chars): $result');
          return;
        }
        const AppLogger(name: 'preview').debug(
          'parse async: ${result.length} blocks, ${source.length} chars in '
          '${clock.elapsedMilliseconds}ms',
        );
        _applyParse(revision, source, result, offset);
      }),
    );
  }

  void _applyParse(
    int revision,
    String source,
    List<md.Node> nodes,
    int lineOffset,
  ) {
    final clock = Stopwatch()..start();
    if (!mounted || revision != _parseRevision) return;
    final theme = Theme.of(context);
    // The task-list boxes take the accent, not `ThemeData.primaryColor`
    // (2026-09-10 device report: they were invisible in the dark). That
    // field is a Material 1 leftover, and a dark `ThemeData` sets it to
    // the *surface* color — so the package's default painted every
    // checkbox in the color of the page behind it. The boxes were there
    // and laid out; they simply could not be seen.
    final styleSheet = MarkdownStyleSheet.fromTheme(theme)
        .copyWith(
          checkbox: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        )
        .merge(widget.styleSheet);
    _spacing = styleSheet.blockSpacing ?? 8.0;
    _builder = MarkdownBuilder(
      delegate: this,
      selectable: false,
      styleSheet: styleSheet,
      imageDirectory: widget.imageDirectory,
      imageBuilder:
          widget.imageBuilder ??
          (widget.imageDirectory == null
              ? null
              : (uri, title, alt) => _imageFor(uri, widget.imageDirectory)),
      checkboxBuilder: widget.checkboxBuilder,
      bulletBuilder: widget.bulletBuilder,
      builders: <String, MarkdownElementBuilder>{
        ...widget.builders,
        if (widget.onWikiLink != null)
          'wikilink': WikilinkBuilder(
            onWikiRef: widget.onWikiLink!,
            recognizers: _recognizers,
          ),
        if (widget.embedResolver != null)
          'embed': EmbedBuilder(onResolve: widget.embedResolver!),
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
    // The inline phase is not paid here: each block pays for it when it
    // builds ([_blockAt]) — ~0.1 ms a block, the visible blocks first, so a
    // keystroke no longer blocks on the whole document's inlines (378 ms on
    // the 931K note; block_parse.dart).
    final doc = makeDocument();
    prepareInlines(doc, nodes);
    setState(() {
      _nodes = nodes;
      _doc = doc;
      _inlines = List<List<md.Node>?>.filled(nodes.length, null);
    });
    final map = widget.scrollMap;
    map?.rebuild(source, lineOffset: lineOffset);
    // The map pairs its blocks with these nodes by position, so a parser
    // the locator does not agree with puts the two panes out of step for
    // the rest of the document. Say so rather than drift.
    if (map != null && map.blockStartLines.length != nodes.length) {
      const AppLogger(name: 'preview').warning(
        'scroll map: ${nodes.length} blocks against '
        '${map.blockStartLines.length} located',
      );
    }
    const AppLogger(name: 'preview').debug(
      'apply parse: ${nodes.length} top-level nodes, '
      '${source.length} chars in ${clock.elapsedMilliseconds}ms',
    );
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

  /// The widget for block [index]: its inline content is paid here, on the
  /// block's first build only — ~0.1 ms a block (block_parse.dart; the old
  /// whole-document inline phase was 378 ms, paid up front). One sliver
  /// child per top-level node, not one per built widget: the package
  /// appends a block-spacing `SizedBox` after every block, so its flat list
  /// has more entries than the source has blocks and the scroll map's
  /// per-block measurements drifted by one every block (T-PP-22); grouping a
  /// node's widgets keeps the map's block index = node index (the locator
  /// tests assert the two counts match). The package spaces the blocks it
  /// puts inside one parent, and every block here is built alone — so the
  /// gap between two blocks is this pane's to add.
  Widget _blockAt(int index) {
    var inlines = _inlines?[index];
    if (inlines == null) {
      inlines = withInlines(_doc!, _nodes![index]);
      _inlines![index] = inlines;
    }
    final block = _builder!.build(inlines);
    final content = Padding(
      padding: EdgeInsets.only(bottom: _spacing),
      child: block.length == 1
          ? block.single
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: block,
            ),
    );
    final map = widget.scrollMap;
    if (map == null) return content;
    // The sliver forces each child's extent (the map's estimate), so the
    // measure sits inside an unbounded box: it reports the block's natural
    // height, which the map then uses as the real extent.
    //
    // Unbounded at *both* ends. The sliver's constraint is tight, and an
    // OverflowBox inherits the minimum it does not override — so with only
    // `maxHeight` relaxed every block was stretched to the estimate it was
    // supposed to correct, reported that back as its height, and kept it
    // forever: a short block (a heading, a quote, a display formula) sat in
    // a box sized by its line count, and the map's own average drifted
    // upward with it (device report, 2026-09-10).
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: _BlockMeasure(
        onHeight: (height) => _onBlockMeasured(index, height),
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _nodes?.length ?? 0;
    final map = widget.scrollMap;
    map?.contentInset = widget.padding.top;
    final delegate = map == null
        ? SliverChildBuilderDelegate(
            (context, index) => _blockAt(index),
            childCount: count,
          )
        : _MappedChildDelegate(
            (context, index) => _blockAt(index),
            childCount: count,
            map: map,
          );
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _onScrollNotification(notification);
        return false;
      },
      child: MathDeferScope(
        deferring: _scrolling,
        child: CustomScrollView(
          controller: widget.controller,
          slivers: <Widget>[
            SliverPadding(
              padding: widget.padding,
              // With a scroll map every block has a known (or estimated)
              // extent, so a jump lays out only the blocks it lands on
              // instead of walking every block in between — the difference
              // between a smooth jump and a 5 ms-per-block stall on a
              // math-heavy note (T-PP-22).
              sliver: map == null
                  ? SliverList(delegate: delegate)
                  : SliverVariedExtentList(
                      delegate: delegate,
                      itemExtentBuilder: (index, dimensions) =>
                          map.extentFor(index),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The preview's children, with the document's real height attached.
///
/// A lazy list otherwise guesses its scrollable extent from the children it
/// has laid out: on a long note that guess is a small fraction of the
/// truth, and every jump beyond it is clamped — which is what pulled the
/// preview away from the editor (device report, 2026-09-10). The map holds
/// an extent for every block, so it can say.
final class _MappedChildDelegate extends SliverChildBuilderDelegate {
  new(super.builder, {required this.map, super.childCount});

  final ScrollMap map;

  @override
  double? estimateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) => map.totalExtent();
}

/// Reports its child's height after layout (the scroll map's per-block
/// measurement — the mapping table's pixel side).
final class _BlockMeasure extends SingleChildRenderObjectWidget {
  const new({required this.onHeight, required super.child});

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
  new(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}

/// Resolves an image URI (T-M2-09). Relative links (`scheme` empty, e.g.
/// `assets/pic.png`) load from [directory] — the library root; absolute
/// http(s)/data/resource URIs keep the package's behavior. The result is
/// an [AspectImage], so the block reserves the image's box instead of
/// growing when the bytes land (T-PP-22); a missing/unreadable file
/// renders as an empty box.
Widget _imageFor(Uri uri, String? directory) {
  final provider = _providerFor(uri, directory);
  if (provider == null) return const SizedBox();
  return AspectImage(provider: provider, errorBuilder: _imageError);
}

/// The [ImageProvider] for an image URI, or null for a data URI that is
/// not an image.
ImageProvider? _providerFor(Uri uri, String? directory) {
  final scheme = uri.scheme;
  if (scheme == 'http' || scheme == 'https') {
    return NetworkImage(uri.toString());
  }
  if (scheme == 'data') {
    final mime = uri.data?.mimeType ?? '';
    if (mime.startsWith('image/')) {
      return MemoryImage(uri.data!.contentAsBytes());
    }
    return null;
  }
  if (scheme == 'resource') return AssetImage(uri.path);
  if (scheme.isEmpty && directory != null) {
    return FileImage(File(p.join(directory, uri.path)));
  }
  return NetworkImage(uri.toString());
}

Widget _imageError(BuildContext context, Object error, StackTrace? stackTrace) {
  return const SizedBox();
}
