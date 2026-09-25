package android.print

import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import java.io.File

/**
 * Calls a [PrintDocumentAdapter] and writes its pages into a file, without
 * the system's print sheet (issue #63).
 *
 * [PrintDocumentAdapter.onLayout] and `onWrite` take callbacks whose
 * constructors are package-private, so only a class in this package can
 * make them: this file is why the app has a source file under
 * `android.print`. Android's own `android.print.PdfPrint` does the same
 * thing and is not in the public SDK; this is the part of it writing a
 * page to a file needs.
 *
 * The adapter calls back on the main thread; [done] is answered once, and
 * the file is closed before it is.
 */
class NimanPdfWriter(private val attributes: PrintAttributes) {
    /** Writes [adapter]'s pages into [file], then answers [done]. */
    fun print(
        adapter: PrintDocumentAdapter,
        file: File,
        done: (Boolean, String?) -> Unit,
    ) {
        val descriptor = try {
            ParcelFileDescriptor.open(
                file,
                ParcelFileDescriptor.MODE_CREATE or
                    ParcelFileDescriptor.MODE_READ_WRITE or
                    ParcelFileDescriptor.MODE_TRUNCATE,
            )
        } catch (error: Exception) {
            done(false, error.message)
            return
        }
        var answered = false
        fun finish(ok: Boolean, error: String?) {
            if (answered) return
            answered = true
            try {
                descriptor.close()
            } catch (_: Exception) {
                // Closing the file is not the caller's answer.
            }
            done(ok, error)
        }
        adapter.onLayout(
            null,
            attributes,
            CancellationSignal(),
            object : PrintDocumentAdapter.LayoutResultCallback() {
                override fun onLayoutFinished(
                    info: PrintDocumentInfo?,
                    changed: Boolean,
                ) {
                    adapter.onWrite(
                        arrayOf(PageRange.ALL_PAGES),
                        descriptor,
                        CancellationSignal(),
                        object : PrintDocumentAdapter.WriteResultCallback() {
                            override fun onWriteFinished(pages: Array<out PageRange>?) {
                                finish(true, null)
                            }

                            override fun onWriteFailed(error: CharSequence?) {
                                finish(false, error?.toString())
                            }

                            override fun onWriteCancelled() {
                                finish(false, "the write was cancelled")
                            }
                        },
                    )
                }

                override fun onLayoutFailed(error: CharSequence?) {
                    finish(false, error?.toString())
                }

                override fun onLayoutCancelled() {
                    finish(false, "the layout was cancelled")
                }
            },
            null,
        )
    }
}
