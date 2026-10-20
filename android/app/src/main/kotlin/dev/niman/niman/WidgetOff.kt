package dev.niman.niman

import org.json.JSONObject

/**
 * What a widget whose feature is off shows (#1109, Phone-4).
 *
 * Dart sends one payload for it, `{"library", "off": {"feature", "text",
 * "action"}, "theme"}`, and writes nothing else for the widget (see
 * `lib/src/widget/widget_off.dart`). The sentence and the button's label
 * are in the payload, written in the app's language, because the launcher
 * renders with no Dart engine and the app speaks more languages than the
 * resources do. The three providers recognise the payload by its `off`
 * object and draw [WidgetOffViews] instead of their rows.
 */
data class WidgetOff(
    /** The id of the feature that is off (`todo`, `kinds.flashcards`, `widgets`). */
    val feature: String,
    /** The sentence: "Todo is off in this library". */
    val text: String,
    /** The label of the button that opens Settings → Features. */
    val action: String,
) {
    companion object {
        /**
         * The off state [payload] carries, or null when it carries none —
         * a payload of data, or one that does not parse.
         */
        fun fromPayload(payload: String?): WidgetOff? {
            val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
            return fromJson(parsed)
        }

        /** The library's folder name, or [fallback] when the payload names none. */
        fun titleFor(library: String, fallback: String): String {
            if (library.isEmpty()) return fallback
            val base = library.trimEnd('/').substringAfterLast('/').substringAfterLast('\\')
            return base.ifEmpty { fallback }
        }

        /** The off state of an already parsed payload, or null. */
        fun fromJson(payload: JSONObject?): WidgetOff? {
            val off = payload?.optJSONObject("off") ?: return null
            return WidgetOff(
                feature = off.optString("feature", ""),
                text = off.optString("text", ""),
                action = off.optString("action", ""),
            )
        }
    }
}
