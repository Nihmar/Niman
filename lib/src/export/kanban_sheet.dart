/// The sheet a kanban board is printed on (#1170): the one rule, in one
/// place, for every engine and for the raster writer.
///
/// A board prints on A4 landscape when its columns fit one row there, each
/// at least [kanbanColumnMinMm] wide, and on A4 portrait, wrapping as many to
/// a row as fit at that width ([kanbanPortraitColumns]), when they do not.
/// The choice is made for the whole document: a PDF holds one note, and a
/// folder export prints each note into a PDF of its own, so no document
/// mixes orientations.
library;

import 'package:niman/src/export/pdf_printer.dart';

/// The narrowest a column may be on a landscape sheet, in millimetres.
const double kanbanColumnMinMm = 60;

/// The gap between two columns, in millimetres.
const double kanbanGapMm = 6;

/// The page margin, in millimetres: the one `html_page.dart` prints with.
const double kanbanMarginMm = 18;

/// A4's short side, in millimetres.
const double kanbanA4ShortMm = 210;

/// A4's long side, in millimetres.
const double kanbanA4LongMm = 297;

/// The sheet a board is printed on.
enum KanbanSheet {
  /// A4 landscape: every column in one row.
  landscape,

  /// A4 portrait: a grid of [kanbanPortraitColumns] columns to a row.
  portrait;

  /// The usable width of the sheet, margins off, in millimetres.
  double get usableMm =>
      (this == landscape ? kanbanA4LongMm : kanbanA4ShortMm) -
      2 * kanbanMarginMm;

  /// The paper a printer is asked for to print this sheet.
  PdfPaper get paper => this == landscape ? PdfPaper.a4Landscape : PdfPaper.a4;
}

/// The most columns one row of [sheet] holds at [kanbanColumnMinMm] each,
/// gaps counted.
int _columnsPerRow(KanbanSheet sheet) =>
    ((sheet.usableMm + kanbanGapMm) / (kanbanColumnMinMm + kanbanGapMm))
        .floor();

/// The most columns one landscape row holds: 4 with the numbers above.
final int kanbanLandscapeColumns = _columnsPerRow(KanbanSheet.landscape);

/// How many columns a row of the portrait grid holds: 2 with the numbers
/// above, so no column is narrower than [kanbanColumnMinMm] on any sheet.
final int kanbanPortraitColumns = _columnsPerRow(KanbanSheet.portrait);

/// The sheet a board of [columns] columns is printed on: landscape when
/// they fit one row of it, portrait when they do not.
///
/// A board with no column (or one) is landscape: nothing to wrap. The
/// export never asks for a board without columns, which is drawn as prose.
KanbanSheet kanbanSheetFor(int columns) => columns <= kanbanLandscapeColumns
    ? KanbanSheet.landscape
    : KanbanSheet.portrait;

/// The paper a page whose board prints on [sheet] is printed on: a note
/// with no board ([sheet] null) is A4 portrait, as it always was.
PdfPaper kanbanPaper(KanbanSheet? sheet) => sheet?.paper ?? PdfPaper.a4;
