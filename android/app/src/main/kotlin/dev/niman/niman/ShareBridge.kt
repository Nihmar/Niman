package dev.niman.niman

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Share-in (#40): what another app hands Niman through the system share
 * sheet ("Share to Niman") or "Open with".
 *
 * Two shapes arrive. `ACTION_SEND` with `EXTRA_TEXT` is text, which Dart
 * puts at the end of the quick note. `ACTION_SEND` with `EXTRA_STREAM`, or
 * `ACTION_VIEW` on a `.md`, is a file — and Android hands it as a
 * `content://` URI, which no file API can read or keep. The bridge reads
 * the bytes itself and writes a copy into the app cache; Dart imports that
 * copy and deletes it. One shape could not be forwarded as a path, the
 * other is a string, so both go over the channel as a map with a `type`.
 *
 * A share that starts the app cold is kept here until Dart asks for it,
 * because the engine is not listening when the intent arrives; a share
 * that reaches an already-running app is pushed straight away. Dart
 * buffers what arrives before a shell (see `share_in.dart`), so a share
 * against the library picker is not lost either.
 */
class ShareBridge(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/share"

        /** The cache subfolder the copies live in. */
        private const val CACHE_DIR = "niman-share"
    }

    private var channel: MethodChannel? = null
    private val pending = ArrayDeque<Map<String, String>>()

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@ShareBridge)
        }
        // Copies from an earlier run: Dart either imported them or never
        // came back for them, and either way it does not need them now.
        shareDir().listFiles()?.forEach { it.delete() }
    }

    /** Drops the channel (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    /**
     * Takes the share out of [intent].
     *
     * With [running] false (a cold start, where Dart is not listening yet)
     * the payload waits for `consumeLaunchRequest`; otherwise it is
     * delivered straight away. The action is cleared either way, so a
     * recreated activity handed the same intent does not replay a share
     * that was already taken.
     */
    fun handleIntent(intent: Intent?, running: Boolean) {
        if (intent == null) return
        val action = intent.action
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_VIEW) return
        val payload = payloadOf(intent) ?: return
        intent.action = null
        if (running) {
            channel?.invokeMethod("share", payload)
        } else {
            pending.add(payload)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "consumeLaunchRequest" -> result.success(pending.removeFirstOrNull())
            else -> result.notImplemented()
        }
    }

    /** The share [intent] carries, or null when it carries none. */
    private fun payloadOf(intent: Intent): Map<String, String>? {
        return when (intent.action) {
            Intent.ACTION_SEND -> {
                // A stream wins over the text: an app that shares a file
                // usually attaches a body line as well, and the file is
                // what the user meant.
                val stream = streamOf(intent)
                if (stream != null) filePayload(stream) ?: textPayload(intent)
                else textPayload(intent)
            }
            Intent.ACTION_VIEW -> intent.data?.let(::filePayload)
            else -> null
        }
    }

    private fun textPayload(intent: Intent): Map<String, String>? {
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        if (text.isNullOrBlank()) return null
        return mapOf("type" to "text", "text" to text)
    }

    private fun filePayload(uri: Uri): Map<String, String>? {
        val name = displayName(uri)
        val dir = shareDir()
        if (!dir.exists() && !dir.mkdirs()) return null
        // The timestamp keeps two shares of one name apart; the note is
        // named from `name`, which travels with the payload.
        val copy = File(dir, "${System.currentTimeMillis()}-$name")
        return try {
            val input = activity.contentResolver.openInputStream(uri)
                ?: return null
            input.use { source ->
                copy.outputStream().use { target -> source.copyTo(target) }
            }
            mapOf("type" to "file", "path" to copy.path, "name" to name)
        } catch (e: Exception) {
            copy.delete()
            null
        }
    }

    /** The stream an `ACTION_SEND` carries, if any. */
    @Suppress("DEPRECATION")
    private fun streamOf(intent: Intent): Uri? {
        return intent.getParcelableExtra(Intent.EXTRA_STREAM)
    }

    /**
     * The name [uri] is known by: the provider's display name when it
     * answers one, else the last path segment.
     *
     * Only the final component is kept — a provider may answer a display
     * name with a path in it, and the copy must stay inside the cache.
     */
    private fun displayName(uri: Uri): String {
        if (uri.scheme == "content") {
            val columns = arrayOf(OpenableColumns.DISPLAY_NAME)
            activity.contentResolver.query(uri, columns, null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(
                            OpenableColumns.DISPLAY_NAME,
                        )
                        if (index >= 0) {
                            cursor.getString(index)?.let { return sanitize(it) }
                        }
                    }
                }
        }
        return sanitize(uri.lastPathSegment ?: "Shared.md")
    }

    private fun sanitize(name: String): String {
        val base = name.substringAfterLast('/').substringAfterLast('\\')
        return base.ifBlank { "Shared.md" }
    }

    private fun shareDir(): File = File(activity.cacheDir, CACHE_DIR)
}
