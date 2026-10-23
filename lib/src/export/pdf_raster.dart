/// Drawing a note as rastered PDF pages (#63): the fallback for a machine
/// with no browser engine to print the HTML with.
///
/// The note is laid out offscreen — the export seam's own view, at the
/// page's content width — and every page is a slice of that one layout,
/// captured at 2× and written into a PDF by [writePdf]. Everything here
/// paints, so it runs on the UI isolate: there is no second engine to hand
/// the picture to, and a note-sized job is the price of a machine without a
/// browser.
///
/// A page is a slice of the one layout, and where the slices end is not
/// the page's nominal edge: the break is moved up to the last offset that
/// falls between two lines of text ([rasterBreaks]), so a page never cuts
/// one in half. A picture taller than a page has nowhere to break and is
/// cut. A machine with an engine prints the page's HTML instead, where the
/// print CSS keeps blocks whole. A kanban board is drawn by
/// `pdf_raster_board.dart` instead, which pages it card by card.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:niman/src/export/kanban_sheet.dart';
import 'package:niman/src/export/pdf_breaks.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_raster_board.dart';
import 'package:niman/src/export/pdf_raster_support.dart';
import 'package:niman/src/export/pdf_writer.dart';
import 'package:niman/src/export/slide_page.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

export 'package:niman/src/export/pdf_raster_support.dart' show pointsPerPixel;

/// A4's width in the logical pixels a page is laid out in (96 per inch).
const double a4WidthPx = a4Width / pointsPerPixel;

/// A4's height in logical pixels.
const double a4HeightPx = a4Height / pointsPerPixel;

/// The page margin the print CSS uses, in logical pixels (18 mm).
const double pdfPageMarginPx = 18 * 96 / 25.4;

/// Lays [text] out and draws its pages, answering the PDF's bytes.
///
/// [images] are the note's pictures, by the target as written, decoded here
/// and drawn in place: the fallback has no browser to print an HTML page
/// with, so a picture it is not handed is a picture the note loses (#63,
/// H3).
///
/// [onProgress] reports how many of the note's pages have been drawn, and
/// [isCancelled] is asked between pages: a cancel stops before the next
/// page and throws [PdfExportCancelled].
///
/// [board], the kanban board the note is (#1170), is drawn as a board on
/// the sheet its columns fit, A4 landscape or portrait, instead of the
/// note's Markdown: see [rasterBoardPdf].
Future<Uint8List> rasterPdf({
  required String text,
  required MarkdownTheme theme,
  required MathCache mathCache,
  Map<String, Uint8List>? images,
  void Function(int done, int total)? onProgress,
  bool Function()? isCancelled,
  double pageWidth = a4WidthPx,
  double pageHeight = a4HeightPx,
  double margin = pdfPageMarginPx,
  double pixelRatio = 2,
  KanbanBoard? board,
}) async {
  if (board != null && board.columns.isNotEmpty) {
    final sheet = kanbanSheetFor(board.columns.length);
    final landscape = sheet == KanbanSheet.landscape;
    return await rasterBoardPdf(
      board: board,
      sheet: sheet,
      theme: theme,
      mathCache: mathCache,
      // A4 on its side: the sheet's short side is the page's height.
      pageWidth: landscape ? math.max(pageWidth, pageHeight) : pageWidth,
      pageHeight: landscape ? math.min(pageWidth, pageHeight) : pageHeight,
      margin: margin,
      images: images,
      onProgress: onProgress,
      isCancelled: isCancelled,
      pixelRatio: pixelRatio,
    );
  }
  final contentWidth = pageWidth - 2 * margin;
  final contentHeight = pageHeight - 2 * margin;
  // Decoded before the tree is built: the offscreen layout has no frame
  // loop, so an [EmbedView] that resolved and decoded on its own could not
  // be waited for.
  final decoded = <String, ui.Image>{};
  final maxPicture = math.max(1, (contentWidth * pixelRatio).round());
  for (final entry in (images ?? const <String, Uint8List>{}).entries) {
    try {
      decoded[entry.key] = await decodePicture(entry.value, maxPicture);
    } on Object {
      // A picture the engine cannot decode is left as the note's own
      // words, not made the export's failure.
    }
  }
  final key = GlobalKey();
  final layout = OffscreenLayout(
    width: contentWidth,
    height: pageHeight,
    child: KeyedSubtree(
      key: key,
      child: MarkdownExportView(
        buffer: SourceBuffer.fromText(text),
        parser: ReadParser(),
        theme: theme,
        mathCache: mathCache,
        width: contentWidth,
        padding: EdgeInsets.zero,
        embedImages: decoded.isEmpty ? null : decoded,
      ),
    ),
  );
  try {
    final box = layout.layOut();
    // Where each page ends: the page's own edge pulled up to a gap between
    // two lines of text, so a slice never cuts one in half (#63).
    final breaks = rasterBreaks(
      total: box.size.height,
      spans: rasterInkSpans(box),
      contentHeight: contentHeight,
    );
    final count = breaks.length - 1;
    onProgress?.call(0, count);
    // The note is recorded once and sliced per page: a capture per page
    // would re-record the whole note for every page, which is quadratic in
    // the note's length (M6).
    final recording = MarkdownExport.record(box);
    final writer = PdfWriter(
      pageWidth: pageWidth * pointsPerPixel,
      pageHeight: pageHeight * pointsPerPixel,
      margin: margin * pointsPerPixel,
    );
    try {
      for (var page = 0; page < count; page++) {
        if (isCancelled?.call() ?? false) throw const PdfExportCancelled();
        final top = breaks[page];
        final height = breaks[page + 1] - top;
        final image = await recording.capture(
          Rect.fromLTWH(0, top, contentWidth, height),
          pixelRatio: pixelRatio,
        );
        try {
          // Compressed into the file here: the fallback holds one page's
          // pixels at a time, not every page of the note (M6).
          writer.addPage(await pageImage(image));
        } finally {
          image.dispose();
        }
        onProgress?.call(page + 1, count);
      }
    } finally {
      recording.dispose();
    }
    return writer.finish();
  } finally {
    layout.dispose();
    for (final image in decoded.values) {
      image.dispose();
    }
  }
}

