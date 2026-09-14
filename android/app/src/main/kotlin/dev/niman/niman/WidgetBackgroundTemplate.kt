package dev.niman.niman

import android.app.PendingIntent
import android.content.Context
import android.content.Intent

/**
 * The tap template for the widget row collections (issue 6).
 *
 * The rows hand their `niman://` URI to this template through
 * `setOnClickFillInIntent`; the merged broadcast feeds the headless Dart
 * engine that does the toggle. The template must be MUTABLE so the
 * fill-in URI actually merges: an IMMUTABLE template (like
 * `HomeWidgetBackgroundIntent.getBroadcast`) drops the row URI on
 * API 31+, the worker then receives an empty string, Dart parses no
 * target, and the tap silently does nothing. minSdk is 35, so
 * FLAG_MUTABLE needs no version gate.
 *
 * The broadcast lands on [WidgetTapReceiver] (which logs the URI, then
 * delegates to the plugin worker) instead of the plugin's receiver
 * directly, so every tap leaves a line in the exported debug log.
 */
object WidgetBackgroundTemplate {
    /** The background-tap action the plugin's worker listens for. */
    const val ACTION = "es.antonborri.home_widget.action.BACKGROUND"

    fun intent(context: Context): PendingIntent {
        val intent = Intent(context, WidgetTapReceiver::class.java)
            .setAction(ACTION)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }
}
