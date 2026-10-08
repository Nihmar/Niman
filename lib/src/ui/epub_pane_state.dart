/// The state of the book's pane ([EpubPane]): the book read, set where it
/// was left or where a link points, followed as it is read, and marked
/// where it was annotated.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/epub/epub_marks.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/read_selection.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_tracker.dart';
import 'package:niman/src/ui/annotation_mark_chooser.dart';
import 'package:niman/src/ui/attachment_unreadable.dart';
import 'package:niman/src/ui/epub_bar.dart';
import 'package:niman/src/ui/epub_contents_sheet.dart';
import 'package:niman/src/ui/epub_links.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:niman/src/ui/epub_places.dart';
import 'package:niman/src/ui/epub_text_zoom.dart';
import 'package:niman/src/ui/epub_theme.dart';
import 'package:niman/src/ui/file_marks.dart';
import 'package:niman/src/ui/highlight_menu.dart';
import 'package:niman/src/ui/place_link_button.dart';
import 'package:niman/src/ui/strings.dart';

/// The pane's state, so a test can ask what it shows.
final class EpubPaneState extends State<EpubPane> {
  static const AppLogger _log = AppLogger(name: 'epub');

  final GlobalKey<MarkdownReadViewState> _readKey =
      GlobalKey<MarkdownReadViewState>();
  final ScrollController _scroll = ScrollController();
  final ReadParser _parser = ReadParser();
  final MathCache _mathCache = MathCache();

  /// The book, once read.
  EpubDocument? get document => _document;
  EpubDocument? _document;
  SourceBuffer? _buffer;

  /// Whether the book could not be read.
  bool get failed => _failed;
  bool _failed = false;

  /// Counts the opens, so a book replaced while it was read is dropped.
  int _opens = 0;

  late ReadingTracker _reading;

  /// The book's marks, while it is in a library that has them.
  FileMarks? _marks;

  /// The link's fragment last gone to: handed again as a tab comes back,
  /// it does not move the reader.
  String? _anchorTaken;

  /// The book over the whole window (#621), drawn in the root overlay. The
  /// pane moves there under [_paneKey], so it keeps its place and state.
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _paneKey = GlobalKey();
  final FocusNode _fullScreenFocus = FocusNode(debugLabel: 'epub full screen');

