#if os(macOS)
  import AppKit
  import FlutterMacOS
  import WebKit

  /// Reading a web page by running it (#531,
  /// lib/src/capture/browser/webview_page_browser.dart), as Android reads it
  /// with its WebView (`PageReaderBridge.kt`): the capture's fallback for a
  /// page that builds itself with scripts.
  ///
  /// An offscreen `WKWebView` of its own: JavaScript on, nothing kept
  /// (a non-persistent data store), no message handler — the page reaches
  /// nothing of the app. Once it has loaded, its text is measured every
  /// second; when it stops growing, or after `maxPolls` seconds, the DOM's
  /// `outerHTML` is the answer, or null past `maxCharacters`.
  ///
  /// One read at a time: a second call while one runs is refused. A
  /// watchdog answers a page that never settles.
  final class PageReaderBridge: NSObject, WKNavigationDelegate {
    /// How often the page's text is measured once it has loaded.
    static let pollSeconds: Double = 1

    /// How many measures before the DOM is read anyway.
    static let maxPolls = 10

    private var webView: WKWebView?
    private var pending: FlutterResult?
    private var watchdog: DispatchWorkItem?
    private var maxCharacters = 20 * 1024 * 1024

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "read":
        guard let args = call.arguments as? [String: Any],
          let address = args["url"] as? String, let url = URL(string: address)
        else {
          result(FlutterError(code: "bad-args", message: "url", details: nil))
          return
        }
        if pending != nil {
          result(FlutterError(code: "read-busy", message: "another page is being read", details: nil))
          return
        }
        maxCharacters = args["maxCharacters"] as? Int ?? maxCharacters
        let timeoutMs = args["timeoutMs"] as? Int ?? 30_000
        read(url, timeout: Double(timeoutMs) / 1000, result: result)
      case "cancel":
        answer(nil)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private func read(_ url: URL, timeout: Double, result: @escaping FlutterResult) {
      pending = result
      let timer = DispatchWorkItem { [weak self] in
        self?.answer(FlutterError(code: "read-timeout", message: "the page did not settle", details: nil))
      }
      watchdog = timer
      DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timer)
      let configuration = WKWebViewConfiguration()
      configuration.websiteDataStore = .nonPersistent()
      let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 768), configuration: configuration)
      view.navigationDelegate = self
      webView = view
      view.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      guard webView === self.webView else { return }
      poll(webView, last: -1, polls: 0)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      guard webView === self.webView else { return }
      answer(nil)
    }

    func webView(
      _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      guard webView === self.webView else { return }
      answer(nil)
    }

    /// Measures the page's text until it stops growing, then reads it.
    private func poll(_ view: WKWebView, last: Int, polls: Int) {
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.pollSeconds) { [weak self] in
        guard let self, view === self.webView else { return }
        view.evaluateJavaScript("document.body ? document.body.innerText.length : 0") { value, _ in
          guard view === self.webView else { return }
          let length = (value as? Int) ?? 0
          if length == last || polls + 1 >= Self.maxPolls {
            self.dump(view)
          } else {
            self.poll(view, last: length, polls: polls + 1)
          }
        }
      }
    }

    /// Answers the page's `outerHTML`, or null past `maxCharacters`.
    private func dump(_ view: WKWebView) {
      let script =
        "(function(){var h=document.documentElement.outerHTML;"
        + "return h.length>\(maxCharacters)?null:h;})()"
      view.evaluateJavaScript(script) { [weak self] value, _ in
        guard let self, view === self.webView else { return }
        self.answer(value as? String)
      }
    }

    /// Answers the waiting read once, and lets the view go.
    private func answer(_ value: Any?) {
      watchdog?.cancel()
      watchdog = nil
      let result = pending
      pending = nil
      webView?.navigationDelegate = nil
      webView?.stopLoading()
      webView = nil
      result?(value)
    }
  }
#endif
