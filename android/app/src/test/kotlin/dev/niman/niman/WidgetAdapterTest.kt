package dev.niman.niman

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

/**
 * The adapter intent of a widget, unique per instance (#969).
 *
 * `RemoteViewsService` caches one factory per `Intent.filterEquals`
 * intent, and the data URI is the part of the intent that tells two
 * instances apart: extras are not compared. The unit tests run against
 * the stubbed Android jar, where `Uri` and `Intent` do nothing, so the
 * URI the helper puts on the intent is tested as the string it is built
 * from.
 */
class WidgetAdapterTest {
    @Test
    fun `two widgets of one kind get different URIs`() {
        assertNotEquals(
            WidgetAdapter.uriString(WidgetAdapter.STUDY, 41),
            WidgetAdapter.uriString(WidgetAdapter.STUDY, 42),
        )
        assertNotEquals(
            WidgetAdapter.uriString(WidgetAdapter.TODO, 7),
            WidgetAdapter.uriString(WidgetAdapter.TODO, 8),
        )
        assertNotEquals(
            WidgetAdapter.uriString(WidgetAdapter.NOTE, 1),
            WidgetAdapter.uriString(WidgetAdapter.NOTE, 2),
        )
    }

    @Test
    fun `the same id of two kinds gets different URIs`() {
        val uris = listOf(WidgetAdapter.STUDY, WidgetAdapter.TODO, WidgetAdapter.NOTE)
            .map { WidgetAdapter.uriString(it, 5) }
        assertEquals(uris.size, uris.toSet().size)
    }

    @Test
    fun `a widget gets the same URI every time it is bound`() {
        // The framework rebinds on every update: a URI that changed would
        // build a new factory each time.
        assertEquals("niman-widget://study/9", WidgetAdapter.uriString(WidgetAdapter.STUDY, 9))
        assertEquals(
            WidgetAdapter.uriString(WidgetAdapter.STUDY, 9),
            WidgetAdapter.uriString(WidgetAdapter.STUDY, 9),
        )
    }
}
