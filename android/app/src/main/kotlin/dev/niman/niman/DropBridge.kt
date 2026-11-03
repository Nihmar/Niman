package dev.niman.niman

import android.app.Activity
import android.content.ClipDescription
import android.os.Handler
import android.os.Looper
import android.view.DragEvent
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Files dragged onto Niman from another app (#1250): split screen, a
 * freeform window, Samsung DeX, ChromeOS. Reported over `niman/drop` as the
 * desktop runners report theirs — `dragEntered`, `dragExited`, `drop` with
 * the paths — so the one Dart target (`lib/src/ui/drop_target.dart`) takes
 * them all.
 *
 * The other app hands over `content://` URIs, readable only with the
 * permission the drop grants and only while it is held: each one is
 * copied into the cache under its own name ([ContentFiles]) off the main
 * thread, and the permission let go once the copies are made.
 *
 * A drag that carries only text is not taken: text dragged from another app
 * is not a file, and the editor has no place under the finger to put it.
 */
class DropBridge(private val activity: Activity) : View.OnDragListener {

    companion object {
        /** The Dart-facing channel, the desktop runners' name. */
        const val CHANNEL = "niman/drop"
    }

    private var channel: MethodChannel? = null
    private var view: View? = null
    private val main = Handler(Looper.getMainLooper())

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL)
    }

    /** Takes the drags that come over [target], the activity's Flutter view. */
    fun listen(target: View) {
        view?.setOnDragListener(null)
        view = target
        target.setOnDragListener(this)
    }

    /** Lets the channel and the view go (the engine is going away). */
    fun detach() {
        view?.setOnDragListener(null)
        view = null
        channel = null
    }

    override fun onDrag(target: View, event: DragEvent): Boolean {
        when (event.action) {
            DragEvent.ACTION_DRAG_STARTED -> return carriesFiles(event.clipDescription)
            DragEvent.ACTION_DRAG_ENTERED ->
                channel?.invokeMethod("dragEntered", mapOf("link" to false))
            DragEvent.ACTION_DRAG_EXITED -> channel?.invokeMethod("dragExited", null)
            DragEvent.ACTION_DROP -> return drop(event)
        }
        return true
    }

    /** Whether a drag holds anything but text: a file, a picture. */
    private fun carriesFiles(description: ClipDescription?): Boolean {
        if (description == null) return false
        return (0 until description.mimeTypeCount)
            .map { description.getMimeType(it) }
            .any { it != ClipDescription.MIMETYPE_TEXT_PLAIN &&
                it != ClipDescription.MIMETYPE_TEXT_HTML &&
                it != ClipDescription.MIMETYPE_TEXT_INTENT }
    }

    private fun drop(event: DragEvent): Boolean {
        val clip = event.clipData ?: return false
        val uris = (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
        if (uris.isEmpty()) return false
        val permissions = activity.requestDragAndDropPermissions(event)
        Thread {
            val paths = try {
                ContentFiles.copyToCache(activity, uris, "drop")
            } finally {
                permissions?.release()
            }
            main.post { channel?.invokeMethod("drop", paths) }
        }.start()
        return true
    }
}
