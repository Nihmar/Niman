package dev.niman.niman

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * The off state of a widget (#1109, Phone-4): Dart sends one payload for a
 * widget whose feature is off, and the providers tell it from a payload of
 * data by its `off` object.
 */
class WidgetOffTest {
    private fun off(feature: String, text: String, action: String) =
        JSONObject()
            .put("library", "/storage/Notes")
            .put(
                "off",
                JSONObject()
                    .put("feature", feature)
                    .put("text", text)
                    .put("action", action),
            )

    @Test
    fun `an off payload carries the sentence and the button`() {
        val payload = off("todo", "Todo is off in this library", "Open Features")
        val parsed = WidgetOff.fromPayload(payload.toString())
        assertNotNull(parsed)
        assertEquals("todo", parsed!!.feature)
        assertEquals("Todo is off in this library", parsed.text)
        assertEquals("Open Features", parsed.action)
    }

    @Test
    fun `the words are the payload's, in whatever language Dart wrote them`() {
        val payload = off("kinds.flashcards", "Lo studio è disattivato", "Apri Funzioni")
        val parsed = WidgetOff.fromJson(payload)
        assertEquals("Lo studio è disattivato", parsed!!.text)
        assertEquals("Apri Funzioni", parsed.action)
    }

    @Test
    fun `a payload of data is not an off payload`() {
        val data = JSONObject()
            .put("library", "/storage/Notes")
            .put("total", 3)
            .put("rows", org.json.JSONArray())
        assertNull(WidgetOff.fromJson(data))
        assertNull(WidgetOff.fromPayload(data.toString()))
    }

    @Test
    fun `nothing, or something that does not parse, is not an off payload`() {
        assertNull(WidgetOff.fromPayload(null))
        assertNull(WidgetOff.fromPayload("not json"))
        assertNull(WidgetOff.fromJson(null))
    }

    @Test
    fun `the header names the library, or the provider when it names none`() {
        assertEquals("Notes", WidgetOff.titleFor("/storage/emulated/0/Notes/", "Todos"))
        assertEquals("Notes", WidgetOff.titleFor("C:\\Users\\me\\Notes", "Todos"))
        assertEquals("Todos", WidgetOff.titleFor("", "Todos"))
    }
}
