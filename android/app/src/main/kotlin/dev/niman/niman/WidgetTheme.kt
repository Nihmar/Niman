package dev.niman.niman

import android.graphics.Color
import android.net.Uri
import org.json.JSONObject

/**
 * The app theme a widget payload wears (issue 6).
 *
 * Dart serializes the resolved colors under the payload's `theme`
 * object; the providers apply them with `RemoteViews` setters so the
 * widget follows the app's brightness choice and palette instead of
 * the system night mode. Payloads without a theme (pushed before
 * this) render the layout defaults. The theme also round-trips
 * through the tap URIs ([appendParams]), so a background toggle
 * re-pushes the same theme instead of flashing the defaults.
 */
data class WidgetTheme(
    val dark: Boolean,
    val background: Int,
    val primary: Int,
    val secondary: Int,
    val accent: Int,
    /** The error color the payload's theme carried, or null when it had none. */
    val errorColor: Int? = null,
) {
    /**
     * The error tone (Overdue, #1003): the palette's own error color when
     * the payload carries one (#1008), else the Material error pair for
     * the app's brightness (a payload pushed before the key existed).
     */
    val error: Int
        get() = errorColor ?: if (dark) ERROR_DARK else ERROR_LIGHT

    companion object {
        private const val ERROR_LIGHT = 0xFFB3261E.toInt()
        private const val ERROR_DARK = 0xFFF2B8B5.toInt()

        /**
         * The payload's theme, or null when it carries none (or a broken
         * one). [parseColor] reads a `#AARRGGBB` string; the platform's is
         * a stub on the host, so tests hand in their own.
         */
        fun fromPayload(
            payload: String?,
            parseColor: (String) -> Int = Color::parseColor,
        ): WidgetTheme? {
            val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
            return parsed?.optJSONObject("theme")?.let { fromJson(it, parseColor) }
        }

        private fun fromJson(theme: JSONObject, parseColor: (String) -> Int): WidgetTheme? {
            return try {
                WidgetTheme(
                    dark = theme.optBoolean("dark", false),
                    background = parseColor(theme.getString("background")),
                    primary = parseColor(theme.getString("primary")),
                    secondary = parseColor(theme.getString("secondary")),
                    accent = parseColor(theme.getString("accent")),
                    // Optional: a broken error color leaves the fallback,
                    // it does not drop the rest of the theme.
                    errorColor = theme.optString("error", "")
                        .takeIf { it.isNotEmpty() }
                        ?.let { runCatching { parseColor(it) }.getOrNull() },
                )
            } catch (e: Exception) {
                null
            }
        }

        /**
         * Appends the theme as tap-URI params (the `td/bg/fg/fs/ac` keys,
         * and `er` when the theme has an error color, that Dart parses
         * back); a null theme appends nothing.
         */
        fun appendParams(builder: Uri.Builder, theme: WidgetTheme?) {
            if (theme == null) return
            builder.appendQueryParameter("td", if (theme.dark) "1" else "0")
            builder.appendQueryParameter("bg", hex(theme.background))
            builder.appendQueryParameter("fg", hex(theme.primary))
            builder.appendQueryParameter("fs", hex(theme.secondary))
            builder.appendQueryParameter("ac", hex(theme.accent))
            theme.errorColor?.let { builder.appendQueryParameter("er", hex(it)) }
        }

        private fun hex(color: Int): String = "#%08X".format(color)
    }
}
