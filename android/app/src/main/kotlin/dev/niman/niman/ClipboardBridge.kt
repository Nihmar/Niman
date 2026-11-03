package dev.niman.niman

import android.content.ClipboardManager
import android.content.Context
import android.os.Handler
import android.os.Looper
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
 *
 * `readFiles` answers the paths of the files on the clipboard (#1249):
 * each `content://` or `file://` item copied into the app's cache under
 * its own name ([ContentFiles]), off the main thread, since only a path
 * can be copied on into the library.
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
            "readFiles" -> readFiles(result)
            else -> result.notImplemented()
        }
    }

    /** The clip's file items, copied into the cache, as their paths. */
    private fun readFiles(result: MethodChannel.Result) {
        val manager =
            context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        val clip = manager?.primaryClip
        val uris = clip?.let { c ->
            (0 until c.itemCount).mapNotNull { c.getItemAt(it).uri }
        }.orEmpty()
        if (uris.isEmpty()) {
            result.success(emptyList<String>())
            return
        }
        val main = Handler(Looper.getMainLooper())
        Thread {
            val paths = ContentFiles.copyToCache(context, uris, "clipboard")
            main.post { result.success(paths) }
        }.start()
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
