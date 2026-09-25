package dev.niman.niman

import android.content.Context
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

        /** How long a print may run before the watchdog answers it failed. */
        const val WATCHDOG_MS = 2 * 60 * 1000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var watchdog: Runnable? = null

    private var channel: MethodChannel? = null
    private var webView: WebView? = null
    private var busy = false

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
            else -> result.notImplemented()
        }
    }

    private fun print(htmlPath: String, pdfPath: String, result: MethodChannel.Result) {
        busy = true
        val answered = AtomicBoolean(false)
        fun finish(ok: Boolean, error: String? = null) {
            if (!answered.compareAndSet(false, true)) return
            watchdog?.let { handler.removeCallbacks(it) }
            watchdog = null
            busy = false
            if (ok) result.success(null) else result.error("print-failed", error, null)
        }

        // A WebView whose callbacks never arrive must not leave the bridge
        // busy forever: the watchdog answers the failure the Dart side
        // times out on.
        val timer = Runnable { finish(false, "the WebView did not finish") }
        watchdog = timer
        handler.postDelayed(timer, WATCHDOG_MS)

        val html = try {
            File(htmlPath).readText()
        } catch (error: Exception) {
            finish(false, error.message)
            return
        }
        // One view at a time: the last print has answered already, and
        // destroying its view outside its own callback keeps that stack
        // clean.
        webView?.destroy()
        val view = WebView(context)
        webView = view
        view.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView, url: String?) {
                write(view, pdfPath) { ok, error -> finish(ok, error) }
            }
        }
        // The base URL only resolves relative URLs: the page is one file,
        // its pictures data: URIs, so the directory it came from is enough.
        val base = File(htmlPath).parentFile?.toURI()?.toString() ?: "file:///"
        view.loadDataWithBaseURL(base, html, "text/html", "utf-8", null)
    }

    /** Lays the loaded page out and writes its pages into [pdfPath]. */
    private fun write(
        view: WebView,
        pdfPath: String,
        done: (Boolean, String?) -> Unit,
    ) {
        val attributes = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            .setMinMargins(
                PrintAttributes.Margins(MARGIN_MILS, MARGIN_MILS, MARGIN_MILS, MARGIN_MILS),
            )
            .build()
        NimanPdfWriter(attributes).print(
            view.createPrintDocumentAdapter("Niman"),
            File(pdfPath),
            done,
        )
    }
}
