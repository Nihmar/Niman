/// The source mode of the unified surface: the note's own text, styled by the
/// engine's tokenizer, editable (#245, phase 3).
///
/// This is the **degenerate case** of the surface and the reason the phase
/// starts here: the rendered text *is* the source text, so a selection offset
/// is
/// a source offset, and no render map can hide an editing bug. `live` mode then
/// adds the marker hiding on top of this.
///
/// Three decisions worth naming:
///
/// * **A source line is the unit of layout**, drawn by one `Text.rich` of the
///   tokenizer's runs, wrapping like prose (`re_editor` wrapped, and a note's
///   paragraphs are one long line each — a source view that did not wrap would
///   need horizontal scrolling to read a sentence).
/// * **The caret comes from this surface's own layout**, never from a metric
///   computed beside it: the line that holds the caret hands out its
///   `RenderParagraph` and the rectangle is `getOffsetForCaret`, which is the
///   quantity `EditableText` computes for you and a surface that paints its own
///   text has to compute itself (phase 3's own exit criterion, and the reason a
///   previous attempt at this surface went). A tap lands through the same
/// paragraph's `getPositionForOffset`, so the rectangle and the hit test agree
///   by construction.
/// * **The windowing is the read view's**: the same `SliverMarkdownBlocks` and
///   the same height map. A note is a note whether it is being read or written.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// The source surface: the note's text, its caret, and where a tap lands.
final class MarkdownSourceView extends StatefulWidget {
  /// Shows [buffer] with [selection], styled with [theme].
  const new({
    required this.buffer,
    required this.theme,
    this.selection,
    this.onSelection,
    this.focusNode,
    this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showLineNumbers = true,
    this.syntax,
    this.dark = false,
    super.key,
  });

  /// The text on screen.
  final SourceBuffer buffer;

  /// The typography: the read view's theme, in monospace.
  final MarkdownTheme theme;

  /// Where the caret is, and what it has selected.
  final SelectionModel? selection;

  /// Called when a tap, or the platform, moves the caret — and when an edit
  /// moves it for them.
  final ValueChanged<SelectionModel>? onSelection;

  /// The keyboard focus, when the caller owns it (the shell does).
  final FocusNode? focusNode;

  /// The scroll position, when the caller owns one (an anchor jump does).
  final ScrollController? controller;

  /// The page margins.
  final EdgeInsets padding;

  /// Whether the gutter shows line numbers.
  final bool showLineNumbers;

  /// The token palette; null takes it from the ambient theme.
  final SyntaxColors? syntax;

  /// Whether bold is drawn a step lighter (the palette's own rule).
  final bool dark;

  @override
  State<MarkdownSourceView> createState() => MarkdownSourceViewState();
}

/// The source view's state, so a caller can ask where the caret is.
final class MarkdownSourceViewState extends State<MarkdownSourceView> {
  /// The tokenizer, kept across rebuilds: an edit re-tokenizes from the edit
  /// point on and nothing else (the 0.507 ms incremental-edit number the phase
  /// has to meet is this object's).
  late HighlightDocument _tokens;

  /// The heights the sliver places lines with.
  late BlockHeightMap _heights;

  /// The keyboard, wired to the buffer this view draws.
  late SourceInput _input;

  late ScrollController _scroll;
  bool _ownsScroll = false;
  late FocusNode _focus;
  bool _ownsFocus = false;

  /// Where the caret is when the caller does not hold one — an uncontrolled
  /// view, which is what a test and a quick screen both are.
  SelectionModel _ownSelection = const SelectionModel.at(0);

  /// The caret, from the caller when it holds one.
  SelectionModel get _selection => widget.selection ?? _ownSelection;

  /// The paragraph of each line a frame has built, so a tap can ask the line it
  /// landed on where an offset is, and the caret can ask its own line for the
  /// rectangle. Only mounted lines keep a key: a long scroll forgets the lines
  /// it left, which is what keeps this from growing with the note.
  final Map<int, GlobalKey> _lineKeys = <int, GlobalKey>{};

