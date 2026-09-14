package dev.niman.niman

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * The pinned-note home-screen widget (issue 6).
 *
 * Renders the payload Dart pushes under `note_<id>` (see
 * `lib/src/widget/widget_payload.dart`): the title plus the excerpt for
 * normal notes, or the checklist rows for `type: list` notes.
 *
 * List rows are a SCROLLABLE `RemoteCollection` bound to
 * [NoteWidgetService] (the launcher binds the service on demand, so a
 * long checklist scrolls instead of clipping): a row tap flips the item
 * in the background (`niman://note-row-toggle`), the header "+" opens
 * [NoteItemAddActivity] — a floating dialog over the launcher where the
 * item is typed on the home screen (RemoteViews cannot capture typed
 * text) and lands through the same background path — and the header
 * opens the note. Checked rows render checked through
 * `setCompoundButtonChecked` (a plain `setChecked` is off the RemoteViews
 * allowlist). Normal notes stay read-only (RemoteViews cannot edit text
 * in place, and editing and moving rows live in the app). The widget
 * never reads the note file itself.
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
            // Force the host to re-query the rows after the payload
            // landed: a tap-to-flip re-pushes a changed payload while the
            // widget is already bound, and the host otherwise keeps
            // showing the cached rows (no-op for normal notes, which
            // have no collection view).
            appWidgetManager.notifyAppWidgetViewDataChanged(
                id,
                R.id.widget_note_rows,
            )
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
        if (kind == "list") {
            return listViews(context, id, library, note, title, payload)
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
        payload: String?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_note_list)
        views.setTextViewText(R.id.widget_note_title, title)
        views.setTextViewText(
            R.id.widget_note_empty,
            if (payload == null) "Open Niman to load — or pin a note first" else "No items",
        )
        // The rows scroll: the launcher binds NoteWidgetService on
        // demand and the factory serves the payload's checklist rows
        // (row taps and the checked-state rendering live there). The
        // instance id rides with the bind as EXTRA_APPWIDGET_ID, so
        // each instance gets its own factory.
        //
        // The two-argument overload targets the ListView by its layout
        // id: the deprecated three-argument overload's first parameter
        // is the appWidgetId (ignored) and its second the view id, so
        // passing (viewId, appWidgetId) binds the service to a view
        // that does not exist and the rows never render.
        views.setEmptyView(R.id.widget_note_rows, R.id.widget_note_empty)
        @Suppress("DEPRECATION") // RemoteCollectionItems is static-only
        views.setRemoteAdapter(
            R.id.widget_note_rows,
            Intent(context, NoteWidgetService::class.java)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id),
        )
        // Row taps: the framework drops a setOnClickPendingIntent set on
        // a collection child (a row of the bound ListView), so the rows
        // hand their URI to this template instead — the merged
        // broadcast feeds the headless engine that does the flip.
        views.setPendingIntentTemplate(
            R.id.widget_note_rows,
            HomeWidgetBackgroundIntent.getBroadcast(context),
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
     * The pending intent for the header "+": the floating add dialog
     * over the launcher ([NoteItemAddActivity]) — the item is typed on
     * the home screen and lands through the background add broadcast,
     * so the launcher is never left. RemoteViews cannot capture typed
     * text, so the "+" never appends blindly.
     */
    private fun addNoteRow(context: Context, id: Int, library: String, note: String): PendingIntent {
        val intent = Intent(context, NoteItemAddActivity::class.java)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
            .putExtra(WidgetBridge.EXTRA_LIBRARY, library)
            .putExtra(WidgetBridge.EXTRA_NOTE, note)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        // One request code per instance: shared codes collapse distinct
        // widgets into one pending intent.
        return PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
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
        return mainActivityIntent(context, id, library, note, WidgetBridge.ACTION_OPEN_NOTE)
    }

    /**
     * The activity pending intent a header tap fires: [action] with the
     * library/note extras, or a plain app launch when the target is
     * unknown (a stale payload). One request code per instance: shared
     * codes collapse distinct widgets into one pending intent.
     */
    private fun mainActivityIntent(
        context: Context,
        id: Int,
        library: String,
        note: String,
        action: String,
    ): PendingIntent {
        val intent = if (library.isEmpty() || note.isEmpty()) {
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        } else {
            Intent(context, MainActivity::class.java)
                .setAction(action)
                .putExtra(WidgetBridge.EXTRA_LIBRARY, library)
                .putExtra(WidgetBridge.EXTRA_NOTE, note)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        } ?: Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
