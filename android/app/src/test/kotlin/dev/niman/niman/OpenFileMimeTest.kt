package dev.niman.niman

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * The type a file is offered to other apps as (#1109): what lets the
 * system's PDF viewer or book reader pick itself out of the list.
 */
class OpenFileMimeTest {
    @Test
    fun aPdfAndABookSayWhatTheyAre() {
        assertEquals("application/pdf", OpenFileMime.forName("Paper.pdf"))
        assertEquals("application/epub+zip", OpenFileMime.forName("Novel.epub"))
    }

    @Test
    fun theExtensionIsReadInAnyCase() {
        assertEquals("application/pdf", OpenFileMime.forName("SCAN.PDF"))
        assertEquals("application/epub+zip", OpenFileMime.forName("Book.EpUb"))
    }

    @Test
    fun onlyTheLastExtensionCounts() {
        assertEquals("application/pdf", OpenFileMime.forName("a.epub.pdf"))
        assertEquals(OpenFileMime.ANY, OpenFileMime.forName("a.pdf.bak"))
    }

    @Test
    fun aFileWithoutAKnownExtensionIsOfferedAsAnything() {
        assertEquals(OpenFileMime.ANY, OpenFileMime.forName("README"))
        assertEquals(OpenFileMime.ANY, OpenFileMime.forName("trailing."))
        assertEquals(OpenFileMime.ANY, OpenFileMime.forName(".pdf"))
        assertEquals(OpenFileMime.ANY, OpenFileMime.forName("sheet.xyz"))
    }
}
