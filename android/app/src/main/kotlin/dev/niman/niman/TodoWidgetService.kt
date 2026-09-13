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
 * Reads the same `todo_<id>` payload the provider renders. Row taps
 * complete the task through the background toggle (round 2, R2): the
 * fill-in carries a `niman://todo-toggle` URI per row, the template
 * pending intent (set by the provider) is the background broadcast.
 * The header keeps opening the Todo tab.
 */
class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val id = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        // The launcher binds this service cross-process; these logs are
        // the proof the bind reached us (the row list is invisible from
        // the provider side).
        Log.d(TAG, "view factory requested for widget $id")
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
    private var library: String = ""

    override fun onCreate() {
        Log.d(TAG, "factory created for widget $appWidgetId")
    }

    override fun onDataSetChanged() {
        rows = load()
        Log.d(TAG, "factory data changed for widget $appWidgetId: ${rows.size} rows")
    }

    override fun onDestroy() {
        Log.d(TAG, "factory destroyed for widget $appWidgetId")
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
            setBoolean(R.id.widget_todo_row_check, "setChecked", false)
            // Per-row target for the background-toggle template: id,
            // library and file line travel in the data URI (the only
            // channel the background worker forwards to Dart).
            val fillIn = Intent().apply {
                data = android.net.Uri.Builder()
                    .scheme("niman")
                    .authority("todo-toggle")
                    .appendQueryParameter("id", appWidgetId.toString())
                    .appendQueryParameter("library", library)
                    .appendQueryParameter("line", row.line.toString())
                    .build()
            }
            // The whole row toggles (checkbox included): one template
            // per collection allows exactly one base action.
            setOnClickFillInIntent(R.id.widget_todo_row, fillIn)
            setOnClickFillInIntent(R.id.widget_todo_row_check, fillIn)
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun load(): List<TodoRow> {
        val payload = HomeWidgetPlugin.getData(context).getString("todo_$appWidgetId", null)
        Log.d(TAG, "load widget $appWidgetId (payload ${payload?.length ?: 0} chars)")
        val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
            ?: run { library = ""; return emptyList() }
        library = parsed.optString("library", "")
        val rows = parsed.optJSONArray("rows") ?: return emptyList()
        // No empty-text filtering: the header counts raw rows, so every
        // row renders (a textless task still shows its priority/due).
        return List(rows.length()) { i ->
            val row = rows.optJSONObject(i) ?: return@List TodoRow("", "", -1)
            val text = row.optString("text", "")
            val meta = listOfNotNull(
                row.optString("priority", "").takeIf { it.isNotEmpty() }?.let { "($it)" },
                row.optString("due", "").takeIf { it.isNotEmpty() },
            ).joinToString(" · ")
            TodoRow(meta, text, row.optInt("line", -1))
        }
    }
}

private data class TodoRow(val meta: String, val text: String, val line: Int)
