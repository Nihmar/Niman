package dev.niman.niman

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/**
 * The scrollable rows of the Study widget (#533): the payload's groups —
 * a deck: category — and decks, in push order. The factory reads the
 * payload the provider renders (`study_<id>`); Dart is its only writer.
 * A deck row hands its library and note to the provider's template, so a
 * tap opens the deck.
 */
class StudyWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        StudyRowsFactory(applicationContext, intent)

    private class StudyRowsFactory(
        context: Context,
        intent: Intent,
    ) : RemoteViewsFactory {
        private val context = context.applicationContext
        private val widgetId: Int = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )

        // Re-parsed only when the payload string changed.
        private var loadedPayload: String? = null
        private var rows: List<JSONObject> = emptyList()
        private var library = ""
        private var theme: WidgetTheme? = null

        override fun onCreate() = Unit

        override fun onDataSetChanged() = load()

        override fun onDestroy() = Unit

        override fun getCount(): Int = synchronized(this) {
            load()
            rows.size
        }

        override fun getItemId(position: Int): Long = position.toLong()

        // A group and a deck.
        override fun getViewTypeCount(): Int = 2

        override fun hasStableIds(): Boolean = true

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewAt(position: Int): RemoteViews {
            val (row, library, theme) = synchronized(this) {
                load()
                Triple(rows.getOrNull(position), library, theme)
            }
            if (row?.optString("kind") == "group") {
                val views = RemoteViews(context.packageName, R.layout.widget_study_group)
                val text = row.optString("text")
                views.setTextViewText(
                    R.id.widget_study_group,
                    text.ifEmpty { context.getString(R.string.widget_study_no_category) },
                )
                theme?.let { views.setTextColor(R.id.widget_study_group, it.secondary) }
                return views
            }
            val views = RemoteViews(context.packageName, R.layout.widget_study_row)
            if (row == null) return views
            views.setTextViewText(R.id.widget_study_row_name, row.optString("name"))
            views.setTextViewText(
                R.id.widget_study_row_counts,
                context.getString(
                    R.string.widget_study_row_counts,
                    row.optInt("due"),
                    row.optInt("new"),
                ),
            )
            theme?.let {
                views.setTextColor(R.id.widget_study_row_name, it.primary)
                views.setTextColor(R.id.widget_study_row_counts, it.secondary)
            }
            views.setOnClickFillInIntent(
                R.id.widget_study_row,
                Intent()
                    .putExtra(WidgetBridge.EXTRA_LIBRARY, library)
                    .putExtra(WidgetBridge.EXTRA_NOTE, row.optString("path")),
            )
            return views
        }

        private fun load() {
            synchronized(this) {
                val payload = HomeWidgetPlugin.getData(context)
                    .getString("study_$widgetId", null)
                if (loadedPayload == payload) return
                loadedPayload = payload
                val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
                library = parsed?.optString("library").orEmpty()
                theme = WidgetTheme.fromPayload(payload)
                val array = parsed?.optJSONArray("rows")
                rows = if (array == null) {
                    emptyList()
                } else {
                    (0 until array.length()).mapNotNull { array.optJSONObject(it) }
                }
            }
        }
    }
}
