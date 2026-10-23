#if os(macOS)
  import AppKit
  import FlutterMacOS
  import WebKit

  /// Printing an exported page with WebKit (lib/src/export/pdf_webview.dart),
  /// as Android prints it with its WebView (`PdfBridge.kt`).
  ///
  /// The page is already HTML: an offscreen `WKWebView` lays it out and
  /// WebKit's print operation, saving to the file with no panel, paginates
  /// it — real text, which selects and searches. `createPDF` would give one
  /// endless page instead. A4 with an 18 mm margin, A4 landscape with the same
  /// one for a wide kanban board (#1170), or a 16:9 sheet a slide with none
  /// (#534).
  ///
  /// One print at a time: a second call while one runs is refused
  /// (`print-busy`) rather than raced, and a watchdog answers a page whose
  /// load never ends, so the bridge never stays busy for good.
  final class PdfBridge: NSObject, WKNavigationDelegate {
    /// 18 mm, in points.
    static let margin: CGFloat = 18 / 25.4 * 72

    /// A4, in points.
    static let a4 = NSSize(width: 595.28, height: 841.89)

    /// A4 on its side, in points: a wide kanban board's sheet (#1170).
    static let a4Landscape = NSSize(width: 841.89, height: 595.28)

    /// A slide's sheet: 10 × 5.625 in, 16:9.
    static let slide = NSSize(width: 720, height: 405)

    /// The sheet the channel's `paper` names, and the margin it prints with:
    /// a slide edge to edge, any other sheet with the note's margin. A name
    /// this side does not know is A4, as a channel older than it was.
    static func sheet(_ paper: String) -> (size: NSSize, margin: CGFloat) {
      switch paper {
      case "slides": return (slide, 0)
      case "a4Landscape": return (a4Landscape, margin)
      default: return (a4, margin)
      }
    }

    /// Longer than a slow note takes to lay out, shorter than the Dart
    /// side's own timeout.
    static let watchdogSeconds: Double = 4 * 60

    private var webView: WKWebView?
    private var window: NSWindow?
    private var pending: FlutterResult?
    private var watchdog: DispatchWorkItem?
    private var pdfPath = ""
    private var paper = "a4"

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "print":
        guard let args = call.arguments as? [String: Any],
          let htmlPath = args["htmlPath"] as? String,
          let pdfPath = args["pdfPath"] as? String
        else {
          result(FlutterError(code: "bad-args", message: "htmlPath and pdfPath", details: nil))
          return
        }
        if pending != nil {
          result(FlutterError(code: "print-busy", message: "another page is being printed", details: nil))
          return
        }
        print(htmlPath: htmlPath, pdfPath: pdfPath, paper: args["paper"] as? String ?? "a4", result: result)
      case "cancel":
        // The export was cancelled: the waiting print is answered now, not
        // when the watchdog would.
        answer(FlutterError(code: "print-cancelled", message: "the export was cancelled", details: nil))
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private func print(htmlPath: String, pdfPath: String, paper: String, result: @escaping FlutterResult) {
      pending = result
      self.pdfPath = pdfPath
      self.paper = paper
      let timer = DispatchWorkItem { [weak self] in
        self?.answer(FlutterError(code: "print-timeout", message: "the page did not finish", details: nil))
      }
      watchdog = timer
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.watchdogSeconds, execute: timer)

      let sheet = Self.sheet(paper)
      let width = sheet.size.width - 2 * sheet.margin
      let frame = NSRect(x: 0, y: 0, width: width, height: 1000)
      let view = WKWebView(frame: frame)
      view.navigationDelegate = self
      // The print runs modally for a window: one off screen, never shown.
      let window = NSWindow(
        contentRect: frame.offsetBy(dx: -20000, dy: -20000), styleMask: [.borderless],
        backing: .buffered, defer: false)
      window.contentView = view
      self.webView = view
      self.window = window
      // The page's pictures are `file:` URLs into the library, wherever it
      // is: the view may read the disk, as Android's loads from it.
      view.loadFileURL(
        URL(fileURLWithPath: htmlPath), allowingReadAccessTo: URL(fileURLWithPath: "/"))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      guard webView === self.webView, let window else { return }
      let info = NSPrintInfo(dictionary: [.jobSavingURL: URL(fileURLWithPath: pdfPath)])
      info.jobDisposition = .save
      let sheet = Self.sheet(paper)
      info.paperSize = sheet.size
      let margin = sheet.margin
      info.topMargin = margin
      info.bottomMargin = margin
      info.leftMargin = margin
      info.rightMargin = margin
      info.horizontalPagination = .fit
      info.verticalPagination = .automatic
      info.isHorizontallyCentered = false
      info.isVerticallyCentered = false
      let operation = webView.printOperation(with: info)
      operation.showsPrintPanel = false
      operation.showsProgressPanel = false
      // Without a frame WebKit's print view lays out nothing: blank pages.
      operation.view?.frame = webView.bounds
      operation.runModal(
        for: window, delegate: self,
        didRun: #selector(printed(_:success:contextInfo:)), contextInfo: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      guard webView === self.webView else { return }
      answer(FlutterError(code: "print-failed", message: error.localizedDescription, details: nil))
    }

    func webView(
      _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      guard webView === self.webView else { return }
      answer(FlutterError(code: "print-failed", message: error.localizedDescription, details: nil))
    }

    // WebKit ends its print on a thread of its own: the answer goes back to
    // the main thread, the only one a channel may answer on. Answered
    // there, the reply waited for the next event to wake the main thread —
    // an export stood still until something was clicked.
    @objc private func printed(
      _ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?
    ) {
      DispatchQueue.main.async {
        self.answer(
          success ? nil : FlutterError(code: "print-failed", message: "WebKit did not print", details: nil))
      }
    }

    /// Answers the waiting print once, and lets the view go.
    private func answer(_ value: Any?) {
      watchdog?.cancel()
      watchdog = nil
      let result = pending
      pending = nil
      webView?.navigationDelegate = nil
      webView?.stopLoading()
      webView = nil
      window = nil
      result?(value)
    }
  }
#endif
