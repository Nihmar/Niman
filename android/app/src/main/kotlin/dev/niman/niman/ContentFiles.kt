package dev.niman.niman

import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log
import java.io.File
import java.util.UUID

/**
 * Files another app hands over as URIs — a clipboard item (#1249), a drop
 * (#1250) — copied into the app's cache under their own names, since Dart
 * copies a path, and a `content://` URI is no path.
 *
 * Each call empties its folder first: the files of the last paste or drop
 * have been copied on into the library by then.
 */
object ContentFiles {
    private const val TAG = "niman"

    /**
     * Copies each of [uris] that is a file — `content://` or `file://`, not
     * a web address — into `cache/<folder>/<id>/<n>/<name>`, and answers
     * the copies' paths, in order. Blocking: call it off the main thread.
     */
    fun copyToCache(context: Context, uris: List<Uri>, folder: String): List<String> {
        val base = File(context.cacheDir, folder)
        base.deleteRecursively()
        val batch = File(base, UUID.randomUUID().toString())
        val paths = mutableListOf<String>()
        uris.forEachIndexed { index, uri ->
            if (uri.scheme != ContentResolver.SCHEME_CONTENT &&
                uri.scheme != ContentResolver.SCHEME_FILE
            ) {
                return@forEachIndexed
            }
            try {
                val target = File(File(batch, index.toString()), nameOf(context, uri))
                target.parentFile?.mkdirs()
                val input = context.contentResolver.openInputStream(uri)
                    ?: return@forEachIndexed
                input.use { source ->
                    target.outputStream().use { sink -> source.copyTo(sink) }
                }
                paths.add(target.path)
            } catch (error: Exception) {
                Log.w(TAG, "content file not copied: $error")
            }
        }
        return paths
    }

    /** The name the provider gives [uri], or its last segment. */
    private fun nameOf(context: Context, uri: Uri): String {
        val shown = try {
            context.contentResolver.query(
                uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (error: Exception) {
            null
        }
        val name = (shown ?: uri.lastPathSegment ?: "file")
            .substringAfterLast('/')
            .ifBlank { "file" }
        return name
    }
}
