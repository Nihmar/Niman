package dev.niman.niman

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/**
 * The scrollable rows of the list-note widget (issue 6 follow-up).
 *
 * The provider binds this service on the widget's ListView
 * (`setRemoteAdapter` with the instance id); the launcher binds the
 * service on demand when it renders the collection, so a long checklist
 * scrolls instead of clipping to the layout. The factory reads the same
 * payload the provider renders (`note_<id>` prefs key, pushed by Dart on
 * every note change): the service never reads the note file itself, and
 * Dart stays the single writer of widget data.
 */
class NoteWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return NoteRowsFactory(applicationContext, intent)
    }

    /**
     * The factory behind one widget instance: the payload's checklist
     * rows in document order (capped upstream), one RemoteViews per row.
     */
    private class NoteRowsFactory(
        context: Context,
        intent: Intent,
    ) : RemoteViewsFactory {
        private val context = context.applicationContext
        private val widgetId: Int = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )

        // Re-parsed only when the payload string actually changed (a
        // refresh and a scroll must not re-parse on every row).
        private var loadedPayload: String? = null
        private var rows: List<JSONObject> = emptyList()
        private var library = ""
        private var note = ""
        private var theme: WidgetTheme? = null

        override fun onCreate() = Unit

        override fun onDataSetChanged() {
            load()
        }

        override fun onDestroy() = Unit

        override fun getCount(): Int {
            synchronized(this) {
                load()
                return rows.size
            }
        }

        override fun getItemId(position: Int): Long = position.toLong()

        override fun getViewTypeCount(): Int = 1

        override fun hasStableIds(): Boolean = true

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewAt(position: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_note_row)
            val (row, library, note, theme) = snapshot(position)
            if (row == null) return views
            views.setTextViewText(R.id.widget_note_row_text, row.optString("text", ""))
            // The checked state is what makes a done row read as done:
            // `setCompoundButtonChecked` is on the RemoteViews allowlist
            // (a plain `setChecked` is not).
            views.setCompoundButtonChecked(
                R.id.widget_note_row_check,
                row.optBoolean("checked", false),
            )
            // The app theme rides in the payload: without it (an old
            // push) the layout defaults stand.
            if (theme != null) {
                views.setTextColor(R.id.widget_note_row_text, theme.primary)
            }
            val fillIn = Uri.Builder()
                .scheme("niman")
                .authority("note-row-toggle")
                .appendQueryParameter("id", widgetId.toString())
                .appendQueryParameter("library", library)
                .appendQueryParameter("note", note)
                .appendQueryParameter("line", row.optInt("line", -1).toString())
                .also { WidgetTheme.appendParams(it, theme) }
                .build()
            // The whole row toggles (checkbox included). A
            // setOnClickPendingIntent is dropped by the framework on a
            // collection child, so the row hands its URI to the
            // provider's pending-intent template: one broadcast per row,
            // the URI in the merged data, the headless Dart engine does
            // the edit and re-push.
            views.setOnClickFillInIntent(R.id.widget_note_row, Intent().setData(fillIn))
            return views
        }

        /**
         * One row with the payload it was parsed from (library, note and
         * theme), so a concurrent re-parse never hands out a mix of two
         * payloads.
         */
        private data class RowSnapshot(
            val row: JSONObject?,
            val library: String,
            val note: String,
            val theme: WidgetTheme?,
        )

        /**
         * The [position] row with its library, note and theme under the
         * parse lock, so a concurrent re-parse never hands out a mix of
         * two payloads.
         */
        private fun snapshot(position: Int): RowSnapshot {
            synchronized(this) {
                load()
                return RowSnapshot(rows.getOrNull(position), library, note, theme)
            }
        }

        private fun load() {
            synchronized(this) {
                val payload = HomeWidgetPlugin.getData(context)
                    .getString("note_$widgetId", null)
                if (loadedPayload == payload) return
                loadedPayload = payload
                if (payload == null) {
                    WidgetDebugLog.log(
                        context,
                        "note factory $widgetId: no payload (unconfigured or never pushed)",
                    )
                }
                val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
                // Only list notes carry rows; anything else (a note-kind
                // payload, a stale or missing one) renders no rows.
                if (parsed == null || parsed.optString("kind", "") != "list") {
                    rows = emptyList()
                    library = ""
                    note = ""
                    theme = null
                    return
                }
                library = parsed.optString("library").orEmpty()
                note = parsed.optString("note").orEmpty()
                theme = WidgetTheme.fromPayload(payload)
                val array = parsed.optJSONArray("rows")
                rows = if (array == null) {
                    emptyList()
                } else {
                    (0 until array.length())
                        .mapNotNull { array.optJSONObject(it) }
                }
            }
        }
    }
}
