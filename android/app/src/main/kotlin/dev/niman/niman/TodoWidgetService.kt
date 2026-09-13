package dev.niman.niman

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

/**
 * The row factory behind the todo widget's list (issue 6).
 *
 * Reads the same `todo_<id>` payload the provider renders; the header
 * and the taps live in [TodoWidgetProvider]. Rows only open the Todo tab
 * (the template pending intent fires on tap): checking off from the
 * widget is future work.
 */
class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TodoViewsFactory(applicationContext, intent)
    }
}

private const val TAG = "TodoWidget"

private class TodoViewsFactory(
    private val context: Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {

    private val appWidgetId = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID,
    )
    private var rows: List<TodoRow> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        rows = load()
    }

    override fun onDestroy() {
        rows = emptyList()
    }

    override fun getCount(): Int = rows.size

    override fun getViewAt(position: Int): RemoteViews {
        val row = rows[position]
        return RemoteViews(context.packageName, R.layout.widget_todo_row).apply {
            if (row.meta.isEmpty()) {
                setViewVisibility(R.id.widget_todo_row_meta, View.GONE)
            } else {
                setViewVisibility(R.id.widget_todo_row_meta, View.VISIBLE)
                setTextViewText(R.id.widget_todo_row_meta, row.meta)
            }
            setTextViewText(R.id.widget_todo_row_text, row.text)
            // Required for the template pending intent to fire.
            setOnClickFillInIntent(R.id.widget_todo_row, Intent())
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun load(): List<TodoRow> {
        val payload = HomeWidgetPlugin.getData(context).getString("todo_$appWidgetId", null)
        Log.d(TAG, "load widget $appWidgetId (payload ${payload?.length ?: 0} chars)")
        val rows = payload?.let { runCatching { JSONObject(it).optJSONArray("rows") }.getOrNull() }
            ?: return emptyList()
        // No empty-text filtering: the header counts raw rows, so every
        // row renders (a textless task still shows its priority/due).
        return List(rows.length()) { i ->
            val row = rows.optJSONObject(i) ?: return@List TodoRow("", "")
            val text = row.optString("text", "")
            val meta = listOfNotNull(
                row.optString("priority", "").takeIf { it.isNotEmpty() }?.let { "($it)" },
                row.optString("due", "").takeIf { it.isNotEmpty() },
            ).joinToString(" · ")
            TodoRow(meta, text)
        }
    }
}

private data class TodoRow(val meta: String, val text: String)
