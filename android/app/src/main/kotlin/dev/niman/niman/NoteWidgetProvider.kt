package dev.niman.niman

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * The pinned-note home-screen widget (issue 6).
 *
 * Renders the payload Dart pushes under `note_<id>` (see
 * `lib/src/widget/widget_payload.dart`): the title plus the excerpt for
 * normal notes, or the checklist rows for `type: list` notes — one row
 * view per item. List rows are interactive: a tap flips the item in the
 * background (`niman://note-row-toggle`), a long-press opens the note in
 * the note from the header, and the header "+" appends a new empty
 * item (`niman://note-row-add`). Normal notes stay read-only (RemoteViews
 * cannot edit text in place, nor does it support long-click — so
 * editing and moving rows live in the app). The widget never reads the
 * note file itself.
 */
class NoteWidgetProvider : HomeWidgetProvider() {

    override fun onEnabled(context: Context) {
        WidgetDebugLog.log(context, "note provider enabled (first widget placed)")
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        WidgetDebugLog.log(context, "note provider disabled (last widget removed)")
        super.onDisabled(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val payload = widgetData.getString("note_$id", null)
            WidgetDebugLog.log(
                context,
                "note update widget $id (payload ${payload?.length ?: 0} chars)",
            )
            val views = viewsFor(context, id, payload)
            // Dry-run the very inflation the launcher performs: a tree
            // that cannot inflate in-process (a layout or resource
            // error) cannot render anywhere, and the export would
            // otherwise show only that the push happened.
            val inflateFailure =
                runCatching { views.apply(context, null) }.exceptionOrNull()
            if (inflateFailure != null) {
                WidgetDebugLog.log(
                    context,
                    "note views failed to inflate for widget $id: $inflateFailure",
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /**
     * Drops the payloads of removed instances, so a deleted widget leaves
     * no snapshot behind. (The configuration rows are reaped on the next
     * Dart refresh, which cannot run from here: the engine may be dead.)
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        WidgetDebugLog.log(context, "note deleted: ${appWidgetIds.toList()}")
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
        val kind = parsed?.optString("kind", "") ?: ""
        // The rows render in-process, one child per payload row (Dart
        // caps the payload at 20 rows upstream).
        val rows = if (kind == "list") parsed?.optJSONArray("rows") else null
        if (kind == "list") {
            return listViews(context, id, library, note, title, rows, payload)
        }
        val views = RemoteViews(context.packageName, R.layout.widget_note)
        views.setTextViewText(R.id.widget_note_title, title)
        views.setTextViewText(R.id.widget_note_body, bodyFor(parsed, payload))
        val open = openNote(context, id, library, note)
        views.setOnClickPendingIntent(R.id.widget_note_root, open)
        return views
    }

    private fun listViews(
        context: Context,
        id: Int,
        library: String,
        note: String,
        title: String,
        rows: JSONArray?,
        payload: String?,
    ): RemoteViews {
        val rowCount = rows?.length() ?: 0
        val views = RemoteViews(context.packageName, R.layout.widget_note_list)
        views.setTextViewText(R.id.widget_note_title, title)
        for (i in 0 until rowCount) {
            val row = rows?.optJSONObject(i) ?: continue
            views.addView(R.id.widget_note_rows, rowViews(context, id, library, note, row))
        }
        views.setViewVisibility(
            R.id.widget_note_rows,
            if (rowCount == 0) View.GONE else View.VISIBLE,
        )
        views.setViewVisibility(
            R.id.widget_note_empty,
            if (rowCount == 0) View.VISIBLE else View.GONE,
        )
        views.setTextViewText(
            R.id.widget_note_empty,
            if (payload == null) "Open Niman to load — or pin a note first" else "No items",
        )
        val open = openNote(context, id, library, note)
        views.setOnClickPendingIntent(R.id.widget_note_header, open)
        views.setOnClickPendingIntent(R.id.widget_note_empty, open)
        views.setOnClickPendingIntent(
            R.id.widget_note_add,
            addNoteRow(context, id, library, note),
        )
        return views
    }

    /**
     * One checklist row: the box glyph plus the item prose. Tapping
     * flips the item in the background; checked rows render dimmed
     * (RemoteViews has no paint flags, so no strikethrough, and no
     * per-row padding, so the nesting depth stays in the app).
     * Editing and moving rows live in the app — the note opens from the
     * header.
     */
    private fun rowViews(
        context: Context,
        id: Int,
        library: String,
        note: String,
        row: JSONObject,
    ): RemoteViews {
        val checked = row.optBoolean("checked", false)
        val views = RemoteViews(context.packageName, R.layout.widget_note_row)
        views.setTextViewText(R.id.widget_note_row_box, if (checked) "☑" else "☐")
        views.setTextViewText(R.id.widget_note_row_text, row.optString("text", ""))
        if (checked) {
            val secondary = context.getColor(R.color.widget_text_secondary)
            views.setTextColor(R.id.widget_note_row_box, secondary)
            views.setTextColor(R.id.widget_note_row_text, secondary)
        }
        val toggle = HomeWidgetBackgroundIntent.getBroadcast(
            context,
            rowFillIn("note-row-toggle", id, library, note, row.optInt("line", -1)),
        )
        views.setOnClickPendingIntent(R.id.widget_note_row, toggle)
        return views
    }

    /** The background fill-in URI of a row op: `niman://<host>` with the
     *  widget id, library and note, plus the item line for toggles. */
    private fun rowFillIn(
        host: String,
        id: Int,
        library: String,
        note: String,
        line: Int,
    ): Uri {
        val builder = Uri.Builder()
            .scheme("niman")
            .authority(host)
            .appendQueryParameter("id", id.toString())
            .appendQueryParameter("library", library)
            .appendQueryParameter("note", note)
        if (line >= 0) builder.appendQueryParameter("line", line.toString())
        return builder.build()
    }

    /** The background pending intent for the header "+": appends a new
     *  empty item through the background worker. */
    private fun addNoteRow(context: Context, id: Int, library: String, note: String): PendingIntent {
        return HomeWidgetBackgroundIntent.getBroadcast(
            context,
            rowFillIn("note-row-add", id, library, note, -1),
        )
    }

    private fun bodyFor(parsed: JSONObject?, payload: String?): String {
        // No payload yet: the choice was just placed and Dart has not
        // pushed. The pin path (tree action) still exists, hence the hint.
        if (parsed == null) return "Open Niman to load — or pin a note first"
        val body = parsed.optString("body", "")
        if (body.isNotEmpty()) {
            return if (parsed.optBoolean("truncated", false)) "$body …" else body
        }
        return when (parsed.optString("kind", "")) {
            "missing" -> "Note not found"
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