  /// The caret rectangle in the caret line's coordinates, recomputed after the
  /// frame that laid that line out. A notifier rather than `setState`: neither
  /// the blink nor the measurement may rebuild the note.
  final ValueNotifier<Rect?> _caretRect = ValueNotifier<Rect?>(null);

  /// Whether the caret is drawn (it blinks).
  final ValueNotifier<bool> _caretOn = ValueNotifier<bool>(true);
  Timer? _blink;

  @override
  void initState() {
    super.initState();
    _tokens = HighlightDocument.fromText(widget.buffer.text);
    _scroll = widget.controller ?? ScrollController();
    _ownsScroll = widget.controller == null;
    _focus = widget.focusNode ?? FocusNode();
    _ownsFocus = widget.focusNode == null;
    _heights = _map();
    _input = SourceInput(
      buffer: widget.buffer,
      onTokenizer: (edit, buffer) =>
          SourceInput.retokenize(_tokens, edit, buffer),
      selection: () => _selection,
      onSelection: (next) {
        setState(() => _ownSelection = next);
        widget.onSelection?.call(next);
        _scheduleCaret();
      },
      onEdited: (_) {
        setState(() {
          _heights = _map();
          _ownSelection = _ownSelection.clampTo(widget.buffer.length);
        });
        _scheduleCaret();
        _ensureCaretVisible();
      },
    );
    _blink = Timer.periodic(const Duration(milliseconds: 550), (_) {
      _caretOn.value = !_caretOn.value;
    });
    _scheduleCaret();
  }

