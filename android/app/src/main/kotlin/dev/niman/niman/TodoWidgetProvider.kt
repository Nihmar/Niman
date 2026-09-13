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
import org.json.JSONObject

/**
 * The open-todos home-screen widget (issue 6).
 *
 * Renders the payload Dart pushes under `todo_<id>` (see
 * `lib/src/widget/widget_payload.dart`): the header names the library,
 * the rows show due-soonest first. Header taps open that library's Todo
 * tab through [WidgetBridge]; row taps complete the task through the
 * background toggle; the widget never reads todo.txt itself.
 *
 * The rows render in-process (one child [RemoteViews] per payload row):
 * the payload already carries every row, and a remote views service
 * would need the LAUNCHER to bind it cross-process -- a bind that only
 * happens when the widget is placed, so an already-placed widget could
 * never recover. Pushing the whole view tree keeps every instance alive
 * on the very next refresh.
 */
class TodoWidgetProvider : HomeWidgetProvider() {

    override fun onEnabled(context: Context) {
        WidgetDebugLog.log(context, "todo provider enabled (first widget placed)")
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        WidgetDebugLog.log(context, "todo provider disabled (last widget removed)")
        super.onDisabled(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val payload = widgetData.getString("todo_$id", null)
            WidgetDebugLog.log(
                context,
                "todo update widget $id (payload ${payload?.length ?: 0} chars)",
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
                    "todo views failed to inflate for widget $id: $inflateFailure",
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
        WidgetDebugLog.log(context, "todo deleted: ${appWidgetIds.toList()}")
        super.onDeleted(context, appWidgetIds)
        HomeWidgetPlugin.getData(context).edit().apply {
            for (id in appWidgetIds) remove("todo_$id")
        }.apply()
    }

    private fun viewsFor(context: Context, id: Int, payload: String?): RemoteViews {
        val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
        val library = parsed?.optString("library").orEmpty()
        val rows = parsed?.optJSONArray("rows")
        val truncated = parsed?.optBoolean("truncated", false) == true

        val views = RemoteViews(context.packageName, R.layout.widget_todo)
        views.setTextViewText(R.id.widget_todo_title, titleFor(library))
        views.setTextViewText(R.id.widget_todo_count, countFor(rows?.length() ?: 0, truncated))
        views.setTextViewText(
            R.id.widget_todo_empty,
            if (payload == null) "Open Niman to load todos" else "No open tasks",
        )

        // The rows render in-process, one child per payload row (Dart
        // caps the payload at 20 rows upstream).
        val rowCount = rows?.length() ?: 0
        for (i in 0 until rowCount) {
            val row = rows?.optJSONObject(i) ?: continue
            views.addView(R.id.widget_todo_rows, rowViews(context, id, library, row))
        }
        views.setViewVisibility(R.id.widget_todo_rows, if (rowCount == 0) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.widget_todo_empty, if (rowCount == 0) View.VISIBLE else View.GONE)

        val open = openTodo(context, id, library)
        views.setOnClickPendingIntent(R.id.widget_todo_header, open)
        views.setOnClickPendingIntent(R.id.widget_todo_empty, open)
        // Same flow as the launcher shortcut (round 2, R3): the "+"
        // button opens the app's add-task dialog. A different action
        // from the open intent keeps the two pending intents distinct.
        views.setOnClickPendingIntent(R.id.widget_todo_add, addTodo(context, id))
        return views
    }

    /**
     * One row (round 2, R2): tapping anywhere on it completes the task
     * without opening the app. The per-row broadcast carries the
     * fill-in URI the background worker forwards to Dart.
     */
    private fun rowViews(context: Context, id: Int, library: String, row: JSONObject): RemoteViews {
        val meta = listOfNotNull(
            row.optString("priority", "").takeIf { it.isNotEmpty() }?.let { "($it)" },
            row.optString("due", "").takeIf { it.isNotEmpty() },
        ).joinToString(" · ")
        val fillIn = Uri.Builder()
            .scheme("niman")
            .authority("todo-toggle")
            .appendQueryParameter("id", id.toString())
            .appendQueryParameter("library", library)
            .appendQueryParameter("line", row.optInt("line", -1).toString())
            .build()
        return RemoteViews(context.packageName, R.layout.widget_todo_row).apply {
            setViewVisibility(
                R.id.widget_todo_row_meta,
                if (meta.isEmpty()) View.GONE else View.VISIBLE,
            )
            setTextViewText(R.id.widget_todo_row_meta, meta)
            setTextViewText(R.id.widget_todo_row_text, row.optString("text", ""))
            setBoolean(R.id.widget_todo_row_check, "setChecked", false)
            // The whole row toggles (checkbox included); one broadcast
            // per row, the URI in its data.
            val toggle = HomeWidgetBackgroundIntent.getBroadcast(context, fillIn)
            setOnClickPendingIntent(R.id.widget_todo_row, toggle)
            setOnClickPendingIntent(R.id.widget_todo_row_check, toggle)
        }
    }

    private fun titleFor(library: String): String {
        if (library.isEmpty()) return "Todos"
        val base = library.trimEnd('/').substringAfterLast('/').substringAfterLast('\\')
        return base.ifEmpty { "Todos" }
    }

    private fun countFor(count: Int, truncated: Boolean): String {
        if (count == 0) return ""
        return if (truncated) "$count+ open" else "$count open"
    }

    private fun addTodo(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(ShortcutsBridge.ACTION)
            .putExtra(ShortcutsBridge.EXTRA_ID, "new_todo")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openTodo(context: Context, id: Int, library: String): PendingIntent {
        val intent = if (library.isEmpty()) {
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        } else {
            Intent(context, MainActivity::class.java)
                .setAction(WidgetBridge.ACTION_OPEN_TODO)
                .putExtra(WidgetBridge.EXTRA_LIBRARY, library)
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
