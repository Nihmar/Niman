package dev.niman.niman

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.json.JSONTokener

/**
 * Reading a web page by running it (issue #531): the capture's fallback
 * when the download has too little text, a page that builds itself with
 * scripts.
 *
 * An offscreen [WebView] of its own, apart from the PDF one: JavaScript on,
 * network pictures off (the text is what is read), no file or content
 * access and no JavaScript interface — the page reaches nothing of the app.
 * Once the page has finished loading, its text is measured every second;
 * when it stops growing, or after [MAX_POLLS] seconds, the DOM's
 * `outerHTML` is the answer.
 *
 * One read at a time, as one print: a second call while one runs is
 * refused. A watchdog answers a page that never settles.
 */
class PageReaderBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        /** The Dart-facing channel. */
        const val CHANNEL = "niman/page_reader"

        /** How often the page's text is measured once it has loaded. */
        const val POLL_MS = 1000L

        /** How many measures before the DOM is read anyway. */
        const val MAX_POLLS = 10
    }

    private val handler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var webView: WebView? = null
    private var watchdog: Runnable? = null
    private var pending: MethodChannel.Result? = null

    /** Wires the channel to the Flutter engine. */
    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL).apply {
            setMethodCallHandler(this@PageReaderBridge)
        }
    }

    /** Drops the channel and the view (the engine is going away). */
    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        stop()
        pending = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "read" -> {
                val url = call.argument<String>("url")
                val timeoutMs = call.argument<Int>("timeoutMs") ?: 45000
                val maxCharacters = call.argument<Int>("maxCharacters") ?: 20 * 1024 * 1024
                if (url == null || !isWeb(url)) {
                    result.error("bad-arguments", "an http or https url is required", null)
                    return
                }
                if (pending != null) {
                    result.error("read-busy", "another page is being read", null)
                    return
                }
                read(url, timeoutMs.toLong(), maxCharacters, result)
            }
            "cancel" -> {
                answer { it.error("read-cancelled", "the read was cancelled", null) }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun isWeb(url: String): Boolean {
        val scheme = Uri.parse(url).scheme?.lowercase()
        return scheme == "http" || scheme == "https"
    }

    /** Answers the waiting read once, and clears the bridge. */
    private fun answer(reply: (MethodChannel.Result) -> Unit) {
        val waiting = pending ?: return
        pending = null
        stop()
        reply(waiting)
    }

    private fun stop() {
        watchdog?.let { handler.removeCallbacks(it) }
        watchdog = null
        handler.removeCallbacksAndMessages(null)
        webView?.stopLoading()
        webView?.destroy()
        webView = null
    }

    private fun read(url: String, timeoutMs: Long, maxCharacters: Int, result: MethodChannel.Result) {
        pending = result
        val timer = Runnable { answer { it.error("read-timeout", "the page did not settle", null) } }
        watchdog = timer
        handler.postDelayed(timer, timeoutMs)

        val view = WebView(context)
        webView = view
        view.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            blockNetworkImage = true
            loadsImagesAutomatically = false
            allowFileAccess = false
            allowContentAccess = false
            mediaPlaybackRequiresUserGesture = true
        }
        var settling = false
        view.webViewClient = object : WebViewClient() {
            // The page may go on to other web pages, never to anything else.
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean =
                !isWeb(request.url.toString())

            override fun onPageFinished(view: WebView, url: String?) {
                if (settling || webView !== view) return
                settling = true
                poll(view, -1, 0, maxCharacters)
            }
        }
        view.loadUrl(url)
    }

    /** Measures the page's text until it stops growing, then reads it. */
    private fun poll(view: WebView, last: Int, polls: Int, maxCharacters: Int) {
        handler.postDelayed({
            if (webView !== view) return@postDelayed
            view.evaluateJavascript("document.body ? document.body.innerText.length : 0") { value ->
                if (webView !== view) return@evaluateJavascript
                val length = value?.toIntOrNull() ?: 0
                if ((length > 0 && length == last) || polls + 1 >= MAX_POLLS) {
                    dump(view, maxCharacters)
                } else {
                    poll(view, length, polls + 1, maxCharacters)
                }
            }
        }, POLL_MS)
    }

    /** Answers the page's `outerHTML`, or null past [maxCharacters]. */
    private fun dump(view: WebView, maxCharacters: Int) {
        val script = "(function(){var h=document.documentElement.outerHTML;" +
            "return h.length>$maxCharacters?null:h;})()"
        view.evaluateJavascript(script) { value ->
            if (webView !== view) return@evaluateJavascript
            // The value comes back as JSON: a string, or null.
            val html = try {
                JSONTokener(value ?: "null").nextValue().takeIf { it != JSONObject.NULL } as? String
            } catch (error: Throwable) {
                null
            }
            answer { it.success(html) }
        }
    }
}
