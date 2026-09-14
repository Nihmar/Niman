package dev.niman.niman

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * The open-todos home-screen widget (issue 6).
 *
 * Renders the payload Dart pushes under `todo_<id>` (see
 * `lib/src/widget/widget_payload.dart`): the header names the library
 * and the true open count, the rows show due-soonest first. Header taps
 * open that library's Todo tab through [WidgetBridge]; row taps complete
 * the task through the background toggle; the widget never reads
 * todo.txt itself.
 *
 * The rows are a SCROLLABLE `RemoteCollection` bound to
 * [TodoWidgetService]: the launcher binds the service on demand when it
 * renders the collection (placement is not required — an already-placed
 * widget gets its rows after the next update) and asks the factory for
 * exactly the rows the (resized) widget can show, so a library with more
 * open tasks than fit scrolls. The payload caps the row count upstream
 * (a payload-size guard); the header count comes from the payload's
 * `total`, so it stays true when the rows are truncated.
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
            // Force the host to re-query the rows after the payload
            // landed: a tap-to-complete re-pushes a changed payload while
            // the widget is already bound, and the host otherwise keeps
            // showing the cached rows.
            appWidgetManager.notifyAppWidgetViewDataChanged(
                id,
                R.id.widget_todo_rows,
            )
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

        // The header count names the TRUE open total (payload `total`),
        // so it stays right when the row cap truncates the payload.
        val rowCount = rows?.length() ?: 0
        val total = parsed?.optInt("total", rowCount) ?: rowCount
        val views = RemoteViews(context.packageName, R.layout.widget_todo)
        views.setTextViewText(R.id.widget_todo_title, titleFor(library))
        views.setTextViewText(R.id.widget_todo_count, countFor(total))
        views.setTextViewText(
            R.id.widget_todo_empty,
            if (payload == null) "Open Niman to load todos" else "No open tasks",
        )
        // The rows scroll: the launcher binds TodoWidgetService on
        // demand and the factory serves the payload's rows (row taps
        // and the checked/unchecked rendering live there). The instance
        // id rides with the bind as EXTRA_APPWIDGET_ID, so each
        // instance gets its own factory.
        //
        // The two-argument overload targets the ListView by its layout
        // id: the deprecated three-argument overload's first parameter
        // is the appWidgetId (ignored) and its second the view id, so
        // passing (viewId, appWidgetId) binds the service to a view
        // that does not exist and the rows never render.
        views.setEmptyView(R.id.widget_todo_rows, R.id.widget_todo_empty)
        @Suppress("DEPRECATION") // RemoteCollectionItems is static-only
        views.setRemoteAdapter(
            R.id.widget_todo_rows,
            Intent(context, TodoWidgetService::class.java)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id),
        )

        val open = openTodo(context, id, library)
        views.setOnClickPendingIntent(R.id.widget_todo_header, open)
        views.setOnClickPendingIntent(R.id.widget_todo_empty, open)
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

    // [total] is the exact open count (payload `total`), so no "more
    // than this" suffix is needed even when the rows are truncated.
    private fun countFor(total: Int): String {
        if (total == 0) return ""
        return "$total open"
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
