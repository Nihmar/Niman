package dev.niman.niman

import android.content.ClipboardManager
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The clipboard's HTML for Paste as Markdown (#531).
 *
 * A browser copies a selection as a [android.content.ClipData] item with
 * both its text and its HTML; Flutter's own clipboard only reads the text.
 * `readHtml` answers the HTML of the clip's items, or null when none has
 * any. Android's clipboard carries no page address, so there is no
 * `source` here, as there is on the desktop.
 */
class ClipboardBridge(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        /** The Dart-facing channel, the same name the GTK runner uses. */
        const val CHANNEL = "niman/clipboard"
    }

    private var channel: MethodChannel? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@ClipboardBridge)
        }
    }

    /** Drops the channel (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "readHtml" -> result.success(readHtml())
            else -> result.notImplemented()
        }
    }

    /** The clip's HTML as `{html}`, or null when it holds none. */
    private fun readHtml(): Map<String, Any?>? {
        val manager =
            context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                ?: return null
        val clip = manager.primaryClip ?: return null
        val html = (0 until clip.itemCount)
            .mapNotNull { clip.getItemAt(it).htmlText }
            .filter { it.isNotBlank() }
            .joinToString("\n")
        if (html.isEmpty()) return null
        return mapOf("html" to html)
    }
}
