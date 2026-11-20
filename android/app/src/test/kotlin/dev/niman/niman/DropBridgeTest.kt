package dev.niman.niman

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * What a drag is taken for (#1250, #1293): a file or a picture is taken,
 * text is not — and a web page's file, which is `text/html` like the
 * selection dragged out of a browser, is told from it by the plain text
 * the selection carries beside its HTML.
 */
class DropBridgeTest {
    @Test
    fun aFileOrAPictureIsTaken() {
        assertTrue(DropBridge.carriesFiles(listOf("application/pdf")))
        assertTrue(DropBridge.carriesFiles(listOf("image/png", "text/plain")))
    }

    @Test
    fun textAloneIsNotTaken() {
        assertFalse(DropBridge.carriesFiles(listOf("text/plain")))
        assertFalse(DropBridge.carriesFiles(listOf("text/plain", "text/html")))
        assertFalse(DropBridge.carriesFiles(emptyList()))
    }

    @Test
    fun aWebPagesFileIsTakenButTheSelectionOfOneIsNot() {
        assertTrue(DropBridge.carriesFiles(listOf("text/html")))
        assertFalse(DropBridge.carriesFiles(listOf("text/html", "text/plain")))
    }
}
