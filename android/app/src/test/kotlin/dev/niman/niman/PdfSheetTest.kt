package dev.niman.niman

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The sheet the `niman/pdf` channel's `paper` names (#1170): the Dart side
 * sends `PdfPaper.name`, and a name this side cannot read must still print.
 */
class PdfSheetTest {
    @Test
    fun everyPaperTheDartSideSendsIsRead() {
        assertEquals(PdfSheet.A4, PdfSheet.forName("a4"))
        assertEquals(PdfSheet.A4_LANDSCAPE, PdfSheet.forName("a4Landscape"))
        assertEquals(PdfSheet.SLIDES, PdfSheet.forName("slides"))
    }

    @Test
    fun noNameOrAnUnknownOneIsAPortraitA4() {
        assertEquals(PdfSheet.A4, PdfSheet.forName(null))
        assertEquals(PdfSheet.A4, PdfSheet.forName("a3"))
    }

    @Test
    fun aBoardSheetLiesOnItsSideWithTheNotesMargin() {
        assertTrue(PdfSheet.A4_LANDSCAPE.landscape)
        assertEquals(PdfSheet.A4.marginMils, PdfSheet.A4_LANDSCAPE.marginMils)
        assertEquals(709, PdfSheet.A4_LANDSCAPE.marginMils)
    }

    @Test
    fun theNotesSheetStaysPortraitAndASlideHasNoMargin() {
        assertFalse(PdfSheet.A4.landscape)
        assertEquals(0, PdfSheet.SLIDES.marginMils)
    }

    @Test
    fun everyKeyIsOneOfAKind() {
        val keys = PdfSheet.entries.map { it.key }
        assertEquals(keys.size, keys.toSet().size)
    }
}
