#if os(macOS)
  import AppKit
  import FlutterMacOS

  /// The clipboard's HTML for Paste as Markdown (#531,
  /// lib/src/capture/paste/channel_clipboard_html.dart), as the Linux and
  /// Android runners read it: `readHtml` answers `{html, source}`, or null
  /// when the clipboard holds no HTML.
  ///
  /// Browsers put a selection on a Mac's pasteboard their own ways: Chrome
  /// and Edge as `public.html` with the page's address beside it
  /// (`org.chromium.source-url`), Firefox as `public.html` alone, Safari as
  /// a web archive, whose main resource is the HTML and names its page.
  enum ClipboardBridge {
    static let chromiumSource = NSPasteboard.PasteboardType("org.chromium.source-url")
    static let webArchive = NSPasteboard.PasteboardType("com.apple.webarchive")

    static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard call.method == "readHtml" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(read(NSPasteboard.general))
    }

    /// The pasteboard's HTML and the page it came from, or nil.
    static func read(_ pasteboard: NSPasteboard) -> [String: String]? {
      let archive = archived(pasteboard)
      guard let html = pasteboard.string(forType: .html) ?? archive?.html,
        !html.isEmpty
      else { return nil }
      var answer = ["html": html]
      if let source = pasteboard.string(forType: chromiumSource) ?? archive?.source {
        answer["source"] = source
      }
      return answer
    }

    /// Safari's web archive: its main resource's HTML and address.
    static func archived(_ pasteboard: NSPasteboard) -> (html: String?, source: String?)? {
      guard let data = pasteboard.data(forType: webArchive),
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
        let root = plist as? [String: Any],
        let main = root["WebMainResource"] as? [String: Any]
      else { return nil }
      var html: String?
      if let bytes = main["WebResourceData"] as? Data {
        let name = main["WebResourceTextEncodingName"] as? String
        html = String(data: bytes, encoding: encoding(name)) ?? String(decoding: bytes, as: UTF8.self)
      }
      return (html, main["WebResourceURL"] as? String)
    }

    /// The text encoding an IANA charset name says, UTF-8 when it says none.
    static func encoding(_ name: String?) -> String.Encoding {
      guard let name else { return .utf8 }
      let cf = CFStringConvertIANACharSetNameToEncoding(name as CFString)
      if cf == kCFStringEncodingInvalidId { return .utf8 }
      return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cf))
    }
  }
#endif
