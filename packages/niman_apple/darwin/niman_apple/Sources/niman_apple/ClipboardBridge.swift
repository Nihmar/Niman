import Foundation

#if os(iOS)
  import Flutter
  import UIKit
#else
  import AppKit
  import FlutterMacOS
#endif

/// The clipboard's HTML for Paste as Markdown (#531,
/// lib/src/capture/paste/channel_clipboard_html.dart), as the Linux and
/// Android runners read it: `readHtml` answers `{html, source}`, or null
/// when the clipboard holds no HTML.
///
/// Browsers put a selection on an Apple pasteboard their own ways: Chrome
/// and Edge as `public.html` with the page's address beside it
/// (`org.chromium.source-url`), Firefox as `public.html` alone, Safari as
/// a web archive, whose main resource is the HTML and names its page.
enum ClipboardBridge {
  static let html = "public.html"
  static let chromiumSource = "org.chromium.source-url"
  static let webArchive = "com.apple.webarchive"

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "readHtml" else {
      result(FlutterMethodNotImplemented)
      return
    }
    #if os(iOS)
      let board = UIPasteboard.general
      result(
        read(
          string: { type in
            board.value(forPasteboardType: type) as? String
              ?? board.data(forPasteboardType: type).flatMap { String(data: $0, encoding: .utf8) }
          },
          data: { board.data(forPasteboardType: $0) }))
    #else
      let board = NSPasteboard.general
      result(
        read(
          string: { board.string(forType: NSPasteboard.PasteboardType($0)) },
          data: { board.data(forType: NSPasteboard.PasteboardType($0)) }))
    #endif
  }

  /// The pasteboard's HTML and the page it came from, or nil, read through
  /// [string] and [data], which answer a type's contents.
  static func read(
    string: (String) -> String?, data: (String) -> Data?
  ) -> [String: String]? {
    let archive = archived(data(webArchive))
    guard let page = string(html) ?? archive?.html, !page.isEmpty else { return nil }
    var answer = ["html": page]
    if let source = string(chromiumSource) ?? archive?.source {
      answer["source"] = source
    }
    return answer
  }

  /// Safari's web archive: its main resource's HTML and address.
  static func archived(_ data: Data?) -> (html: String?, source: String?)? {
    guard let data,
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
      let root = plist as? [String: Any],
      let main = root["WebMainResource"] as? [String: Any]
    else { return nil }
    var page: String?
    if let bytes = main["WebResourceData"] as? Data {
      let name = main["WebResourceTextEncodingName"] as? String
      page = String(data: bytes, encoding: encoding(name)) ?? String(decoding: bytes, as: UTF8.self)
    }
    return (page, main["WebResourceURL"] as? String)
  }

  /// The text encoding an IANA charset name says, UTF-8 when it says none.
  static func encoding(_ name: String?) -> String.Encoding {
    guard let name else { return .utf8 }
    let cf = CFStringConvertIANACharSetNameToEncoding(name as CFString)
    if cf == kCFStringEncodingInvalidId { return .utf8 }
    return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cf))
  }
}
