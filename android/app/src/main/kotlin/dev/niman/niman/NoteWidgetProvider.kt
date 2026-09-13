package dev.niman.niman

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * The pinned-note home-screen widget (issue 6).
 *
 * Renders the payload Dart pushes under `note_<id>` (see
 * `lib/src/widget/widget_payload.dart`): the title plus the excerpt, or
 * the checklist rows for `type: list` notes. Tapping anywhere opens the
 * note in the editor through [WidgetBridge]; the widget never reads the
 * note file itself. Read-only by design: RemoteViews cannot reorder or
 * edit rows.
 */
class NoteWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val payload = widgetData.getString("note_$id", null)
            appWidgetManager.updateAppWidget(id, viewsFor(context, id, payload))
        }
    }

    /**
     * Drops the payloads of removed instances, so a deleted widget leaves
     * no snapshot behind. (The configuration rows are reaped on the next
     * Dart refresh, which cannot run from here: the engine may be dead.)
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        HomeWidgetPlugin.getData(context).edit().apply {
            for (id in appWidgetIds) remove("note_$id")
        }.apply()
    }

    private fun viewsFor(context: Context, id: Int, payload: String?): RemoteViews {
        val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
        val library = parsed?.optString("library").orEmpty()
        val note = parsed?.optString("note").orEmpty()
        val title = parsed?.optString("title").orEmpty().ifEmpty { "Note" }
        val body = bodyFor(parsed)

        val views = RemoteViews(context.packageName, R.layout.widget_note)
        views.setTextViewText(R.id.widget_note_title, title)
        views.setTextViewText(R.id.widget_note_body, body)

        val open = openNote(context, id, library, note)
        views.setOnClickPendingIntent(R.id.widget_note_root, open)
        return views
    }

    private fun bodyFor(parsed: JSONObject?): String {
        // No payload yet: the choice was just placed and Dart has not
        // pushed. The pin path (tree action) still exists, hence the hint.
        if (parsed == null) return "Open Niman to load — or pin a note first"
        val body = parsed.optString("body", "")
        if (body.isNotEmpty()) {
            return if (parsed.optBoolean("truncated", false)) "$body …" else body
        }
        return when (parsed.optString("kind", "")) {
            "missing" -> "Note not found"
            "list" -> "No items"
            else -> "Empty note"
        }
    }

    private fun openNote(context: Context, id: Int, library: String, note: String): PendingIntent {
        val intent = if (library.isEmpty() || note.isEmpty()) {
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        } else {
            Intent(context, MainActivity::class.java)
                .setAction(WidgetBridge.ACTION_OPEN_NOTE)
                .putExtra(WidgetBridge.EXTRA_LIBRARY, library)
                .putExtra(WidgetBridge.EXTRA_NOTE, note)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        } ?: Intent(context, MainActivity::class.java)
        // One request code per instance: shared codes collapse distinct
        // widgets into one pending intent.
        return PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
