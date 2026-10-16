package dev.niman.niman

import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetBackgroundWorker
import io.flutter.FlutterInjector

/**
 * Hands a `niman://` URI to the headless Dart callback (issue 6, #1018).
 *
 * The Flutter loader is started first, exactly as the plugin's own
 * receiver does (#180). The worker builds its engine from
 * `flutterLoader().findAppBundlePath()`, which needs the loader
 * initialized; without these two calls the engine throws, the work fails
 * and nothing happens at all — while the app is running the loader
 * happens to be up already, which is why the taps looked half-broken
 * rather than broken. Every native caller of the worker (the row taps,
 * the day-change receiver) goes through here, so each does the plugin's
 * work.
 */
object WidgetBackgroundWork {
    /** Starts the loader and enqueues [intent]'s data for the Dart callback. */
    fun enqueue(context: Context, intent: Intent) {
        val ready = runCatching {
            val flutterLoader = FlutterInjector.instance().flutterLoader()
            flutterLoader.startInitialization(context)
            flutterLoader.ensureInitializationComplete(context, null)
        }
        // Logged rather than swallowed: a call that cannot start an
        // engine is the failure this exists to make visible (#180).
        ready.exceptionOrNull()?.let {
            WidgetDebugLog.log(context, "widget background: flutter loader failed: $it")
        }
        HomeWidgetBackgroundWorker.enqueueWork(context, intent)
    }
}
