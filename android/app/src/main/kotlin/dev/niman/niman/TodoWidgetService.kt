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
 * The scrollable items of the todo widget (issue 6 follow-up, sections
 * #1003): section headers and task rows, one RemoteViews each.
 *
 * The provider binds this service on the widget's ListView
 * (`setRemoteAdapter` with the instance id); the launcher binds the
 * service on demand when it renders the collection — placement is not
 * required — and asks the factory for exactly the items the (resized)
 * widget can show, so a library with more open tasks than fit scrolls
 * instead of clipping. The factory reads the same payload the provider
 * renders (`todo_<id>` prefs key, pushed by Dart on every todo change):
 * the service never reads todo.txt itself, and Dart stays the single
 * writer of widget data.
 *
 * A header is inert (no fill-in intent) and the widget always shows every
 * section expanded: a collection row can only fire an intent, and
 * folding is the app's per-device state (see [TodoWidgetItems]).
 */
class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoRowsFactory(applicationContext, intent)
    }

    /**
     * The factory behind one widget instance: the payload's items in
     * push order (sections by due date, each followed by its rows,
     * capped upstream), one RemoteViews per item.
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
        private var language = ""
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

        // A task row and a section header.
        override fun getViewTypeCount(): Int = TodoWidgetItems.VIEW_TYPE_COUNT

        override fun hasStableIds(): Boolean = true

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewAt(position: Int): RemoteViews {
            val (item, library, language, theme) = snapshot(position)
            if (item != null && TodoWidgetItems.viewType(item) == TodoWidgetItems.VIEW_SECTION) {
                return sectionViews(item, theme)
            }
            val views = RemoteViews(context.packageName, R.layout.widget_todo_row)
            val row = item ?: return views
            // The meta line names priority, the due date (unless the
            // section already says it) and the +project/@context/#tag
            // markers. Rows without any of them hide the line, so their
            // text aligns with the others instead of leaving a blank gap.
            val meta = TodoWidgetItems.metaLine(row)
            views.setTextViewText(R.id.widget_todo_row_meta, meta)
            views.setViewVisibility(
                R.id.widget_todo_row_meta,
                if (meta.isEmpty()) android.view.View.GONE else android.view.View.VISIBLE,
            )
            views.setTextViewText(R.id.widget_todo_row_text, TodoWidgetItems.string(row, "text"))
            // The app theme rides in the payload: without it (an old
            // push) the layout defaults stand.
            if (theme != null) {
                views.setTextColor(R.id.widget_todo_row_meta, theme.secondary)
                views.setTextColor(R.id.widget_todo_row_text, theme.primary)
            }
            // Every rendered row is open by definition, so the unchecked
            // CheckBox default is already right.
            val fillIn = Uri.Builder()
                .scheme("niman")
                .authority("todo-toggle")
                .appendQueryParameter("id", widgetId.toString())
                .appendQueryParameter("library", library)
                .appendQueryParameter("line", row.optInt("line", -1).toString())
                // The language the headings were written in: the
                // background isolate that re-pushes does not know it.
                .also { if (language.isNotEmpty()) it.appendQueryParameter("lg", language) }
                .also { WidgetTheme.appendParams(it, theme) }
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

        /**
         * A section header: label at the start, count at the end. It sets
         * no fill-in intent, so a tap on it does nothing; the Overdue one
         * is drawn in the error tone.
         */
        private fun sectionViews(item: JSONObject, theme: WidgetTheme?): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_todo_section)
            views.setTextViewText(
                R.id.widget_todo_section_label,
                TodoWidgetItems.sectionLabel(item),
            )
            views.setTextViewText(
                R.id.widget_todo_section_count,
                TodoWidgetItems.sectionCount(item),
            )
            val color = if (TodoWidgetItems.isErrorTone(item)) {
                theme?.error ?: context.getColor(R.color.widget_error)
            } else {
                theme?.secondary
            }
            if (color != null) {
                views.setTextColor(R.id.widget_todo_section_label, color)
                views.setTextColor(R.id.widget_todo_section_count, color)
            }
            return views
        }

        /**
         * The [position] item with its library, language and theme under
         * the parse lock, so a concurrent re-parse never hands out a mix
         * of two payloads.
         */
        private fun snapshot(position: Int): Snapshot {
            synchronized(this) {
                load()
                return Snapshot(rows.getOrNull(position), library, language, theme)
            }
        }

        private data class Snapshot(
            val item: JSONObject?,
            val library: String,
            val language: String,
            val theme: WidgetTheme?,
        )

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
                language = parsed?.let { TodoWidgetItems.string(it, "language") }.orEmpty()
                theme = WidgetTheme.fromPayload(payload)
                rows = TodoWidgetItems.parse(parsed?.optJSONArray("rows"))
            }
        }
    }
}
