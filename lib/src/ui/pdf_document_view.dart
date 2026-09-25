/// A PDF in the note pane, its pages one under the other, zoomed with a
/// pinch or Ctrl+wheel, opening where it was left ([ReadingPositions]) or
/// at the page the link it was opened by names (`#page=34`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/reading/reading_tracker.dart';
import 'package:niman/src/ui/attachment_bar.dart';
import 'package:niman/src/ui/attachment_unreadable.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/place_link_button.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

/// The place of a PDF laid out as [pages], one under the other, at [top]
/// of the document: the page it is on, or the one below the gap it is
/// in, and how far down it; null for a PDF with no pages.
PdfLocation? pdfLocationAt(List<Rect> pages, double top) {
  for (final (index, page) in pages.indexed) {
    if (page.bottom > top || index == pages.length - 1) {
      final into = page.height > 0 ? (top - page.top) / page.height : 0.0;
      return PdfLocation(page: index + 1, fraction: into.clamp(0.0, 1.0));
    }
  }
  return null;
}

/// The PDF at [path], an absolute path, and its row: its name, a link to
/// the page being read (#282), on desktop the system's application.
final class PdfDocumentView extends StatefulWidget {
  /// Shows the PDF at [path].
  const new({
    required this.path,
    required this.launcher,
    this.linkType = LinkType.wikilink,
    this.positions,
    this.anchor,
    this.reloadToken = 0,
    super.key,
  });

  /// The PDF's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  /// How the library writes links, for the one to the page being read.
  final LinkType linkType;

  /// Where the library keeps its reading positions; null keeps none, and
  /// the PDF opens at its first page.
  final ReadingPositions? positions;

  /// The fragment of the link the PDF was opened by (#282): `page=34`. It
  /// wins over where the PDF was left.
  final String? anchor;

  /// Bumped when the same link is followed again, so the PDF goes back to
  /// its page.
  final int reloadToken;

  @override
  State<PdfDocumentView> createState() => _PdfDocumentViewState();
}

final class _PdfDocumentViewState extends State<PdfDocumentView> {
  final PdfViewerController _controller = PdfViewerController();
  late ReadingTracker _reading;
  late Future<BookLocation?> _left;

  /// The link's fragment last gone to: handed again as a tab comes back,
  /// it does not move the reader.
  String? _anchorTaken;

  /// Whether the PDF is laid out, and has pages to link to.
  bool _ready = false;

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
    _controller.removeListener(_onMove);
    _reading.flush();
    super.dispose();
  }

  void _follow() {
    _reading = ReadingTracker(widget.positions, widget.path);
    _left = _reading.read();
  }

  /// Sets the PDF, once it is laid out, at the link's page, else where it
  /// was left, else at its first page.
  Future<void> _place(PdfViewerController controller) async {
    final reading = _reading;
    final left = await _left;
    if (!mounted || !identical(reading, _reading)) return;
    setState(() => _ready = true);
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
    final name = p.basenameWithoutExtension(widget.path);
    return (
      path: path,
      place: place,
      label: AppStrings.pdfPageLabel(name, place.page),
    );
  }

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
            errorBannerBuilder: (context, error, stack, documentRef) =>
                const AttachmentUnreadable(),
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
        ],
      ),
    ],
  );
}
