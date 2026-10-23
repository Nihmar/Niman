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
 * The Niman Study home-screen widget (#533, mockup P8).
 *
 * Renders the payload Dart pushes under `study_<id>` (see
 * `lib/src/widget/study_widget.dart`): the header names the library and
 * the cards to study today, the rows are the decks with cards today,
 * grouped by their `deck:`. A tap on the header opens Study; a tap on a
 * deck opens its note. The widget never reads a deck or `review.json`
 * itself: Dart counts, the provider draws.
 *
 * The rows are a scrollable remote collection bound to
 * [StudyWidgetService], as the todo widget's are.
 */
class StudyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val payload = widgetData.getString("study_$id", null)
            WidgetDebugLog.log(
                context,
                "study update widget $id (payload ${payload?.length ?: 0} chars)",
            )
            val views = viewsFor(context, id, payload)
            val inflateFailure =
                runCatching { views.apply(context, null) }.exceptionOrNull()
            if (inflateFailure != null) {
                WidgetDebugLog.log(
                    context,
                    "study views failed to inflate for widget $id: $inflateFailure",
                )
            }
            appWidgetManager.updateAppWidget(id, views)
            // The host re-queries the rows once the new payload landed.
            appWidgetManager.notifyAppWidgetViewDataChanged(id, R.id.widget_study_rows)
        }
    }

    /** Drops the payloads of removed instances. */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        WidgetDebugLog.log(context, "study deleted: ${appWidgetIds.toList()}")
        super.onDeleted(context, appWidgetIds)
        HomeWidgetPlugin.getData(context).edit().apply {
            for (id in appWidgetIds) remove("study_$id")
        }.apply()
    }

    private fun viewsFor(context: Context, id: Int, payload: String?): RemoteViews {
        val parsed = payload?.let { runCatching { JSONObject(it) }.getOrNull() }
        val library = parsed?.optString("library").orEmpty()
        // The feature is off in this library (#1109): the sentence and the
        // button, no decks.
        WidgetOff.fromJson(parsed)?.let { off ->
            return WidgetOffViews.build(
                context,
                id,
                library,
                off,
                payload,
                context.getString(R.string.widget_study_title_fallback),
            )
        }
        val total = parsed?.optInt("total", 0) ?: 0
        val views = RemoteViews(context.packageName, R.layout.widget_study)
        views.setTextViewText(R.id.widget_study_title, titleFor(context, library))
        views.setTextViewText(
            R.id.widget_study_count,
            if (total == 0) "" else context.getString(R.string.widget_study_count, total),
        )
        views.setTextViewText(
            R.id.widget_study_empty,
            context.getString(
                if (payload == null) R.string.widget_study_empty_loading
                else R.string.widget_study_empty_none,
            ),
        )
        WidgetTheme.fromPayload(payload)?.let { theme ->
            views.setInt(R.id.widget_study_root, "setBackgroundColor", theme.background)
            views.setTextColor(R.id.widget_study_title, theme.primary)
            views.setTextColor(R.id.widget_study_count, theme.secondary)
            views.setTextColor(R.id.widget_study_empty, theme.secondary)
        }
        views.setEmptyView(R.id.widget_study_rows, R.id.widget_study_empty)
        @Suppress("DEPRECATION") // RemoteCollectionItems is static-only
        views.setRemoteAdapter(
            R.id.widget_study_rows,
            WidgetAdapter.intent(context, StudyWidgetService::class.java, WidgetAdapter.STUDY, id),
        )
        // A row hands its deck to this template: the framework drops a
        // click set on a collection child. Mutable, so the fill-in's
        // extras reach the activity.
        views.setPendingIntentTemplate(R.id.widget_study_rows, openDeckTemplate(context, id))
        val open = openStudy(context, id, library)
        views.setOnClickPendingIntent(R.id.widget_study_header, open)
        views.setOnClickPendingIntent(R.id.widget_study_empty, open)
        return views
    }

    private fun titleFor(context: Context, library: String): String {
        val fallback = context.getString(R.string.widget_study_title_fallback)
        if (library.isEmpty()) return fallback
        val base = library.trimEnd('/').substringAfterLast('/').substringAfterLast('\\')
        return base.ifEmpty { fallback }
    }

    private fun openStudy(context: Context, id: Int, library: String): PendingIntent {
        val intent = if (library.isEmpty()) {
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        } else {
            WidgetBridge.studyIntent(context, library)
        } ?: Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun openDeckTemplate(context: Context, id: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(WidgetBridge.ACTION_OPEN_NOTE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or WidgetBackgroundTemplate.mutableFlag(),
        )
    }
}
