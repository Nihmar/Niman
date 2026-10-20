package dev.niman.niman

/**
 * The type a file is offered to other apps as (#1109).
 *
 * An app picks itself out of the system's list by the type of what it is
 * handed, so a PDF or a book has to say what it is. The types a library
 * holds are named here; anything else is offered as `*` and left to the
 * system to match by the file's name.
 */
object OpenFileMime {
    /** Offered for a file whose extension is not known here. */
    const val ANY = "*/*"

    private val byExtension = mapOf(
        "pdf" to "application/pdf",
        "epub" to "application/epub+zip",
        "md" to "text/markdown",
        "markdown" to "text/markdown",
        "txt" to "text/plain",
        "png" to "image/png",
        "jpg" to "image/jpeg",
        "jpeg" to "image/jpeg",
        "gif" to "image/gif",
        "webp" to "image/webp",
        "bmp" to "image/bmp",
        "mp3" to "audio/mpeg",
        "m4a" to "audio/mp4",
        "wav" to "audio/x-wav",
        "ogg" to "audio/ogg",
        "flac" to "audio/flac",
        "mp4" to "video/mp4",
        "zip" to "application/zip",
    )

    /** The type for a file called [name], by its extension, any case. */
    fun forName(name: String): String {
        val dot = name.lastIndexOf('.')
        if (dot <= 0 || dot == name.length - 1) return ANY
        return byExtension[name.substring(dot + 1).lowercase()] ?: ANY
    }
}
