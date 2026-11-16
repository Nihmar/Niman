package dev.niman.niman

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The sheet the `niman/pdf` channel's `paper`, `width` and `height` name
 * (#1170, #1285): the Dart side sends `PdfPaper.name` and the sheet's size
 * as it lies, and a name this side cannot read must still print.
 */
class PdfSheetTest {
    @Test
    fun aSheetIsReadAtTheSizeItIsSent() {
        // US Letter, 612 × 792 points: 8.5 × 11 inches.
        val letter = PdfSheet.of("portrait", 612.0, 792.0)
        assertEquals(8500, letter.widthMils)
        assertEquals(11000, letter.heightMils)
        assertFalse(letter.landscape)
        assertEquals(PDF_MARGIN_MILS, letter.marginMils)
        val board = PdfSheet.of("landscape", 1224.0, 792.0)
        assertTrue(board.landscape)
        assertEquals(11000, board.shortMils)
        assertEquals(17000, board.longMils)
    }

    @Test
    fun theNamesBeforeThePaperWasAChoiceAreA4() {
        assertEquals(PdfSheet.A4, PdfSheet.of("a4", null, null))
        assertEquals(PdfSheet.A4_LANDSCAPE, PdfSheet.of("a4Landscape", null, null))
        assertEquals(PdfSheet.SLIDES, PdfSheet.of("slides", 1.0, 1.0))
    }

    @Test
    fun noNameAnUnknownOneOrNoSizeIsA4() {
        assertEquals(PdfSheet.A4, PdfSheet.of(null, null, null))
        assertEquals(PdfSheet.A4, PdfSheet.of("a3", 842.0, 1191.0))
        assertEquals(PdfSheet.A4, PdfSheet.of("portrait", null, 10.0))
        assertEquals(PdfSheet.A4_LANDSCAPE, PdfSheet.of("landscape", 0.0, 0.0))
    }

    @Test
    fun aSlideHasNoMarginAndANoteTheNotesMargin() {
        assertTrue(PdfSheet.SLIDES.slides)
        assertEquals(0, PdfSheet.SLIDES.marginMils)
        assertEquals(709, PdfSheet.A4_LANDSCAPE.marginMils)
        assertFalse(PdfSheet.A4.slides)
    }
}
