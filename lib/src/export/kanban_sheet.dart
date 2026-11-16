/// The sheet a kanban board is printed on (#1170): the one rule, in one
/// place, for every engine and for the raster writer.
///
/// A board prints on the paper on its side when its columns fit one row
/// there, each at least [kanbanColumnMinMm] wide, and standing up,
/// wrapping as many to a row as fit at that width ([kanbanColumnsPerRow]),
/// when they do not. The paper is the export's own (#1285), A4 unless
/// another is picked. The choice is made for the whole document: a PDF
/// holds one note, and a folder export prints each note into a PDF of its
/// own, so no document mixes orientations.
library;

import 'dart:math' as math;

import 'package:niman/src/export/paper_size.dart';
import 'package:niman/src/export/pdf_printer.dart';

/// The narrowest a column may be on a landscape sheet, in millimetres.
const double kanbanColumnMinMm = 60;

/// The gap between two columns, in millimetres.
const double kanbanGapMm = 6;

/// The page margin, in millimetres: the one `html_page.dart` prints with.
const double kanbanMarginMm = 18;

/// The way a board's sheet lies.
enum KanbanSheet {
  /// On its side: every column in one row.
  landscape,

  /// Standing up: a grid of [kanbanColumnsPerRow] columns to a row.
  portrait;

  /// The usable width of [paper] lying this way, margins off, in
  /// millimetres.
  double usableMm([PaperSize paper = PaperSize.a4]) =>
      (this == landscape ? paper.heightMm : paper.widthMm) - 2 * kanbanMarginMm;

  /// The paper a printer is asked for to print this sheet of [paper].
  PdfPaper paperOf([PaperSize paper = PaperSize.a4]) =>
      PdfPaper(paper, landscape: this == landscape);
}

/// The most columns one row of [sheet] of [paper] holds at
/// [kanbanColumnMinMm] each, gaps counted; one at least, however narrow.
int kanbanColumnsPerRow(KanbanSheet sheet, [PaperSize paper = PaperSize.a4]) =>
    math.max(
      1,
      ((sheet.usableMm(paper) + kanbanGapMm) /
              (kanbanColumnMinMm + kanbanGapMm))
          .floor(),
    );

/// The sheet a board of [columns] columns is printed on, of [paper]:
/// landscape when they fit one row of it, portrait when they do not.
///
/// A board with no column (or one) is landscape: nothing to wrap. The
/// export never asks for a board without columns, which is drawn as prose.
KanbanSheet kanbanSheetFor(int columns, [PaperSize paper = PaperSize.a4]) =>
    columns <= kanbanColumnsPerRow(KanbanSheet.landscape, paper)
    ? KanbanSheet.landscape
    : KanbanSheet.portrait;

/// The paper a page whose board prints on [sheet] is printed on: a note
/// with no board ([sheet] null) is [paper] standing up, as it always was.
PdfPaper kanbanPaper(KanbanSheet? sheet, [PaperSize paper = PaperSize.a4]) =>
    sheet?.paperOf(paper) ?? PdfPaper(paper);
