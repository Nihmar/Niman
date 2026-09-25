/// The state of a PDF in the note pane ([PdfDocumentView]).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_tracker.dart';
import 'package:niman/src/ui/annotation_mark_chooser.dart';
import 'package:niman/src/ui/attachment_bar.dart';
import 'package:niman/src/ui/attachment_unreadable.dart';
import 'package:niman/src/ui/file_marks.dart';
import 'package:niman/src/ui/pdf_document_view.dart';
import 'package:niman/src/ui/pdf_mark_layer.dart';
import 'package:niman/src/ui/place_link_button.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

/// The view's state: the PDF set where it was left or where a link
/// points, followed as it is read, annotated, and marked where it was.
final class PdfDocumentViewState extends State<PdfDocumentView> {
  final PdfViewerController _controller = PdfViewerController();
  late ReadingTracker _reading;
  late Future<BookLocation?> _left;

  /// The link's fragment last gone to: handed again as a tab comes back,
  /// it does not move the reader.
  String? _anchorTaken;

  /// Whether the PDF is laid out, and has pages to link to.
  bool _ready = false;

  /// The text selected, when some is.
  PdfTextSelection? _selection;

  /// The PDF's marks, while it is in a library that has them, and where
  /// they are drawn.
  FileMarks? _marks;
  final PdfMarkLayer _layer = PdfMarkLayer();
  int _layerLoads = 0;

  @override
  void initState() {
    super.initState();
    _follow();
    _controller.addListener(_onMove);
  }

