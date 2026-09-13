package dev.niman.niman

import android.content.Context
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Durable append-only log of widget placement and lifecycle decisions.
 *
 * The device's logcat ring buffer keeps only tens of seconds, so the
 * lines that explain a widget problem (a config rejection, a picker
 * result) are gone by the time a debug log is exported. This file is
 * not: it lives in the app's own external files dir, survives process
 * death and reboots, and the debug export appends its tail
 * (`WidgetBridge.widgetDebugLog`).
 *
 * Every call mirrors its line to logcat as well, so both channels stay
 * consistent. Never throws: logging must not break the widget flow it
 * only describes.
 */
object WidgetDebugLog {

    /** The file name inside the app's external files dir. */
    const val FILE_NAME = "widget-debug.log"

    private const val TAG = "WidgetDebug"

    /** Above this size the file is trimmed to its tail (half the cap). */
    private const val MAX_BYTES = 128 * 1024

    private val lock = Any()

    /** The log file in the app's external files dir, or null. */
    fun file(context: Context): File? =
        context.getExternalFilesDir(null)?.let { File(it, FILE_NAME) }

    /**
     * Appends one timestamped line to the file and mirrors it to
     * logcat. [message] is one line; callers compose multi-part
     * messages themselves.
     */
    fun log(context: Context, message: String) {
        Log.d(TAG, message)
        try {
            val file = file(context) ?: return
            val line = "${timestamp()} $message\n"
            synchronized(lock) {
                trimIfNeeded(file)
                file.appendText(line)
            }
        } catch (e: Exception) {
            Log.w(TAG, "widget debug log write failed", e)
        }
    }

    /** Keeps the file bounded: the tail is what a report is about. */
    private fun trimIfNeeded(file: File) {
        if (file.length() < MAX_BYTES) return
        val bytes = file.readBytes()
        val tail = bytes.copyOfRange(bytes.size - MAX_BYTES / 2, bytes.size)
        // Drop the partial first line left by the cut.
        val start = tail.indexOf('\n'.code.toByte()) + 1
        file.writeBytes(if (start in 1..tail.size - 1) tail.copyOfRange(start, tail.size) else tail)
    }

    private fun timestamp(): String =
        SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date())
}
