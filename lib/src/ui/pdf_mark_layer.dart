/// The marks drawn over a PDF's pages where it was annotated (#285): a
/// passage tinted as a highlighter marks it, a page annotated as a whole
/// pinned at its corner. A tap opens the annotation.
///
/// A passage is where its link says, `chars=120-180` of the page's text:
/// its rectangles come from that text, read once per marked page when the
/// marks change. A passage whose page no longer has those characters, and
/// a mark on a page annotated whole, are pinned instead.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:pdfrx/pdfrx.dart';

/// The rectangles of characters [start]..[end] of [text], one per run of
/// text they cover: a passage over three lines is three.
List<PdfRect> passageRects(PdfPageText text, int start, int end) {
  final last = math.min(end, text.charRects.length);
  return [
    for (final fragment in text.fragments)
      if (math.max(start, fragment.index) < math.min(last, fragment.end))
        text.charRects.boundingRect(
          start: math.max(start, fragment.index),
          end: math.min(last, fragment.end),
        ),
  ];
}

/// The marks over the pages of one PDF.
final class PdfMarkLayer {
  /// Each passage mark's rectangles, in its page's coordinates.
  final Map<AnnotationMark, List<PdfRect>> _rects = {};

  /// Reads where [marks]' passages are in [document]; the pages' text is
  /// read once each.
  Future<void> load(PdfDocument document, List<AnnotationMark> marks) async {
    final rects = <AnnotationMark, List<PdfRect>>{};
    final texts = <int, PdfPageText>{};
    for (final mark in marks) {
      if (mark.place case PdfLocation(:final page, chars: final chars?)
          when page <= document.pages.length) {
        final text = texts[page] ??= await document.pages[page - 1]
            .loadStructuredText();
        final found = passageRects(text, chars.start, chars.end);
        if (found.isNotEmpty) rects[mark] = found;
      }
    }
    _rects
      ..clear()
      ..addAll(rects);
  }

  /// The marks over [page], drawn at [pageRect]'s scale; [onTap] opens
  /// the marks tapped.
  List<Widget> overlays(
    BuildContext context,
    Rect pageRect,
    PdfPage page,
    List<AnnotationMark> marks, {
    required void Function(List<AnnotationMark> marks) onTap,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pinned = <AnnotationMark>[];
    final out = <Widget>[];
    for (final mark in marks) {
      if (mark.place case PdfLocation(page: final number)
          when number == page.pageNumber) {
        final rects = _rects[mark];
        if (rects == null) {
          pinned.add(mark);
          continue;
        }
        for (final rect in rects) {
          out.add(
            Positioned.fromRect(
              rect: rect.toRect(page: page, scaledPageSize: pageRect.size),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap([mark]),
                child: ColoredBox(color: markHighlightFor(dark: dark)),
              ),
            ),
          );
        }
      }
    }
    if (pinned.isNotEmpty) {
      out.add(
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filledTonal(
            key: Key('pdf-page-mark-${page.pageNumber}'),
            icon: const Icon(Icons.sticky_note_2_outlined),
            onPressed: () => onTap(pinned),
          ),
        ),
      );
    }
    return out;
  }
}
