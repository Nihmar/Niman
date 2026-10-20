package dev.niman.niman

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands a library file to another app (#1109).
 *
 * With the PDF and EPUB readers off, a PDF or a book opens in whatever the
 * system opens it with, as on a desktop. The library sits in shared storage
 * (Niman holds All files access), but another app is not given a path: it is
 * given a `content://` URI from FileProvider, with read access granted for
 * that one start (see `file_provider_paths.xml`).
 *
 * `openFile` answers true when an app took the file, false when the file is
 * gone, FileProvider will not name it, or no app opens its type.
 */
class OpenFileBridge(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/open"
    }

    private var channel: MethodChannel? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@OpenFileBridge)
        }
    }

    /** Drops the channel (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openFile" -> result.success(openFile(call.argument("path")))
            else -> result.notImplemented()
        }
    }

    private fun openFile(path: String?): Boolean {
        if (path.isNullOrEmpty()) return false
        val file = File(path)
        if (!file.isFile) return false
        val uri = try {
            FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        } catch (e: IllegalArgumentException) {
            return false
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, OpenFileMime.forName(file.name))
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
