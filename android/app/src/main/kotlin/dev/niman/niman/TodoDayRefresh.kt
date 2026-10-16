package dev.niman.niman

import org.json.JSONObject
import java.net.URLEncoder

/**
 * The day-change refresh of a todo widget (#1018): what the receiver
 * hands the background Dart callback for one placed widget.
 *
 * The target is the `niman://todo-refresh` URI Dart parses
 * (`parseTodoRefreshUri`): the instance id, the library the payload
 * names, and the payload's language and theme so the re-push words and
 * paints the widget as it already is. The theme's colors travel as the
 * `#AARRGGBB` strings the payload already holds, under the same `td/bg/
 * fg/fs/ac/er` keys a row tap uses; Dart validates them. A widget with no
 * payload (never pushed) or no library has nothing to re-read and gets no
 * target. Plain JVM code: the URI is built as the string it is, so it is
 * tested without a device.
 */
object TodoDayRefresh {
    /** The URI host the Dart callback routes to the refresh. */
    const val HOST = "todo-refresh"

    /** Payload `theme` key to tap-URI key, in the order Dart writes them. */
    private val THEME_KEYS = listOf(
        "background" to "bg",
        "primary" to "fg",
        "secondary" to "fs",
        "accent" to "ac",
        "error" to "er",
    )

    /** The key of the widget [id]'s payload in the widget storage. */
    fun payloadKey(id: Int): String = "todo_$id"

    /**
     * The refresh URI of widget [id] from its [payload], or null when the
     * payload names no library.
     */
    fun uriString(id: Int, payload: String?): String? {
        val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return null
        val library = TodoWidgetItems.string(parsed, "library")
        if (library.isEmpty()) return null
        val params = mutableListOf("id" to id.toString(), "library" to library)
        val language = TodoWidgetItems.string(parsed, "language")
        if (language.isNotEmpty()) params += "lg" to language
        parsed.optJSONObject("theme")?.let { theme ->
            params += "td" to if (theme.optBoolean("dark", false)) "1" else "0"
            for ((key, param) in THEME_KEYS) {
                val value = TodoWidgetItems.string(theme, key)
                if (value.isNotEmpty()) params += param to value
            }
        }
        return "niman://$HOST?" + params.joinToString("&") { (key, value) ->
            "$key=${URLEncoder.encode(value, "UTF-8")}"
        }
    }
}