/// Draws one page per slide of [slides] (#534), each the slide's Markdown
/// laid out on a [slideSize] page and clipped to it, answering the PDF's
/// bytes. The fallback of a machine with no engine, as [rasterPdf] is for
/// a note; [theme] carries the slides' larger type.
Future<Uint8List> rasterSlidesPdf({
  required List<String> slides,
  required MarkdownTheme theme,
  required MathCache mathCache,
  Map<String, Uint8List>? images,
  void Function(int done, int total)? onProgress,
  bool Function()? isCancelled,
  double pixelRatio = 2,
}) async {
  final width = slideSize.width;
  final height = slideSize.height;
  final decoded = <String, ui.Image>{};
  for (final entry in (images ?? const <String, Uint8List>{}).entries) {
    try {
      decoded[entry.key] = await decodePicture(
        entry.value,
        (width * pixelRatio).round(),
      );
    } on Object {
      // As in [rasterPdf]: a picture that will not decode stays words.
    }
  }
  final writer = PdfWriter(
    pageWidth: width * pointsPerPixel,
    pageHeight: height * pointsPerPixel,
  );
  try {
    onProgress?.call(0, slides.length);
    for (var index = 0; index < slides.length; index++) {
      if (isCancelled?.call() ?? false) throw const PdfExportCancelled();
      final layout = OffscreenLayout(
        width: width,
        height: height,
        child: MarkdownExportView(
          buffer: SourceBuffer.fromText(slides[index]),
          parser: ReadParser(),
          theme: theme,
          mathCache: mathCache,
          width: width,
          padding: slidePadding,
          embedImages: decoded.isEmpty ? null : decoded,
        ),
      );
      try {
        final recording = MarkdownExport.record(layout.layOut());
        try {
          final image = await recording.capture(
            Rect.fromLTWH(0, 0, width, height),
            pixelRatio: pixelRatio,
          );
          try {
            writer.addPage(await pageImage(image));
          } finally {
            image.dispose();
          }
        } finally {
          recording.dispose();
        }
      } finally {
        layout.dispose();
      }
      onProgress?.call(index + 1, slides.length);
    }
    return writer.finish();
  } finally {
    for (final image in decoded.values) {
      image.dispose();
    }
  }
}
