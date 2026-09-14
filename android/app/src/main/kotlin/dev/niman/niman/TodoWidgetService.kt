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
 * The scrollable rows of the todo widget (issue 6 follow-up).
 *
 * The provider binds this service on the widget's ListView
 * (`setRemoteAdapter` with the instance id); the launcher binds the
 * service on demand when it renders the collection — placement is not
 * required — and asks the factory for exactly the rows the (resized)
 * widget can show, so a library with more open tasks than fit scrolls
 * instead of clipping. The factory reads the same payload the provider
 * renders (`todo_<id>` prefs key, pushed by Dart on every todo change):
 * the service never reads todo.txt itself, and Dart stays the single
 * writer of widget data.
 */
class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoRowsFactory(applicationContext, intent)
    }

    /**
     * The factory behind one widget instance: the payload's rows in
     * push order (due-soonest first, capped upstream), one RemoteViews
     * per row.
     */
    private class TodoRowsFactory(
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
            val views = RemoteViews(context.packageName, R.layout.widget_todo_row)
            val (row, library) = snapshot(position)
            if (row == null) return views
            val meta = listOfNotNull(
                jsonString(row, "priority").takeIf { it.isNotEmpty() }?.let { "($it)" },
                jsonString(row, "due").takeIf { it.isNotEmpty() },
            ).joinToString(" · ")
            views.setTextViewText(R.id.widget_todo_row_meta, meta)
            views.setTextViewText(R.id.widget_todo_row_text, jsonString(row, "text"))
            // Every rendered row is open by definition, so the unchecked
            // CheckBox default is already right.
            val fillIn = Uri.Builder()
                .scheme("niman")
                .authority("todo-toggle")
                .appendQueryParameter("id", widgetId.toString())
                .appendQueryParameter("library", library)
                .appendQueryParameter("line", row.optInt("line", -1).toString())
                .build()
            // The whole row toggles (checkbox included). A
            // setOnClickPendingIntent is dropped by the framework on a
            // collection child, so the row hands its URI to the
            // provider's pending-intent template: one broadcast per row,
            // the URI in the merged data, the headless Dart engine does
            // the edit and re-push.
            views.setOnClickFillInIntent(R.id.widget_todo_row, Intent().setData(fillIn))
            return views
        }

        /// The [key] string of [row]; an explicit JSON null reads as
        /// absent (optString would hand back the string "null").
        private fun jsonString(row: JSONObject, key: String): String {
            val value = row.opt(key)
            return if (value == null || value == JSONObject.NULL) "" else value.toString()
        }

        /**
         * The [position] row and its library under the parse lock, so a
         * concurrent re-parse never hands out a mix of two payloads.
         */
        private fun snapshot(
            position: Int,
        ): Pair<JSONObject?, String> {
            synchronized(this) {
                load()
                return rows.getOrNull(position) to library
            }
        }

        private fun load() {
            synchronized(this) {
                val payload = HomeWidgetPlugin.getData(context)
                    .getString("todo_$widgetId", null)
                if (loadedPayload == payload) return
                loadedPayload = payload
                if (payload == null) {
                    WidgetDebugLog.log(
                        context,
                        "todo factory $widgetId: no payload (unconfigured or never pushed)",
                    )
                }
                val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
                library = parsed?.optString("library").orEmpty()
                val array = parsed?.optJSONArray("rows")
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
