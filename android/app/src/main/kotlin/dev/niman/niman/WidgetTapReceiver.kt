package dev.niman.niman

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * The tap entrypoint for the widget row collections (issue 6).
 *
 * The row tap hands its `niman://` URI to the template as a fill-in; this
 * receiver logs that URI to the durable widget debug log (the headless
 * Dart engine's own log lines live in the background isolate's memory
 * buffer and never reach the exported debug log, so a tap that parses to
 * nothing would otherwise be invisible) and then delegates to the
 * plugin's worker through [WidgetBackgroundWork], which runs the Dart
 * toggle. The widget never reads the note file itself.
 *
 * The Flutter loader is started first, exactly as the plugin's own
 * receiver does (#180): this receiver took the plugin's place for the
 * sake of that log line, so it has to do the plugin's work too.
 */
class WidgetTapReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetDebugLog.log(context, "widget row tap: ${intent.data}")
        WidgetBackgroundWork.enqueue(context, intent)
    }
}
