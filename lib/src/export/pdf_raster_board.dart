/// Drawing a kanban board as rastered PDF pages (#1170): the fallback of a
/// machine with no browser engine to print the board's HTML with.
///
/// The board is a Flutter widget tree, not the Markdown read view: columns
/// of cards laid out like the printed page — one row sharing the width on a
/// landscape sheet, a few to a row on a portrait one. A row of columns
/// cannot be sliced like a note's one tall layout (no cut is clear of every
/// column's cards), so the board is laid out twice: once to measure every
/// card, then page by page, each page holding the cards the plan
/// ([planBoardPages]) put on it. A card is never cut across two pages.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:niman/src/export/board_raster_content.dart';
import 'package:niman/src/export/board_raster_context.dart';
import 'package:niman/src/export/board_raster_head.dart';
import 'package:niman/src/export/board_raster_plan.dart';
import 'package:niman/src/export/kanban_sheet.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_raster_support.dart';
import 'package:niman/src/export/pdf_writer.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';

/// Lays [board] out on [sheet] pages of [pageWidth] by [pageHeight] logical
/// pixels, [margin] in, and draws them, answering the PDF's bytes.
///
/// [images] are the note's pictures, decoded here as the note's own
/// fallback decodes them; [onProgress] and [isCancelled] are as in
/// `rasterPdf`.
Future<Uint8List> rasterBoardPdf({
  required KanbanBoard board,
  required KanbanSheet sheet,
  required MarkdownTheme theme,
  required MathCache mathCache,
  required double pageWidth,
  required double pageHeight,
  required double margin,
  Map<String, Uint8List>? images,
  void Function(int done, int total)? onProgress,
  bool Function()? isCancelled,
  double pixelRatio = 2,
}) async {
  final contentWidth = pageWidth - 2 * margin;
  final contentHeight = pageHeight - 2 * margin;
  final decoded = <String, ui.Image>{};
  final maxPicture = math.max(1, (contentWidth * pixelRatio).round());
  for (final entry in (images ?? const <String, Uint8List>{}).entries) {
    try {
      decoded[entry.key] = await decodePicture(entry.value, maxPicture);
    } on Object {
      // As in `rasterPdf`: a picture that will not decode stays words.
    }
  }
  try {
    final content = BoardRasterContent(
      board: board,
      sheet: sheet,
      contentWidth: contentWidth,
      context: BoardRasterContext(
        board: board,
        theme: theme,
        mathCache: mathCache,
        images: decoded.isEmpty ? null : decoded,
      ),
    );
    final pages = planBoardPages(
      bands: measureBoardContent(content, contentWidth, pageHeight),
      pageHeight: contentHeight,
      bandGap: content.gap,
    );
    onProgress?.call(0, pages.length);
    final writer = PdfWriter(
      pageWidth: pageWidth * pointsPerPixel,
      pageHeight: pageHeight * pointsPerPixel,
      margin: margin * pointsPerPixel,
    );
    for (var index = 0; index < pages.length; index++) {
      if (isCancelled?.call() ?? false) throw const PdfExportCancelled();
      final layout = OffscreenLayout(
        width: contentWidth,
        height: pageHeight,
        child: _page(content, pages[index], contentWidth, contentHeight),
      );
      try {
        final recording = MarkdownExport.record(layout.layOut());
        try {
          final image = await recording.capture(
            Rect.fromLTWH(0, 0, contentWidth, contentHeight),
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
      onProgress?.call(index + 1, pages.length);
    }
    return writer.finish();
  } finally {
    for (final image in decoded.values) {
      image.dispose();
    }
  }
}

/// Every head and every item of [content] laid out once on a page
/// [contentWidth] wide, and their heights: what the plan pages by.
///
/// They are laid out as the children of one column, in the order the plan
/// reads them back: each lane's head, then its items.
List<List<BoardLaneMeasure>> measureBoardContent(
  BoardRasterContent content,
  double contentWidth,
  double pageHeight,
) {
  final children = <Widget>[
    for (final band in content.bands)
      for (final lane in band) ...[?lane.head, ...lane.items],
  ];
  final layout = OffscreenLayout(
    width: contentWidth,
    height: pageHeight,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    ),
  );
  try {
    final heights = <double>[];
    layout.layOut().visitChildren((child) {
      heights.add((child as RenderBox).size.height);
    });
    var at = 0;
    return [
      for (final band in content.bands)
        [
          for (final lane in band)
            () {
              final head = lane.head == null ? 0.0 : heights[at++];
              final items = heights.sublist(at, at += lane.items.length);
              return BoardLaneMeasure(
                head: head,
                items: items,
                chrome: lane.framed ? boardLaneChrome : 0,
              );
            }(),
        ],
    ];
  } finally {
    layout.dispose();
  }
}

/// One page: the band slices [slices] stacked, each a row of its lanes'
/// slices, on a [width] by [height] sheet.
Widget _page(
  BoardRasterContent content,
  List<BoardBandSlice> slices,
  double width,
  double height,
) {
  final rows = <Widget>[];
  for (final slice in slices) {
    final lanes = content.bands[slice.band];
    if (rows.isNotEmpty) rows.add(SizedBox(height: content.gap));
    rows.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final part in slice.lanes) ...[
            if (part.lane > 0) SizedBox(width: content.gap),
            if (part.visible)
              lanes[part.lane].slice(part.from, part.to, withHead: part.head)
            else
              SizedBox(width: lanes[part.lane].width),
          ],
        ],
      ),
    );
  }
  return SizedBox(
    width: width,
    height: height,
    child: ClipRect(
      // The page is a window on its rows: a card taller than it is cut, not
      // reported as an overflow.
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    ),
  );
}