  @override
  void didUpdateWidget(PdfDocumentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path == widget.path) {
      final anchor = widget.anchor;
      final again =
          anchor != _anchorTaken || widget.reloadToken != oldWidget.reloadToken;
      // Not laid out yet, the PDF takes the link when it is.
      if (anchor == null || !again || !_controller.isReady) return;
      _anchorTaken = anchor;
      final place = _linked();
      if (place == null) return;
      _reading.flush();
      unawaited(
        _show(_controller, place).then((shown) {
          if (shown) _reading.placed(place);
        }),
      );
      return;
    }
    _reading.flush();
    _ready = false;
    _follow();
  }

  @override
  void dispose() {
    _marks?.dispose();
    _controller.removeListener(_onMove);
    _reading.flush();
    super.dispose();
  }

  void _follow() {
    _reading = ReadingTracker(widget.positions, widget.path);
    _left = _reading.read();
    _marks?.dispose();
    _marks = null;
    final source = widget.marks;
    final key = widget.positions?.keyOf(widget.path);
    if (source == null || key == null) return;
    _marks = FileMarks(source, key)..addListener(() => unawaited(_drawMarks()));
  }

  /// Finds where the marks' passages are, once the PDF is laid out.
  Future<void> _drawMarks() async {
    final marks = _marks?.marks;
    if (marks == null || !_controller.isReady) return;
    final load = ++_layerLoads;
    await _layer.load(_controller.document, marks);
    if (mounted && load == _layerLoads) setState(() {});
  }

  /// Opens the annotations [marks] stand for.
  void _openMarks(List<AnnotationMark> marks) {
    final source = widget.marks;
    if (source != null) unawaited(openAnnotationMarks(context, marks, source));
  }

  /// Sets the PDF, once it is laid out, at the link's page, else where it
  /// was left, else at its first page.
  Future<void> _place(PdfViewerController controller) async {
    final reading = _reading;
    final left = await _left;
    if (!mounted || !identical(reading, _reading)) return;
    setState(() => _ready = true);
    unawaited(_drawMarks());
    _anchorTaken = widget.anchor;
    for (final place in [_linked(), if (left is PdfLocation) left]) {
      if (place != null && await _show(controller, place)) {
        reading.placed(place);
        return;
      }
    }
    reading.placed(null);
  }

  /// The page the link's fragment names, when it names one.
  PdfLocation? _linked() =>
      switch (BookLocation.fromFragment(widget.anchor ?? '')) {
        final PdfLocation place => place,
        _ => null,
      };

  /// Goes to [place], if the PDF has its page.
  Future<bool> _show(PdfViewerController controller, PdfLocation place) async {
    final pages = controller.layout.pageLayouts;
    if (place.page > pages.length) return false;
    final page = pages[place.page - 1];
    await controller.goToPosition(
      documentOffset: Offset(
        controller.visibleRect.left,
        page.top + place.fraction * page.height,
      ),
    );
    return true;
  }

  void _onMove() {
    if (!_controller.isReady) return;
    final here = pdfLocationAt(
      _controller.layout.pageLayouts,
      _controller.visibleRect.top,
    );
    if (here != null) _reading.moved(here);
  }

  /// The page being read, for a link to it.
  PlaceToLink? _here() {
    final path = widget.positions?.keyOf(widget.path);
    if (path == null || !_controller.isReady) return null;
    final place = pdfLocationAt(
      _controller.layout.pageLayouts,
      _controller.visibleRect.top,
    );
    if (place == null) return null;
    return (path: path, place: place, label: _label(place.page));
  }

  /// Whether a passage or a page can be annotated: the PDF is in a
  /// library, and someone writes annotations.
  bool get _annotates => widget.onAnnotate != null && widget.positions != null;

  /// Annotates the passage [selection] holds: its first page's characters,
  /// quoting all of it.
  Future<void> _annotateSelection(PdfTextSelection selection) async {
    final key = widget.positions?.keyOf(widget.path);
    final ranges = await selection.getSelectedTextRanges();
    if (key == null || ranges.isEmpty) return;
    final text = await selection.getSelectedText();
    final first = ranges.first;
    widget.onAnnotate?.call(
      Annotation(
        path: key,
        place: PdfLocation(
          page: first.pageNumber,
          chars: (start: first.start, end: first.end),
        ),
        label: _label(first.pageNumber),
        quote: text,
      ),
    );
  }

  /// Annotates the passage selected, else the page being read.
  void _annotateHere() {
    final selection = _selection;
    if (selection != null && selection.hasSelectedText) {
      unawaited(_annotateSelection(selection));
      return;
    }
    final here = _here();
    if (here == null) return;
    final page = (here.place as PdfLocation).page;
    widget.onAnnotate?.call(
      Annotation(
        path: here.path,
        place: PdfLocation(page: page),
        label: here.label,
      ),
    );
  }

  /// A selection's menu, with the passage's annotation.
  void _selectionMenu(
    PdfViewerContextMenuBuilderParams params,
    List<ContextMenuButtonItem> items,
  ) {
    final selection = params.textSelectionDelegate;
    if (!_annotates || !selection.hasSelectedText) return;
    items.add(
      ContextMenuButtonItem(
        label: AppStrings.annotateAction,
        onPressed: () {
          params.dismissContextMenu();
          unawaited(_annotateSelection(selection));
        },
      ),
    );
  }

  String _label(int page) =>
      AppStrings.pdfPageLabel(p.basenameWithoutExtension(widget.path), page);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: PdfViewer.file(
          widget.path,
          key: const Key('attachment-pdf'),
          controller: _controller,
          params: PdfViewerParams(
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerLowest,
            onViewerReady: (document, controller) =>
                unawaited(_place(controller)),
            pageOverlaysBuilder: (context, pageRect, page) => _layer.overlays(
              context,
              pageRect,
              page,
              _marks?.marks ?? const [],
              onTap: _openMarks,
            ),
            errorBannerBuilder: (context, error, stack, documentRef) =>
                const AttachmentUnreadable(),
            textSelectionParams: PdfTextSelectionParams(
              onTextSelectionChange: (selection) => _selection = selection,
            ),
            customizeContextMenuItems: _selectionMenu,
          ),
        ),
      ),
      AttachmentBar(
        path: widget.path,
        launcher: widget.launcher,
        actions: [
          PlaceLinkButton(
            here: _ready && widget.positions != null ? _here : null,
            linkType: widget.linkType,
          ),
          IconButton(
            key: const Key('annotate-button'),
            tooltip: AppStrings.annotateAction,
            icon: const Icon(Icons.edit_note),
            visualDensity: VisualDensity.compact,
            onPressed: _ready && _annotates ? _annotateHere : null,
          ),
        ],
      ),
    ],
  );
}
