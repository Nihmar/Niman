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
 * The rows render in-process from 20 STATIC layout slots (one per
 * payload row; the 20-row cap lives in Dart): the launcher reuses the
 * inflated tree between updates, so a provider `addView` would
 * accumulate a copy of the rows on every refresh. Each refresh re-fills
 * the slots (text, color, visibility) instead, which is what the layout
 * was made for; a remote views service would need the LAUNCHER to bind
 * it cross-process, and that bind only happens when the widget is
 * placed, so an already-placed widget could never recover.
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

        // The rows fill the 20 static slots (Dart caps the payload at
        // 20 rows upstream): re-filling works on the tree the launcher
        // keeps between updates; addView would not.
        val rowCount = rows?.length() ?: 0
        for (i in 0 until rowIds.size) {
            val row = if (i < rowCount) rows?.optJSONObject(i) else null
            views.setViewVisibility(
                rowIds[i],
                if (row == null) View.GONE else View.VISIBLE,
            )
            if (row != null) fillRow(views, context, id, library, i, row)
        }
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
     * Fills slot [slot] with [row] (round 2, R2): tapping anywhere on the
     * row completes the task without opening the app. The per-row
     * broadcast carries the fill-in URI the background worker forwards
     * to Dart.
     */
    private fun fillRow(
        views: RemoteViews,
        context: Context,
        id: Int,
        library: String,
        slot: Int,
        row: JSONObject,
    ) {
        val meta = listOfNotNull(
            row.optString("priority", "").takeIf { it.isNotEmpty() }?.let { "($it)" },
            row.optString("due", "").takeIf { it.isNotEmpty() },
        ).joinToString(" · ")
        views.setViewVisibility(
            rowMetaIds[slot],
            if (meta.isEmpty()) View.GONE else View.VISIBLE,
        )
        views.setTextViewText(rowMetaIds[slot], meta)
        views.setTextViewText(rowTextIds[slot], row.optString("text", ""))
        val fillIn = Uri.Builder()
            .scheme("niman")
            .authority("todo-toggle")
            .appendQueryParameter("id", id.toString())
            .appendQueryParameter("library", library)
            .appendQueryParameter("line", row.optInt("line", -1).toString())
            .build()
        // Every rendered row is open by definition, so the unchecked
        // CheckBox default is already right. RemoteViews forbids
        // CheckBox.setChecked(boolean) and would drop the whole view.
        // The whole row toggles (checkbox included); one broadcast
        // per row, the URI in its data.
        val toggle = HomeWidgetBackgroundIntent.getBroadcast(context, fillIn)
        views.setOnClickPendingIntent(rowIds[slot], toggle)
    }

    companion object {
        // The 20 static row slots of R.layout.widget_todo (kept in sync
        // by hand; the cap is widgetTodoLimit in Dart).
        val rowIds = intArrayOf(
            R.id.widget_todo_row_0, R.id.widget_todo_row_1, R.id.widget_todo_row_2,
            R.id.widget_todo_row_3, R.id.widget_todo_row_4, R.id.widget_todo_row_5,
            R.id.widget_todo_row_6, R.id.widget_todo_row_7, R.id.widget_todo_row_8,
            R.id.widget_todo_row_9, R.id.widget_todo_row_10, R.id.widget_todo_row_11,
            R.id.widget_todo_row_12, R.id.widget_todo_row_13, R.id.widget_todo_row_14,
            R.id.widget_todo_row_15, R.id.widget_todo_row_16, R.id.widget_todo_row_17,
            R.id.widget_todo_row_18, R.id.widget_todo_row_19,
        )
        val rowMetaIds = intArrayOf(
            R.id.widget_todo_row_meta_0, R.id.widget_todo_row_meta_1, R.id.widget_todo_row_meta_2,
            R.id.widget_todo_row_meta_3, R.id.widget_todo_row_meta_4, R.id.widget_todo_row_meta_5,
            R.id.widget_todo_row_meta_6, R.id.widget_todo_row_meta_7, R.id.widget_todo_row_meta_8,
            R.id.widget_todo_row_meta_9, R.id.widget_todo_row_meta_10, R.id.widget_todo_row_meta_11,
            R.id.widget_todo_row_meta_12, R.id.widget_todo_row_meta_13, R.id.widget_todo_row_meta_14,
            R.id.widget_todo_row_meta_15, R.id.widget_todo_row_meta_16, R.id.widget_todo_row_meta_17,
            R.id.widget_todo_row_meta_18, R.id.widget_todo_row_meta_19,
        )
        val rowTextIds = intArrayOf(
            R.id.widget_todo_row_text_0, R.id.widget_todo_row_text_1, R.id.widget_todo_row_text_2,
            R.id.widget_todo_row_text_3, R.id.widget_todo_row_text_4, R.id.widget_todo_row_text_5,
            R.id.widget_todo_row_text_6, R.id.widget_todo_row_text_7, R.id.widget_todo_row_text_8,
            R.id.widget_todo_row_text_9, R.id.widget_todo_row_text_10, R.id.widget_todo_row_text_11,
            R.id.widget_todo_row_text_12, R.id.widget_todo_row_text_13, R.id.widget_todo_row_text_14,
            R.id.widget_todo_row_text_15, R.id.widget_todo_row_text_16, R.id.widget_todo_row_text_17,
            R.id.widget_todo_row_text_18, R.id.widget_todo_row_text_19,
        )
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
