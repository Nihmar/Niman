package dev.niman.niman

import android.app.Activity
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The launcher quick actions (T-SC-01/02): the long-press menu on the app
 * icon.
 *
 * Dart owns the set and its labels and publishes them through
 * [CHANNEL]; each shortcut carries only its id back, and the Dart side
 * runs the matching in-app flow. A tap that starts the app cold is kept
 * here until Dart asks for it, because the engine is not running yet when
 * the intent arrives.
 */
class ShortcutsBridge(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/shortcuts"

        /** The intent action every published shortcut carries. */
        const val ACTION = "dev.niman.niman.SHORTCUT"

        /** The intent extra holding the shortcut id. */
        const val EXTRA_ID = "shortcut_id"
    }

    private var channel: MethodChannel? = null
    private var launchAction: String? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@ShortcutsBridge)
        }
    }

    /** Drops the channel (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /**
     * Takes the shortcut id out of [intent].
     *
     * With [running] false (a cold start, where Dart is not listening
     * yet) the id waits for `consumeLaunchAction`; otherwise it is
     * delivered straight away. The extra is removed either way, so the
     * action is not replayed when the activity is recreated with the same
     * intent (a rotation, a process restore).
     */
    fun handleIntent(intent: Intent?, running: Boolean) {
        if (intent == null || intent.action != ACTION) return
        val id = intent.getStringExtra(EXTRA_ID) ?: return
        intent.removeExtra(EXTRA_ID)
        if (running) {
            channel?.invokeMethod("shortcut", id)
        } else {
            launchAction = id
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "publish" -> {
                @Suppress("UNCHECKED_CAST")
                val specs = call.arguments as? List<Map<String, String>>
                publish(specs ?: emptyList())
                result.success(null)
            }
            "consumeLaunchAction" -> {
                result.success(launchAction)
                launchAction = null
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Replaces the dynamic shortcut set with [specs], in order.
     *
     * Trimmed to what the launcher accepts: over the cap
     * `setDynamicShortcuts` throws and the app would lose every shortcut
     * rather than the last one.
     */
    private fun publish(specs: List<Map<String, String>>) {
        val manager = activity.getSystemService(ShortcutManager::class.java)
            ?: return
        val shortcuts = specs
            .take(manager.maxShortcutCountPerActivity)
            .mapIndexedNotNull { rank, spec -> build(spec, rank) }
        manager.dynamicShortcuts = shortcuts
    }

    private fun build(spec: Map<String, String>, rank: Int): ShortcutInfo? {
        val id = spec["id"] ?: return null
        val label = spec["label"] ?: return null
        val icon = iconFor(id) ?: return null
        val intent = Intent(activity, MainActivity::class.java)
            .setAction(ACTION)
            .putExtra(EXTRA_ID, id)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return ShortcutInfo.Builder(activity, id)
            .setShortLabel(label)
            .setLongLabel(label)
            .setRank(rank)
            .setIcon(Icon.createWithResource(activity, icon))
            .setIntent(intent)
            .build()
    }

    /**
     * The drawable for [id].
     *
     * Referenced directly rather than looked up by name: R8 resource
     * shrinking (on in release builds) strips a drawable no code points
     * at, which is how the reminder icon once shipped as a white block.
     */
    private fun iconFor(id: String): Int? = when (id) {
        "quick_note" -> R.drawable.ic_shortcut_quick_note
        "new_todo" -> R.drawable.ic_shortcut_new_todo
        "new_note" -> R.drawable.ic_shortcut_new_note
        "new_list" -> R.drawable.ic_shortcut_new_list
        else -> null
    }
}
