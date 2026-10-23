#if os(iOS)
  import Flutter
  import UIKit
  import WebKit

  /// Printing an exported page with WebKit on iOS
  /// (lib/src/export/pdf_webview.dart), as the Mac's `PdfBridge` does and
  /// Android's `PdfBridge.kt`: the same channel, the same answers.
  ///
  /// iOS has no print operation that saves a file: an offscreen
  /// `WKWebView` lays the page out, a `UIPrintPageRenderer` paginates its
  /// print formatter, and each page is drawn into a PDF context — real
  /// text, which selects and searches. A4 with an 18 mm margin, A4 landscape
  /// with the same one for a wide kanban board (#1170), or a 16:9 sheet a
  /// slide with none (#534).
  ///
  /// One print at a time (`print-busy`), and a watchdog for a page whose
  /// load never ends.
  final class PdfBridgeIOS: NSObject, WKNavigationDelegate {
    /// 18 mm, in points.
    static let margin: CGFloat = 18 / 25.4 * 72

    /// A4, in points.
    static let a4 = CGSize(width: 595.28, height: 841.89)

    /// A4 on its side, in points: a wide kanban board's sheet (#1170).
    static let a4Landscape = CGSize(width: 841.89, height: 595.28)

    /// A slide's sheet: 10 × 5.625 in, 16:9.
    static let slide = CGSize(width: 720, height: 405)

    /// The sheet the channel's `paper` names, and the margin it prints with:
    /// a slide edge to edge, any other sheet with the note's margin. A name
    /// this side does not know is A4, as a channel older than it was.
    static func sheet(_ paper: String) -> (size: CGSize, margin: CGFloat) {
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
      let view = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: 1000))
      view.navigationDelegate = self
      webView = view
      // The page's pictures are `file:` URLs beside it in the app's own
      // folders: the view may read the container.
      let page = URL(fileURLWithPath: htmlPath)
      view.loadFileURL(page, allowingReadAccessTo: URL(fileURLWithPath: NSHomeDirectory()))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      guard webView === self.webView else { return }
      let sheet = Self.sheet(paper)
      let paperRect = CGRect(origin: .zero, size: sheet.size)
      let renderer = PageRenderer(
        paper: paperRect, printable: paperRect.insetBy(dx: sheet.margin, dy: sheet.margin))
      renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)
      let data = NSMutableData()
      UIGraphicsBeginPDFContextToData(data, paperRect, nil)
      let pages = renderer.numberOfPages
      renderer.prepare(forDrawingPages: NSRange(location: 0, length: pages))
      for index in 0..<pages {
        UIGraphicsBeginPDFPage()
        renderer.drawPage(at: index, in: UIGraphicsGetPDFContextBounds())
      }
      UIGraphicsEndPDFContext()
      if pages > 0 && data.write(toFile: pdfPath, atomically: true) {
        answer(nil)
      } else {
        answer(FlutterError(code: "print-failed", message: "WebKit laid out no page", details: nil))
      }
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

    /// Answers the waiting print once, and lets the view go.
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

  /// A renderer whose paper and printable area are the bridge's: the two
  /// are read-only on `UIPrintPageRenderer`, set by a print job otherwise.
  private final class PageRenderer: UIPrintPageRenderer {
    private let paper: CGRect
    private let printable: CGRect

    init(paper: CGRect, printable: CGRect) {
      self.paper = paper
      self.printable = printable
    }

    override var paperRect: CGRect { paper }
    override var printableRect: CGRect { printable }
  }
#endif
