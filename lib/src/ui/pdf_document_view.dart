/// A PDF in the note pane, its pages one under the other, zoomed with a
/// pinch or Ctrl+wheel, opening where it was left ([ReadingPositions]) or
/// at the page the link it was opened by names (`#page=34`), marked where
/// it was annotated (#285).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/pdf_document_view_state.dart';

export 'package:niman/src/ui/pdf_document_view_state.dart'
    show PdfDocumentViewState;

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
/// the page being read (#282), annotating it (#284), on desktop the
/// system's application. A passage selected is annotated from its menu,
/// or from the row's button, which annotates the page when nothing is.
final class PdfDocumentView extends StatefulWidget {
  /// Shows the PDF at [path].
  const new({
    required this.path,
    required this.launcher,
    this.linkType = LinkType.wikilink,
    this.positions,
    this.anchor,
    this.reloadToken = 0,
    this.onAnnotate,
    this.marks,
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

  /// Annotates a passage or a page of the PDF in its companion note
  /// (#284); null offers no annotating.
  final void Function(Annotation annotation)? onAnnotate;

  /// Where the library's files were annotated (#285): the passages and
  /// pages a companion note points at are marked, and a tap opens the
  /// note. Null marks nothing.
  final AnnotationMarkSource? marks;

  @override
  State<PdfDocumentView> createState() => PdfDocumentViewState();
}