  /// Whether the book is read in full screen.
  bool get fullScreen => _fullScreen;
  bool _fullScreen = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.fullScreen?.addListener(_onFullScreen);
    unawaited(_open());
  }

  /// Follows the shell's word on who reads in full screen: this pane's own
  /// button, or the shell's Back.
  void _onFullScreen() {
    final on = widget.fullScreen?.value == this;
    if (on == _fullScreen) return;
    setState(() {
      _fullScreen = on;
      on ? _portal.show() : _portal.hide();
    });
    if (on) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _fullScreen) _fullScreenFocus.requestFocus();
      });
    }
  }

  void _toggleFullScreen() {
    final owner = widget.fullScreen;
    if (owner != null) owner.value = owner.value == this ? null : this;
  }

  @override
  void didUpdateWidget(EpubPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullScreen != widget.fullScreen) {
      oldWidget.fullScreen?.removeListener(_onFullScreen);
      widget.fullScreen?.addListener(_onFullScreen);
      _onFullScreen();
    }
    if (oldWidget.path == widget.path) {
      final anchor = widget.anchor;
      final document = _document;
      final again =
          anchor != _anchorTaken || widget.reloadToken != oldWidget.reloadToken;
      if (anchor == null || !again || document == null) return;
      // Still being read, the book takes the link when it opens.
      _anchorTaken = anchor;
      final place = _linked();
      if (place == null) return;
      _reading.flush();
      if (_show(document, place)) _reading.placed(place);
      return;
    }
    _reading.flush();
    // The build that follows shows the spinner until the new book is read.
    _document = null;
    _buffer = null;
    _failed = false;
    unawaited(_open());
  }

  @override
  void dispose() {
    final owner = widget.fullScreen?..removeListener(_onFullScreen);
    // A book closed in full screen takes the window out with it.
    if (owner?.value == this) owner!.value = null;
    _fullScreenFocus.dispose();
    _marks?.dispose();
    _reading.flush();
    _scroll.dispose();
    _mathCache.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final open = ++_opens;
    _followMarks();
    final reading = _reading = ReadingTracker(widget.positions, widget.path);
    try {
      final left = reading.read();
      final document = await openEpub(widget.path, await widget.cacheDir());
      final saved = switch (await left) {
        final EpubLocation location => location,
        _ => null,
      };
      if (!mounted || open != _opens) return;
      // An ad-hoc diagnostic (#303): what the chapters carried and what
      // the read text got of it.
      _log.info('epub "${widget.path}": ${_mathReport(document)}');
      setState(() {
        _document = document;
        _buffer = SourceBuffer.fromText(document.markdown);
      });
      // Once the view is there to be scrolled: the link's place, else
      // where the book was left, else its start.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || open != _opens) return;
        _anchorTaken = widget.anchor;
        final place = [_linked(), saved].firstWhere(
          (place) => place != null && _show(document, place),
          orElse: () => null,
        );
        reading.placed(place);
      });
    } on Object catch (error) {
      _log.warning('could not read ${widget.path}: $error');
      if (!mounted || open != _opens) return;
      setState(() => _failed = true);
    }
  }

  /// The place the link's fragment names, when it names one in a book.
  EpubLocation? _linked() =>
      switch (BookLocation.fromFragment(widget.anchor ?? '')) {
        final EpubLocation place => place,
        _ => null,
      };

  /// Scrolls to [place], if [document] has it.
  bool _show(EpubDocument document, EpubLocation place) {
    final line = document.lineOfLocation(place);
    if (line == null) return false;
    _readKey.currentState?.showAnchor((line: line, fraction: place.fraction));
    return true;
  }

  void _onScroll() {
    final anchor = _readKey.currentState?.topAnchor;
    final here = anchor == null
        ? null
        : _document?.locationAt(anchor.line, anchor.fraction);
    if (here != null) _reading.moved(here);
  }

  Future<void> _showContents() async {
    final document = _document;
    if (document == null) return;
    final top = _readKey.currentState?.topAnchor?.line ?? 0;
    final line = await showEpubContents(context, document, top);
    if (line != null) _readKey.currentState?.jumpToLine(line);
  }

  /// Follows the marks of the book now shown.
  void _followMarks() {
    _marks?.dispose();
    _marks = null;
    final source = widget.marks;
    final key = widget.positions?.keyOf(widget.path);
    if (source == null || key == null) return;
    _marks = FileMarks(source, key)..addListener(() => setState(() {}));
  }

  /// Opens the annotations of the paragraph over [start]..[end].
  void _openMarks(EpubDocument document, int start, int end) {
    final source = widget.marks;
    final marks = _marks?.marks;
    final key = widget.positions?.keyOf(widget.path);
    if (source == null || marks == null || key == null) return;
    final here = epubMarksBetween(document, marks, start, end);
    final following = _marks;
    unawaited(
      openAnnotationMarks(
        context,
        here,
        source,
        path: key,
        linkType: widget.linkType,
      ).then((_) => following?.refresh()),
    );
  }

  /// The book's places, as links and annotations name them.
  EpubPlaces get _places => EpubPlaces(
    path: widget.path,
    positions: widget.positions,
    document: _document,
    view: _readKey.currentState,
  );

  void _annotate(Annotation? annotation) {
    if (annotation != null) widget.onAnnotate?.call(annotation);
  }

  /// What a selection of the book offers (#283): highlighting it (#626) —
  /// first, where a phone keeps it in sight — annotating it and a link to
  /// it, in a library; copying it, anywhere.
  List<ReadSelectionAction> _selectionActions() => [
    if (widget.positions != null && widget.marks != null)
      (
        label: AppStrings.highlightAction,
        onPressed: (selection) {
          final source = widget.marks;
          final annotation = _places.selectionAnnotation(selection);
          if (source == null || annotation == null) return;
          final following = _marks;
          unawaited(
            highlightPassage(
              context,
              source,
              annotation,
            ).then((_) => following?.refresh()),
          );
        },
      ),
    if (widget.positions != null && widget.onAnnotate != null)
      (
        label: AppStrings.annotateAction,
        onPressed: (selection) =>
            _annotate(_places.selectionAnnotation(selection)),
      ),
    if (widget.positions != null)
      (
        label: AppStrings.copyPlaceLink,
        onPressed: (selection) {
          final at = _places.selected(selection);
          if (at != null) {
            unawaited(copyPlaceLink(context, at, widget.linkType));
          }
        },
      ),
  ];

  /// The zoom of the books' text, while the pane has a size to keep.
  EpubTextZoom? get _zoom => switch (widget.onTextScale) {
    final keep? => EpubTextZoom(keep),
    null => null,
  };

  /// [child] with the zoom keys bound over it: the pane in its place, and
  /// the focus the full screen takes, which the pane sits under.
  Widget _zoomKeys(Widget child) => switch (_zoom) {
    final zoom? => CallbackShortcuts(bindings: zoom.bindings, child: child),
    null => child,
  };

  @override
  Widget build(BuildContext context) {
    final pane = KeyedSubtree(
      key: _paneKey,
      child: ListenableBuilder(
        listenable: EpubLooks.revision,
        // The whole pane wears the book's look, its row included.
        builder: (context, _) => Theme(
          data: epubThemeOf(context),
          child: Builder(builder: _pane),
        ),
      ),
    );
    return OverlayPortal(
      controller: _portal,
      overlayLocation: OverlayChildLocation.rootOverlay,
      overlayChildBuilder: (context) => Positioned.fill(
        // Esc leaves, as it leaves Zen.
        child: _zoomKeys(
          Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => _toggleFullScreen(),
              ),
            },
            child: Focus(focusNode: _fullScreenFocus, child: pane),
          ),
        ),
      ),
      child: _fullScreen ? const SizedBox.expand() : _zoomKeys(pane),
    );
  }

  Widget _pane(BuildContext context) {
    final document = _document;
    final buffer = _buffer;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: _failed
                ? const AttachmentUnreadable()
                : document == null || buffer == null
                ? const Center(child: CircularProgressIndicator())
                : _book(context, document, buffer),
          ),
          EpubBar(
            path: widget.path,
            launcher: widget.launcher,
            linkType: widget.linkType,
            onEditLook: widget.onEditLook,
            onContents: document == null || document.contents.isEmpty
                ? null
                : () => unawaited(_showContents()),
            here: document == null || widget.positions == null
                ? null
                : () => _places.here(),
            onAnnotate:
                document == null ||
                    widget.positions == null ||
                    widget.onAnnotate == null
                ? null
                : () => _annotate(_places.annotationHere()),
            fullScreen: _fullScreen,
            onFullScreen: widget.fullScreen == null ? null : _toggleFullScreen,
          ),
        ],
      ),
    );
  }

  /// An ad-hoc diagnostic (#303): the book's math, and what the read text
  /// got of it.
  static String _mathReport(EpubDocument document) {
    final signs = RegExp(r'(?<!\\)\$').allMatches(document.markdown).length;
    final first = RegExp(r'(?<!\\)\$\$?[^\$\n]{1,60}')
        .firstMatch(document.markdown)
        ?.group(0);
    return '${document.mathReport ?? 'no math in the chapters'}; '
        'text: $signs dollar signs'
        '${first == null ? '' : ', first "$first"'}';
  }

  /// The book, at the books' text size rather than the interface one, as
  /// a note's read view is at the note's, zoomed by a pinch as a note is.
  Widget _book(
    BuildContext context,
    EpubDocument document,
    SourceBuffer buffer,
  ) {
    final book = _read(context, document, buffer);
    return _zoom?.pinch(book) ?? book;
  }

  Widget _read(
    BuildContext context,
    EpubDocument document,
    SourceBuffer buffer,
  ) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: epubTextScalerOf(context)),
    child: MarkdownReadView(
      key: _readKey,
      buffer: buffer,
      parser: _parser,
      mathCache: _mathCache,
      controller: _scroll,
      column: widget.column,
      onTapLink: (text, href) => followEpubLink(
        context,
        _document,
        href,
        jumpToLine: (line) => _readKey.currentState?.jumpToLine(line),
      ),
      embedResolver: (target) async => document.pictures[target],
      // A paragraph links, and annotates, only in a library.
      selectionActions: _selectionActions(),
      marks: epubBlockMarks(document, _marks?.marks ?? const []),
      onTapMark: (start, end) => _openMarks(document, start, end),
    ),
  );
}
