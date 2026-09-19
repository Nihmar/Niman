package dev.niman.niman

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetBackgroundWorker
import io.flutter.FlutterInjector

/**
 * The tap entrypoint for the widget row collections (issue 6).
 *
 * The row tap hands its `niman://` URI to the template as a fill-in; this
 * receiver logs that URI to the durable widget debug log (the headless
 * Dart engine's own log lines live in the background isolate's memory
 * buffer and never reach the exported debug log, so a tap that parses to
 * nothing would otherwise be invisible) and then delegates to the
 * plugin's worker, which runs the Dart toggle. The widget never reads
 * the note file itself.
 *
 * The Flutter loader is started first, exactly as the plugin's own
 * receiver does (#180). The worker builds its engine from
 * `flutterLoader().findAppBundlePath()`, which needs the loader
 * initialized; without these two calls the engine throws, the work fails
 * and the tap does nothing at all — while the app is running the loader
 * happens to be up already, which is why the taps looked half-broken
 * rather than broken. This receiver took the plugin's place for the sake
 * of that log line, so it has to do the plugin's work too.
 */
class WidgetTapReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetDebugLog.log(context, "widget row tap: ${intent.data}")
        val ready = runCatching {
            val flutterLoader = FlutterInjector.instance().flutterLoader()
            flutterLoader.startInitialization(context)
            flutterLoader.ensureInitializationComplete(context, null)
        }
        // Logged rather than swallowed: a tap that cannot start an engine
        // is the failure this receiver exists to make visible (#180).
        ready.exceptionOrNull()?.let {
            WidgetDebugLog.log(context, "widget tap: flutter loader failed: $it")
        }
        HomeWidgetBackgroundWorker.enqueueWork(context, intent)
    }
}
