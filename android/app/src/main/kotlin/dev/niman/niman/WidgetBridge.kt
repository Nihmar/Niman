package dev.niman.niman

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Home-screen widget taps (issue 6): what a widget asks the app to open.
 *
 * A tap only carries plain data — the library, and the tab or note inside
 * it — as intent extras. Dart owns the meaning and runs the matching
 * in-app flow. A tap that starts the app cold is kept here until Dart asks
 * for it, because the engine is not running yet when the intent arrives.
 */
class WidgetBridge(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/widgets"

        /** Opens the Todo tab of the carrying library. */
        const val ACTION_OPEN_TODO = "dev.niman.niman.OPEN_TODO"

        /** Opens one note of the carrying library in the editor. */
        const val ACTION_OPEN_NOTE = "dev.niman.niman.OPEN_NOTE"

        /** The intent extra holding the absolute library root. */
        const val EXTRA_LIBRARY = "library_path"

        /** The intent extra holding the library-relative note path. */
        const val EXTRA_NOTE = "note_path"

        /** The intent extra holding the optional heading anchor. */
        const val EXTRA_ANCHOR = "anchor"
    }

    private var channel: MethodChannel? = null
    private var launchTarget: Map<String, String>? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@WidgetBridge)
        }
    }

    /** Drops the channel (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /**
     * Takes the widget target out of [intent].
     *
     * With [running] false (a cold start, where Dart is not listening
     * yet) the target waits for `consumeLaunchTarget`; otherwise it is
     * delivered straight away. The extras are removed either way, so the
     * tap is not replayed when the activity is recreated with the same
     * intent (a rotation, a process restore).
     */
    fun handleIntent(intent: Intent?, running: Boolean) {
        val target = targetOf(intent) ?: return
        clearExtras(intent!!)
        if (running) {
            channel?.invokeMethod("target", target)
        } else {
            launchTarget = target
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "consumeLaunchTarget" -> {
                result.success(launchTarget)
                launchTarget = null
            }
            "getWidgetIds" -> {
                result.success(widgetIds(call.argument<String>("provider")))
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Builds the pending intent a widget row taps.
     *
     * Explicit (component-set), so no manifest filter is needed; the
     * extras carry the target the bridge reads back in [handleIntent].
     */
    fun todoIntent(libraryPath: String): Intent {
        return Intent(activity, MainActivity::class.java)
            .setAction(ACTION_OPEN_TODO)
            .putExtra(EXTRA_LIBRARY, libraryPath)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }

    /** Builds the pending intent a pinned note taps. */
    fun noteIntent(libraryPath: String, notePath: String, anchor: String?): Intent {
        val intent = Intent(activity, MainActivity::class.java)
            .setAction(ACTION_OPEN_NOTE)
            .putExtra(EXTRA_LIBRARY, libraryPath)
            .putExtra(EXTRA_NOTE, notePath)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (anchor != null) intent.putExtra(EXTRA_ANCHOR, anchor)
        return intent
    }

    /**
     * The placed instances of [provider] (a `TodoWidgetProvider` class
     * name, e.g.): the launcher owns the ids, so Dart asks the host
     * instead of tracking them. Empty when the provider is unknown.
     */
    private fun widgetIds(provider: String?): List<Int> {
        if (provider.isNullOrEmpty()) return emptyList()
        val manager = activity.getSystemService(AppWidgetManager::class.java)
            ?: return emptyList()
        val component = ComponentName(activity, "${activity.packageName}.$provider")
        return manager.getAppWidgetIds(component).toList()
    }

    private fun targetOf(intent: Intent?): Map<String, String>? {
        if (intent == null) return null
        val library = intent.getStringExtra(EXTRA_LIBRARY)
        if (library.isNullOrEmpty()) return null
        return when (intent.action) {
            ACTION_OPEN_TODO -> mapOf(
                "kind" to "todo",
                "libraryPath" to library,
            )
            ACTION_OPEN_NOTE -> {
                val note = intent.getStringExtra(EXTRA_NOTE)
                if (note.isNullOrEmpty()) return null
                val target = mutableMapOf(
                    "kind" to "note",
                    "libraryPath" to library,
                    "notePath" to note,
                )
                intent.getStringExtra(EXTRA_ANCHOR)?.let { anchor ->
                    if (anchor.isNotEmpty()) target["anchor"] = anchor
                }
                target
            }
            else -> null
        }
    }

    private fun clearExtras(intent: Intent) {
        intent.removeExtra(EXTRA_LIBRARY)
        intent.removeExtra(EXTRA_NOTE)
        intent.removeExtra(EXTRA_ANCHOR)
    }
}
