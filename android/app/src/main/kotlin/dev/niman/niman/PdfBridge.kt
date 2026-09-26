package dev.niman.niman

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.print.NimanPdfWriter
import android.print.PrintAttributes
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Printing a page with the system WebView (issue #63).
 *
 * The page is already HTML; an offscreen [WebView] lays it out, its print
 * adapter paginates it, and [NimanPdfWriter] — under `android.print`, the
 * only package that may call the adapter's callbacks — writes the pages
 * straight into the PDF file. A4, with the 18 mm margin the page's own
 * print CSS asks for — the attribute is in thousandths of an inch.
 *
 * One print at a time: the view and the answer belong to the activity,
 * and a second call while one runs is refused rather than raced.
 *
 * A WebView whose callbacks never arrive is answered by a watchdog, so the
 * bridge never stays busy forever; the Dart side times out on the same
 * span.
 */
class PdfBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/pdf"

        /** 18 mm in thousandths of an inch. */
        const val MARGIN_MILS = 709

        /** How long a print may run before the watchdog answers it failed.
         *  Longer than the route a slow one takes, shorter than the Dart
         *  side's own timeout: a WebView that is laying a long note out
         *  gets to finish, and one that never answers is stopped by the
         *  watchdog itself. */
        const val WATCHDOG_MS = 4 * 60 * 1000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var watchdog: Runnable? = null

    private var channel: MethodChannel? = null
    private var webView: WebView? = null
    private var busy = false

    /** The print the Dart side is waiting on, and whether it was answered. */
    private var pendingResult: MethodChannel.Result? = null
    private var pendingAnswer: AtomicBoolean? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@PdfBridge)
        }
    }

    /** Drops the channel and the offscreen view (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        watchdog?.let { handler.removeCallbacks(it) }
        watchdog = null
        webView?.destroy()
        webView = null
        busy = false
        pendingAnswer = null
        pendingResult = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "print" -> {
                val htmlPath = call.argument<String>("htmlPath")
                val pdfPath = call.argument<String>("pdfPath")
                if (htmlPath == null || pdfPath == null) {
                    result.error("bad-arguments", "htmlPath and pdfPath are required", null)
                    return
                }
                if (busy) {
                    result.error("print-busy", "another page is being printed", null)
                    return
                }
                print(htmlPath, pdfPath, result)
            }
            // The export was cancelled: destroy the view and answer the
            // waiting print, instead of staying busy until the watchdog.
            "cancel" -> {
                cancel(result)
            }
            else -> result.notImplemented()
        }
    }

    /** Stops the print in flight, if any, and clears the bridge. */
    private fun cancel(result: MethodChannel.Result) {
        watchdog?.let { handler.removeCallbacks(it) }
        watchdog = null
        busy = false
        webView?.destroy()
        webView = null
        val answer = pendingAnswer
        val waiting = pendingResult
        pendingAnswer = null
        pendingResult = null
        // The waiting print is answered after the print's own callback,
        // which the flag keeps from answering twice.
        answer?.set(true)
        waiting?.error("print-cancelled", "the print was cancelled", null)
        result.success(null)
    }

    private fun print(htmlPath: String, pdfPath: String, result: MethodChannel.Result) {
        busy = true
        val answered = AtomicBoolean(false)
        pendingResult = result
        pendingAnswer = answered
        fun finish(ok: Boolean, error: String? = null) {
            if (!answered.compareAndSet(false, true)) return
            watchdog?.let { handler.removeCallbacks(it) }
            watchdog = null
            busy = false
            pendingResult = null
            pendingAnswer = null
            if (ok) result.success(null) else result.error("print-failed", error, null)
        }

        // A WebView whose callbacks never arrive must not leave the bridge
        // busy forever: the watchdog answers the failure the Dart side
        // times out on.
        val timer = Runnable { finish(false, "the WebView did not finish") }
        watchdog = timer
        handler.postDelayed(timer, WATCHDOG_MS)

        // One view at a time: the last print has answered already, and
        // destroying its view outside its own callback keeps that stack
        // clean.
        webView?.destroy()
        val view = WebView(context)
        webView = view
        // The page is one file whose pictures are `file:` URLs into the
        // library: the WebView loads it from disk and fetches them itself.
        // Reading the file into a String first built a page-sized
        // StringWriter in this process's heap — 256 MB for a note with
        // many photos — and OOM'd the app.
        view.settings.allowFileAccess = true
        view.settings.allowFileAccessFromFileURLs = true
        view.settings.allowContentAccess = true
        view.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String?) {
                write(view, pdfPath) { ok, error -> finish(ok, error) }
            }
        }
        view.loadUrl(Uri.fromFile(File(htmlPath)).toString())
    }

    /** Lays the loaded page out and writes its pages into [pdfPath]. */
    private fun write(
        view: WebView,
        pdfPath: String,
        done: (Boolean, String?) -> Unit,
    ) {
        val attributes = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            // The WebView's adapter refuses a layout whose attributes say
            // nothing about resolution: without it `onLayout` answers
            // "attributes must specify print resolution" and every export
            // fell back to a picture. 300 dpi is the usual print floor;
            // the text stays vector either way.
            .setResolution(PrintAttributes.Resolution("niman", "Niman", 300, 300))
            .setMinMargins(
                PrintAttributes.Margins(MARGIN_MILS, MARGIN_MILS, MARGIN_MILS, MARGIN_MILS),
            )
            .build()
        try {
            val adapter = view.createPrintDocumentAdapter("Niman")
            NimanPdfWriter(attributes).print(adapter, File(pdfPath), done)
        } catch (error: Throwable) {
            // The package-private access the writer needs cannot be checked
            // by the compiler against every device's runtime: a refusal is
            // an Error, and it must fail the print — the export falls back —
            // not the process.
            done(false, error.message ?: error.toString())
        }
    }
}
