package dev.niman.niman

import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

/**
 * The copy a shared stream becomes in the share cache (#386).
 *
 * Android hands a share over as a `content://` URI, so [ShareBridge]
 * reads the bytes itself and Dart imports the copy it writes. The size
 * is the sender's choice and the manifest takes a zip — a Notion export
 * (#25) — as well as a note, so the read is capped here: without a cap a
 * share is however large the sender felt like making it, and a stream a
 * provider never ends is read forever.
 *
 * The bytes are counted as they arrive rather than taken from a size a
 * provider reports: a provider may report nothing, or a number its own
 * stream does not honour. [ShareBridge] asks for the reported size too,
 * to refuse a large share before reading it; this is the limit that
 * actually holds.
 */
internal object ShareCopy {
    /**
     * The most a shared file may be, in bytes.
     *
     * 512 MiB. A Notion export of a whole workspace is the largest thing
     * a phone shares into Niman, and the copy is temporary — Dart
     * imports it and deletes it. Past this the share is refused, which
     * costs the sender a message rather than the app its responsiveness.
     */
    const val MAX_BYTES = 512L * 1024 * 1024

    /** How much is read at a time (64 KiB). */
    private const val CHUNK = 64 * 1024

    /** What reading a share produced. */
    internal sealed interface Result {
        /** The whole stream is in the file. */
        data object Copied : Result

        /**
         * The stream held more than the cap. Nothing was left behind:
         * the half-written file is deleted before this is answered, so
         * a refused share never reaches Dart as a truncated file it
         * would import as a note.
         */
        data object TooLarge : Result
    }

    /**
     * Reads [source] into [file], refusing a stream longer than [cap].
     *
     * At most one chunk past [cap] is read, so a refusal costs the cap
     * and not the rest of the share — a provider that answers with an
     * endless stream ends the read here instead of never.
     *
     * [source] is left open: the caller opened it and closes it.
     */
    fun read(source: InputStream, file: File, cap: Long = MAX_BYTES): Result {
        var total = 0L
        var refused = false
        val chunk = ByteArray(CHUNK)
        FileOutputStream(file).use { target ->
            while (true) {
                val read = source.read(chunk)
                if (read < 0) break
                total += read
                if (total > cap) {
                    refused = true
                    break
                }
                target.write(chunk, 0, read)
            }
        }
        if (refused) {
            file.delete()
            return Result.TooLarge
        }
        return Result.Copied
    }
}