  @override
  void didUpdateWidget(MarkdownSourceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buffer.revision != widget.buffer.revision) {
      // An edit this view did not make (a command, a revert): the tokenizer is
      // rebuilt rather than adjusted, because there is no `SourceEdit` to
      // follow.
      _tokens = HighlightDocument.fromText(widget.buffer.text);
      _heights = _map();
    }
    if (oldWidget.selection != widget.selection) _scheduleCaret();
    if (oldWidget.controller != widget.controller) {
      if (_ownsScroll) _scroll.dispose();
      _scroll = widget.controller ?? ScrollController();
      _ownsScroll = widget.controller == null;
    }
  }

  @override
  void dispose() {
    _input.detach();
    if (_ownsFocus) _focus.dispose();
    _blink?.cancel();
    _caretRect.dispose();
    _caretOn.dispose();
    if (_ownsScroll) _scroll.dispose();
    super.dispose();
  }

  /// How many source lines the note has.
  int get lineCount => _tokens.lineCount;

  /// The keyboard focus, for a shell that wants to raise the keyboard.
  FocusNode get focusNode => _focus;

  /// Whether the platform is attached to this surface (the keyboard is up).
  bool get isKeyboardAttached => _input.isAttached;

  /// How many updates arrived as deltas, and how many of those arrived with an
  /// `oldText` that disagreed with the buffer.
  int get deltaCount => _input.deltaCount;

  /// The count of deltas that had to be recovered onto the platform's text.
  int get recoveredDeltas => _input.recoveredDeltas;

  /// The caret's rectangle in the note's own coordinates, or null before the
  /// frame that measured it.
  Rect? get caretRect {
    final rect = _caretRect.value;
    final line = _paragraphAt(_caretLineIndex);
    if (rect == null || line == null || !line.attached) return null;
    return rect.shift(line.localToGlobal(Offset.zero));
  }

  /// The offset a tap at [global] lands on, or null when it lands outside a
  /// line.
  int? offsetAt(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final local = box.globalToLocal(global) - widget.padding.topLeft;
    final line = _heights.indexAt(local.dy + _scroll.offset);
    if (line == null) return null;
    final paragraph = _paragraphAt(line);
    if (paragraph == null) return null;
    final lineTop = _heights.offsetOf(line) - _scroll.offset;
    final position = paragraph.getPositionForOffset(local - Offset(0, lineTop));
    return widget.buffer.offsetOfLine(line) + position.offset;
  }

  /// Scrolls so [line] is at the top, as far as the map knows.
  void jumpToLine(int line) {
    if (line < 0 || line >= _tokens.lineCount || !_scroll.hasClients) return;
    _scroll.jumpTo(
      _heights.offsetOf(line).clamp(0.0, _scroll.position.maxScrollExtent),
    );
    _scheduleCaret();
  }

  /// Puts the caret at [offset], tells the platform, and keeps it on screen.
  void placeCaret(int offset) {
    final next = _selection.collapsedTo(offset).clampTo(widget.buffer.length);
    setState(() => _ownSelection = next);
    widget.onSelection?.call(next);
    _input.sendSelection();
    _scheduleCaret();
    _ensureCaretVisible();
  }

  /// Scrolls the caret's line into view when an edit or a jump left it out.
  void _ensureCaretVisible() {
    if (!_scroll.hasClients) return;
    final line = _caretLineIndex;
    if (line < 0) return;
    final top = _heights.offsetOf(line);
    final bottom = top + _heights.extentFor(line);
    final viewport = _scroll.position.viewportDimension;
    if (top < _scroll.offset) {
      _scroll.jumpTo(top);
    } else if (bottom > _scroll.offset + viewport) {
      _scroll.jumpTo(
        (bottom - viewport).clamp(0.0, _scroll.position.maxScrollExtent),
      );
    }
  }

  /// The paragraph of line [line], when a frame has built it.
  RenderParagraph? _paragraphAt(int line) {
    final object = _lineKeys[line]?.currentContext?.findRenderObject();
    return object is RenderParagraph ? object : null;
  }

  /// The key of line `index`'s paragraph, created on first use.
  GlobalKey _keyFor(int index) {
    final key = _lineKeys.putIfAbsent(index, GlobalKey.new);
    if (_lineKeys.length > 512) {
      _lineKeys.removeWhere((_, key) => key.currentContext == null);
    }
    return key;
  }

  /// The line the caret sits on, or -1.
  int get _caretLineIndex {
    final line = widget.buffer.lineOf(_selection.extent);
    return line < 0 || line >= _tokens.lineCount ? -1 : line;
  }

  BlockHeightMap _map() =>
      BlockHeightMap(count: _tokens.lineCount, estimate: _estimate);

  /// A line's height before a frame has drawn it: its character count over the
  /// width a line holds, which is the same shape the read view's estimator has
  /// and is corrected by the sliver's own measurement.
  double _estimate(int index) {
    final text = _tokens.lineAt(index).text;
    final columns = _columnsPerLine;
    final visual = text.isEmpty ? 1 : (text.length / columns).ceil();
    return visual * widget.theme.lineHeight;
  }

  /// Roughly how many monospace characters fit a line at this width and size.
  ///
  /// The pane's real width is not known here (the estimator is asked before a
  /// frame), so this is deliberately a *shape* and not a measurement: the
  /// sliver
  /// replaces every estimate with the line's own height as soon as it draws it,
  /// and only a jump made before that first frame can see the difference.
  double get _columnsPerLine {
    final size = widget.theme.body.fontSize ?? 14;
    final advance = size * 0.6;
    return advance <= 0 ? 1 : 320 / advance;
  }

  /// Measures the caret after the frame that laid its line out.
  void _scheduleCaret() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final line = _caretLineIndex;
      final paragraph = _paragraphAt(line);
      if (paragraph == null || line < 0) {
        _caretRect.value = null;
        return;
      }
      final local = _selection.extent - widget.buffer.offsetOfLine(line);
      final length = paragraph.text.toPlainText().length;
      final position = TextPosition(offset: local.clamp(0, length));
      // The caret is the *surface's* answer, not a metric computed beside it:
      // the painter reports the offset the way it paints it, over the run it is
      // really over. The prototype's width matters only on the RTL side and its
      // height not at all (the phase-1 spike), so the height comes from the
      // line.
      final rect = paragraph.getOffsetForCaret(
        position,
        const Rect.fromLTWH(0, 0, 1.5, 0),
      );
      _caretRect.value = Rect.fromLTWH(
        rect.dx,
        rect.dy,
        1.5,
        paragraph.getFullHeightForCaret(position),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final syntax = widget.syntax ?? SyntaxColors.of(context);
    final caretLine = _caretLineIndex;
    return Focus(
      focusNode: _focus,
      onFocusChange: (hasFocus) => hasFocus ? _input.attach() : _input.detach(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - widget.padding.horizontal;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _focus.requestFocus(),
            onTapUp: (details) {
              final offset = offsetAt(details.globalPosition);
              if (offset != null) placeCaret(offset);
            },
            child: CustomScrollView(
              controller: _scroll,
              slivers: <Widget>[
                SliverPadding(
                  padding: widget.padding,
                  sliver: SliverMarkdownBlocks(
                    heights: _heights,
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _Line(
                        key: ValueKey<int>(index),
                        paragraphKey: _keyFor(index),
                        styled: _tokens.lineAt(index),
                        number: widget.showLineNumbers ? index + 1 : null,
                        theme: widget.theme,
                        syntax: syntax,
                        dark: widget.dark,
                        width: available,
                        caret: index == caretLine ? _caretRect : null,
                        caretOn: _caretOn,
                      );
                    }, childCount: _tokens.lineCount),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One source line: its gutter number, its styled runs, and its caret.
final class _Line extends StatelessWidget {
  const new({
    required this.paragraphKey,
    required this.styled,
    required this.number,
    required this.theme,
    required this.syntax,
    required this.dark,
    required this.width,
    required this.caret,
    required this.caretOn,
    super.key,
  });

  /// The key of the line's own paragraph, so the surface can ask it for a caret
  /// offset or a caret rectangle.
  final GlobalKey paragraphKey;

  final StyledLine styled;
  final int? number;
  final MarkdownTheme theme;
  final SyntaxColors syntax;
  final bool dark;

  /// The width the line's text wraps at (the pane minus the gutter).
  final double width;

  /// The caret rectangle, for the line that holds the caret.
  final ValueNotifier<Rect?>? caret;
  final ValueNotifier<bool> caretOn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (number != null)
            SizedBox(
              width: 44,
              child: Text(
                '$number',
                textAlign: TextAlign.right,
                style: theme.marker.copyWith(
                  fontSize: (theme.body.fontSize ?? 14) * 0.8,
                ),
              ),
            ),
          Expanded(
            child: _caretBox(
              Text.rich(_span(), key: paragraphKey, style: theme.body),
            ),
          ),
        ],
      ),
    );
  }

  /// [child] with the caret painted over it.
  ///
  /// A `foregroundPainter` rather than a `Stack`: a sliver lays its children
  /// out
  /// with unbounded main-axis constraints — that is what makes it measure them
  /// —
  /// and a `Stack` needs a bound it cannot have here. The painter draws on top
  /// of
  /// the text it belongs to, which is also what a caret is.
  Widget _caretBox(Widget child) {
    final rect = caret;
    if (rect == null) return child;
    return ValueListenableBuilder<Rect?>(
      valueListenable: rect,
      builder: (context, value, child) => ValueListenableBuilder<bool>(
        valueListenable: caretOn,
        builder: (context, on, child) => CustomPaint(
          foregroundPainter: on && value != null ? _CaretPainter(value) : null,
          child: child,
        ),
        child: child,
      ),
      child: child,
    );
  }

  /// The line's tokens as styled runs. A token's override never changes the
  /// size
  /// or the height, so a line keeps the surface's metrics whatever it contains
  /// (`highlight_style.dart`).
  TextSpan _span() {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final token in styled.tokens) {
      if (token.start > at) {
        spans.add(TextSpan(text: styled.text.substring(at, token.start)));
      }
      spans.add(
        TextSpan(
          text: styled.text.substring(token.start, token.end),
          style: markdownTokenStyle(token.kind, syntax, dark: dark),
        ),
      );
      at = token.end;
    }
    if (at < styled.text.length) {
      spans.add(TextSpan(text: styled.text.substring(at)));
    }
    return TextSpan(children: spans);
  }
}

/// Draws the caret: a thin vertical bar at the rectangle the line's own layout
/// answered with.
final class _CaretPainter extends CustomPainter {
  const new(this.rect);

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
      Paint()..color = const Color(0xFF7AA2F7),
    );
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => oldDelegate.rect != rect;
}
