package dev.niman.niman

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * The open-todos home-screen widget (issue 6).
 *
 * Renders the payload Dart pushes under `todo_<id>` (see
 * `lib/src/widget/widget_payload.dart`): the header names the library,
 * the list shows due-soonest first. Every tap opens that library's Todo
 * tab through [WidgetBridge]; the widget never reads todo.txt itself.
 */
class TodoWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "TodoWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val payload = widgetData.getString("todo_$id", null)
            Log.d(TAG, "update widget $id (payload ${payload?.length ?: 0} chars)")
            appWidgetManager.updateAppWidget(id, viewsFor(context, id, payload))
            // The collection does not always rebind on a full update
            // alone: invalidate its data explicitly so the rows follow
            // the new snapshot.
            appWidgetManager.notifyAppWidgetViewDataChanged(id, R.id.widget_todo_list)
        }
    }

    /**
     * Drops the payloads of removed instances, so a deleted widget leaves
     * no snapshot behind. (The configuration rows are reaped on the next
     * Dart refresh, which cannot run from here: the engine may be dead.)
     */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
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
        views.setEmptyView(R.id.widget_todo_list, R.id.widget_todo_empty)
        views.setTextViewText(
            R.id.widget_todo_empty,
            if (payload == null) "Open Niman to load todos" else "No open tasks",
        )

        // The collection needs a per-instance adapter identity, or every
        // widget shows the first one's rows.
        val adapter = Intent(context, TodoWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
            data = Uri.parse("niman://todo/$id")
        }
        views.setRemoteAdapter(R.id.widget_todo_list, adapter)

        val open = openTodo(context, id, library)
        views.setOnClickPendingIntent(R.id.widget_todo_header, open)
        views.setOnClickPendingIntent(R.id.widget_todo_empty, open)
        // Row taps complete the task without opening the app (round 2,
        // R2): the broadcast reaches the Dart background toggle, one
        // row's fill-in URI at a time.
        views.setPendingIntentTemplate(
            R.id.widget_todo_list,
            es.antonborri.home_widget.HomeWidgetBackgroundIntent.getBroadcast(context),
        )
        // Same flow as the launcher shortcut (round 2, R3): the "+"
        // button opens the app's add-task dialog. A different action
        // from the open intent keeps the two pending intents distinct.
        views.setOnClickPendingIntent(R.id.widget_todo_add, addTodo(context, id))
        return views
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
