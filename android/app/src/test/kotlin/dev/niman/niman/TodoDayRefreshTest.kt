package dev.niman.niman

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * The day-change refresh target of a todo widget (#1018): the
 * `niman://todo-refresh` URI built from the payload the widget shows.
 */
class TodoDayRefreshTest {
    private fun payload(
        library: String? = "/storage/Work notes",
        language: String? = "it",
        theme: JSONObject? = null,
    ): String = JSONObject()
        .also { if (library != null) it.put("library", library) }
        .also { if (language != null) it.put("language", language) }
        .also { if (theme != null) it.put("theme", theme) }
        .put("rows", org.json.JSONArray())
        .toString()

    private fun theme(error: String?) = JSONObject()
        .put("dark", true)
        .put("background", "#E61A1C1E")
        .put("primary", "#FFE2E2E5")
        .put("secondary", "#FFC3C6CF")
        .put("accent", "#FFD0BCFF")
        .also { if (error != null) it.put("error", error) }

    @Test
    fun `the target names the widget, its library and its language`() {
        val uri = TodoDayRefresh.uriString(7, payload())!!
        assertTrue(uri.startsWith("niman://todo-refresh?"))
        assertTrue(uri.contains("id=7"))
        // Encoded: a library path with a space survives a query string.
        assertTrue(uri.contains("library=%2Fstorage%2FWork+notes"))
        assertTrue(uri.contains("lg=it"))
    }

    @Test
    fun `the theme rides under the keys a row tap uses`() {
        val uri = TodoDayRefresh.uriString(7, payload(theme = theme("#FFB3261E")))!!
        assertTrue(uri.contains("td=1"))
        assertTrue(uri.contains("bg=%23E61A1C1E"))
        assertTrue(uri.contains("fg=%23FFE2E2E5"))
        assertTrue(uri.contains("fs=%23FFC3C6CF"))
        assertTrue(uri.contains("ac=%23FFD0BCFF"))
        assertTrue(uri.contains("er=%23FFB3261E"))
    }

    @Test
    fun `a theme without an error color carries no er key`() {
        val uri = TodoDayRefresh.uriString(7, payload(theme = theme(null)))!!
        assertTrue(uri.contains("td=1"))
        assertTrue(!uri.contains("er="))
    }

    @Test
    fun `a payload without a language or theme carries neither`() {
        val uri = TodoDayRefresh.uriString(3, payload(language = null))!!
        assertEquals("niman://todo-refresh?id=3&library=%2Fstorage%2FWork+notes", uri)
    }

    @Test
    fun `a widget with nothing to re-read gets no target`() {
        assertNull(TodoDayRefresh.uriString(7, null))
        assertNull(TodoDayRefresh.uriString(7, "not json"))
        assertNull(TodoDayRefresh.uriString(7, payload(library = null)))
        assertNull(TodoDayRefresh.uriString(7, payload(library = "")))
    }

    @Test
    fun `the payload key is the one Dart pushes under`() {
        assertEquals("todo_42", TodoDayRefresh.payloadKey(42))
    }
}
