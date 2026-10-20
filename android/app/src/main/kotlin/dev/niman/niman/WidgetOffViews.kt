package dev.niman.niman

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Draws a widget whose feature is off (#1109, Phone-4): the library's
 * name, the sentence, and a button that opens Settings → Features.
 *
 * Shared by the Todos, Study and Note providers; each hands over the
 * payload's [WidgetOff] and its own fallback title. The button and the
 * sentence open the app on the widget's library through
 * [WidgetBridge.featuresIntent]; nothing here reads or writes data.
 */
object WidgetOffViews {
    fun build(
        context: Context,
        id: Int,
        library: String,
        off: WidgetOff,
        payload: String?,
        titleFallback: String,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_off)
        views.setTextViewText(R.id.widget_off_title, WidgetOff.titleFor(library, titleFallback))
        views.setTextViewText(R.id.widget_off_text, off.text)
        views.setTextViewText(R.id.widget_off_action, off.action)
        // The app theme rides in the payload: without it the layout
        // defaults stand.
        WidgetTheme.fromPayload(payload)?.let { theme ->
            views.setInt(R.id.widget_off_root, "setBackgroundColor", theme.background)
            views.setTextColor(R.id.widget_off_title, theme.primary)
            views.setTextColor(R.id.widget_off_text, theme.secondary)
            views.setTextColor(R.id.widget_off_action, theme.primary)
        }
        val open = openFeatures(context, id, library)
        views.setOnClickPendingIntent(R.id.widget_off_action, open)
        views.setOnClickPendingIntent(R.id.widget_off_text, open)
        return views
    }

    private fun openFeatures(context: Context, id: Int, library: String): PendingIntent {
        val intent = if (library.isEmpty()) {
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        } else {
            WidgetBridge.featuresIntent(context, library)
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
