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
) {
    companion object {
        /** The payload's theme, or null when it carries none (or a broken one). */
        fun fromPayload(payload: String?): WidgetTheme? {
            val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
            return parsed?.optJSONObject("theme")?.let { fromJson(it) }
        }

        private fun fromJson(theme: JSONObject): WidgetTheme? {
            return try {
                WidgetTheme(
                    dark = theme.optBoolean("dark", false),
                    background = Color.parseColor(theme.getString("background")),
                    primary = Color.parseColor(theme.getString("primary")),
                    secondary = Color.parseColor(theme.getString("secondary")),
                    accent = Color.parseColor(theme.getString("accent")),
                )
            } catch (e: Exception) {
                null
            }
        }

        /**
         * Appends the theme as tap-URI params (the `td/bg/fg/fs/ac` keys
         * Dart parses back); a null theme appends nothing.
         */
        fun appendParams(builder: Uri.Builder, theme: WidgetTheme?) {
            if (theme == null) return
            builder.appendQueryParameter("td", if (theme.dark) "1" else "0")
            builder.appendQueryParameter("bg", hex(theme.background))
            builder.appendQueryParameter("fg", hex(theme.primary))
            builder.appendQueryParameter("fs", hex(theme.secondary))
            builder.appendQueryParameter("ac", hex(theme.accent))
        }

        private fun hex(color: Int): String = "#%08X".format(color)
    }
}
