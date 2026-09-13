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
 * normal notes, or the checklist rows for `type: list` notes — drawn
 * like the todo widget, from 20 STATIC layout slots (one per payload
 * row; the 20-row cap lives in Dart). The launcher reuses the inflated
 * tree between updates, so a provider `addView` would accumulate a copy
 * of the rows on every refresh; each refresh re-fills the slots
 * (text, color, visibility) instead.
 *
 * List rows are interactive: a tap flips the item in the background
 * (`niman://note-row-toggle`), and the header "+" appends a new empty
 * item (`niman://note-row-add`); the header opens the note. Checked rows
 * render dimmed (RemoteViews forbids `CheckBox.setChecked`, and has no
 * paint flags, so no strikethrough). Normal notes stay read-only
 * (RemoteViews cannot edit text in place, and editing and moving rows
 * live in the app). The widget never reads the note file itself.
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
        // The rows fill the 20 static slots (Dart caps the payload at
        // 20 rows upstream).
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
        for (i in 0 until rowIds.size) {
            val row = if (i < rowCount) rows?.optJSONObject(i) else null
            views.setViewVisibility(
                rowIds[i],
                if (row == null) View.GONE else View.VISIBLE,
            )
            if (row != null) fillRow(views, context, id, library, note, i, row)
        }
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
     * Fills slot [slot] with [row]: the same CheckBox row as the todo
     * widget. Tapping flips the item in the background; checked rows
     * render dimmed (the CheckBox itself cannot be checked from
     * RemoteViews, and the color is set both ways because the launcher
     * keeps the tree between updates). Editing and moving rows live in
     * the app — the note opens from the header.
     */
    private fun fillRow(
        views: RemoteViews,
        context: Context,
        id: Int,
        library: String,
        note: String,
        slot: Int,
        row: JSONObject,
    ) {
        val checked = row.optBoolean("checked", false)
        views.setTextViewText(rowTextIds[slot], row.optString("text", ""))
        views.setTextColor(
            rowTextIds[slot],
            context.getColor(
                if (checked) R.color.widget_text_secondary else R.color.widget_text_primary,
            ),
        )
        val fillIn = Uri.Builder()
            .scheme("niman")
            .authority("note-row-toggle")
            .appendQueryParameter("id", id.toString())
            .appendQueryParameter("library", library)
            .appendQueryParameter("note", note)
            .appendQueryParameter("line", row.optInt("line", -1).toString())
            .build()
        val toggle = HomeWidgetBackgroundIntent.getBroadcast(context, fillIn)
        views.setOnClickPendingIntent(rowIds[slot], toggle)
    }

    /** The background pending intent for the header "+": appends a new
     *  empty item through the background worker. */
    private fun addNoteRow(context: Context, id: Int, library: String, note: String): PendingIntent {
        return HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.Builder()
                .scheme("niman")
                .authority("note-row-add")
                .appendQueryParameter("id", id.toString())
                .appendQueryParameter("library", library)
                .appendQueryParameter("note", note)
                .build(),
        )
    }

    companion object {
        // The 20 static row slots of R.layout.widget_note_list (kept in
        // sync by hand; the cap is widgetChecklistMaxItems in Dart).
        val rowIds = intArrayOf(
            R.id.widget_note_row_0, R.id.widget_note_row_1, R.id.widget_note_row_2,
            R.id.widget_note_row_3, R.id.widget_note_row_4, R.id.widget_note_row_5,
            R.id.widget_note_row_6, R.id.widget_note_row_7, R.id.widget_note_row_8,
            R.id.widget_note_row_9, R.id.widget_note_row_10, R.id.widget_note_row_11,
            R.id.widget_note_row_12, R.id.widget_note_row_13, R.id.widget_note_row_14,
            R.id.widget_note_row_15, R.id.widget_note_row_16, R.id.widget_note_row_17,
            R.id.widget_note_row_18, R.id.widget_note_row_19,
        )
        val rowTextIds = intArrayOf(
            R.id.widget_note_row_text_0, R.id.widget_note_row_text_1, R.id.widget_note_row_text_2,
            R.id.widget_note_row_text_3, R.id.widget_note_row_text_4, R.id.widget_note_row_text_5,
            R.id.widget_note_row_text_6, R.id.widget_note_row_text_7, R.id.widget_note_row_text_8,
            R.id.widget_note_row_text_9, R.id.widget_note_row_text_10, R.id.widget_note_row_text_11,
            R.id.widget_note_row_text_12, R.id.widget_note_row_text_13, R.id.widget_note_row_text_14,
            R.id.widget_note_row_text_15, R.id.widget_note_row_text_16, R.id.widget_note_row_text_17,
            R.id.widget_note_row_text_18, R.id.widget_note_row_text_19,
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
