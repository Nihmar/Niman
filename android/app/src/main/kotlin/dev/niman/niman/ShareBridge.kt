package dev.niman.niman

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

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
 *
 * Both callers are UI-thread callbacks — `configureFlutterEngine` and
 * `onNewIntent` in MainActivity — and the copy is the whole shared file:
 * a Notion export (#25) or a long PDF is a second or more of I/O, which
 * on that thread froze the app and drew an ANR (#386). So a copy runs on
 * the copy thread ([copies]) and comes back to the UI thread to be
 * delivered; only bookkeeping — the channel, what waits for Dart, what
 * is still copying — stays on the thread the intents arrive on.
 */
class ShareBridge(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/share"

        /** The cache subfolder the copies live in. */
        private const val CACHE_DIR = "niman-share"

        /** The copy thread's name, for a thread dump. */
        private const val COPY_THREAD = "niman-share-copy"
    }

    /** Where a finished copy goes back to (a copy ends off this thread). */
    private val main = Handler(Looper.getMainLooper())

    private var channel: MethodChannel? = null
    private val pending = ArrayDeque<Map<String, String>>()

    /** Shares handed to the copy thread that are not delivered yet. */
    private var copiesInFlight = 0

    /** Dart's `consumeLaunchRequest` answer, held while a copy runs. */
    private var launchResult: MethodChannel.Result? = null

    /** The copy thread. Started, read and replaced on the UI thread. */
    private var copies: ExecutorService? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@ShareBridge)
        }
        // Copies from an earlier run: Dart either imported them or never
        // came back for them, and either way it does not need them now.
        // A directory's worth of deletes is I/O too, and the one thread
        // keeps them ahead of any share that arrives next.
        copies().execute { shareDir().listFiles()?.forEach { it.delete() } }
    }

    /** Drops the channel and the copy thread (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        // A copy already running finishes; its payload goes nowhere, as
        // the channel it would be pushed to is gone.
        copies?.shutdown()
        copies = null
    }

    /**
     * Takes the share out of [intent].
     *
     * With [running] false (a cold start, where Dart is not listening yet)
     * the payload waits for `consumeLaunchRequest`; otherwise it is
     * delivered straight away. The action is cleared either way, so a
     * recreated activity handed the same intent does not replay a share
     * that was already taken.
     *
     * The text half is an intent extra, which is no I/O, so it is taken
     * and delivered here. A file is copied on the copy thread and
     * delivered when the copy is done, so this returns at once and the UI
     * thread never waits on the bytes; a share that carries both keeps the
     * file and falls back to the text only when the copy fails or the
     * share is over the cap.
     */
    fun handleIntent(intent: Intent?, running: Boolean) {
        if (intent == null) return
        val action = intent.action
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_VIEW) return
        val isSend = action == Intent.ACTION_SEND
        val uri = if (isSend) streamOf(intent) else intent.data
        val text = if (isSend) textPayload(intent) else null
        intent.action = null
        if (uri == null) {
            // Text on its own, or an `ACTION_VIEW` with nothing to open.
            if (text != null) {
                deliver(text, running)
                answerLaunch()
            }
            return
        }
        copiesInFlight++
        copies().execute {
            // A share that cannot be read — a provider that throws, a
            // refused share — is delivered as its text, if it carried
            // any. The copy is accounted for however it went, so Dart is
            // answered rather than left waiting on a payload.
            val payload = try {
                filePayload(uri) ?: text
            } catch (e: Exception) {
                text
            }
            main.post { copied(payload, running) }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "consumeLaunchRequest" -> launchRequest(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Answers the `consumeLaunchRequest` call with the share a cold start
     * carried, once.
     *
     * A share still being copied is not in [pending] yet, so the answer
     * is held until it lands ([answerLaunch]) rather than answered null,
     * which would drop it: Dart asks as soon as it is up, well before a
     * large copy is done.
     */
    private fun launchRequest(result: MethodChannel.Result) {
        val payload = pending.removeFirstOrNull()
        if (payload != null || copiesInFlight == 0) {
            result.success(payload)
            return
        }
        if (launchResult != null) {
            // One cold start, one share: a second caller is answered
            // nothing rather than the first caller's share.
            result.success(null)
            return
        }
        launchResult = result
    }

    /** A copy is done: hands its [payload] over, if it produced one. */
    private fun copied(payload: Map<String, String>?, running: Boolean) {
        copiesInFlight--
        if (payload != null) deliver(payload, running)
        answerLaunch()
    }

    /** Hands [payload] to Dart: pushed when it is listening, else kept. */
    private fun deliver(payload: Map<String, String>, running: Boolean) {
        if (running) {
            channel?.invokeMethod("share", payload)
        } else {
            pending.add(payload)
        }
    }

    /**
     * Answers a waiting `consumeLaunchRequest`, once nothing is copying:
     * the launch share is in [pending] by then, or it never arrived (it
     * was refused, or could not be read) and null is the answer.
     */
    private fun answerLaunch() {
        if (copiesInFlight > 0) return
        val result = launchResult ?: return
        launchResult = null
        result.success(pending.removeFirstOrNull())
    }

    /**
     * The thread shared files are copied on, started on first use.
     *
     * One at a time and in the order handed over: the deletes [attach]
     * queues must run before a copy that follows them, or they would
     * delete the copy Dart is about to import. A daemon thread, so a copy
     * in flight never holds the process up. Started again by a bridge
     * attached after [detach], so a second engine still copies here.
     */
    private fun copies(): ExecutorService {
        val current = copies
        if (current != null && !current.isShutdown) return current
        val started = Executors.newSingleThreadExecutor { task ->
            Thread(task, COPY_THREAD).apply { isDaemon = true }
        }
        copies = started
        return started
    }

    /**
     * The text half of a share, with its subject: a browser sharing a page
     * puts the page's title there (#531), which the address alone in the
     * text does not carry.
     */
    private fun textPayload(intent: Intent): Map<String, String>? {
        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        if (text.isNullOrBlank()) return null
        val payload = mutableMapOf("type" to "text", "text" to text)
        val subject = intent.getCharSequenceExtra(Intent.EXTRA_SUBJECT)
        if (!subject.isNullOrBlank()) payload["subject"] = subject.toString()
        return payload
    }

    /** The file payload [uri] becomes, or null when it cannot be one. */
    private fun filePayload(uri: Uri): Map<String, String>? {
        val (name, reported) = metadataOf(uri)
        // A provider that reports the size answers the cap without a byte
        // read; the copy is the limit that holds, reported size or not.
        if (reported != null && reported > ShareCopy.MAX_BYTES) return null
        val dir = shareDir()
        if (!dir.exists() && !dir.mkdirs()) return null
        // The timestamp keeps two shares of one name apart; the note is
        // named from `name`, which travels with the payload.
        val copy = File(dir, "${System.currentTimeMillis()}-$name")
        return try {
            val input = activity.contentResolver.openInputStream(uri)
                ?: return null
            input.use { source ->
                when (ShareCopy.read(source, copy)) {
                    // Over the cap: ShareCopy deleted the half a copy, and
                    // the caller falls back to the share's text, if any.
                    ShareCopy.Result.TooLarge -> null
                    is ShareCopy.Result.Copied -> mapOf(
                        "type" to "file",
                        "path" to copy.path,
                        "name" to name,
                    )
                }
            }
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
     * The name [uri] is known by and the size its provider reports (null
     * when it reports none, or reports it as unknown).
     *
     * Only the final component of the name is kept: a provider may answer
     * a display name with a path in it, and the copy stays in the cache.
     */
    private fun metadataOf(uri: Uri): Pair<String, Long?> {
        var name: String? = null
        var size: Long? = null
        if (uri.scheme == "content") {
            val columns = arrayOf(
                OpenableColumns.DISPLAY_NAME,
                OpenableColumns.SIZE,
            )
            activity.contentResolver.query(uri, columns, null, null, null)
                ?.use { cursor ->
                    if (!cursor.moveToFirst()) return@use
                    val nameIndex = cursor.getColumnIndex(
                        OpenableColumns.DISPLAY_NAME,
                    )
                    if (nameIndex >= 0) name = cursor.getString(nameIndex)
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                        // -1 is the "size unknown" a provider answers
                        // with, and no measurement to cap against.
                        size = cursor.getLong(sizeIndex).takeIf { it >= 0 }
                    }
                }
        }
        val fallback = uri.lastPathSegment ?: "Shared.md"
        return sanitize(name ?: fallback) to size
    }

    private fun sanitize(name: String): String {
        val base = name.substringAfterLast('/').substringAfterLast('\\')
        return base.ifBlank { "Shared.md" }
    }

    private fun shareDir(): File = File(activity.cacheDir, CACHE_DIR)
}
