import AVFoundation

#if os(iOS)
  import Flutter
  import UIKit
#else
  import FlutterMacOS
#endif

/// Niman's native code for macOS and iOS (README.md lists the channels).
public class NimanApplePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    let audio = FlutterMethodChannel(name: "niman/audio", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(NimanApplePlugin(), channel: audio)
    #if os(macOS)
      // WebKit prints the PDF export and reads script-built pages, as
      // Android's WebView does (README.md).
      let pdf = FlutterMethodChannel(name: "niman/pdf", binaryMessenger: messenger)
      pdf.setMethodCallHandler(pdfBridge.handle)
    #else
      // WebKit prints the PDF export through a page renderer on iOS.
      let pdf = FlutterMethodChannel(name: "niman/pdf", binaryMessenger: messenger)
      pdf.setMethodCallHandler(pdfBridge.handle)
    #endif
    // Script-built pages are run in WebKit, on both (README.md).
    let pageReader = FlutterMethodChannel(name: "niman/page_reader", binaryMessenger: messenger)
    pageReader.setMethodCallHandler(pageReaderBridge.handle)
    // The clipboard's HTML, for Paste as Markdown, as Linux's runner reads it.
    let clipboard = FlutterMethodChannel(name: "niman/clipboard", binaryMessenger: messenger)
    clipboard.setMethodCallHandler(ClipboardBridge.handle)
    #if os(iOS)
      // The screen kept on while slides are presented, as Android's
      // keep-screen-on flag (a Mac takes a power assertion from Dart).
      let screen = FlutterMethodChannel(name: "niman/screen", binaryMessenger: messenger)
      screen.setMethodCallHandler { call, result in
        guard call.method == "keepOn", let on = call.arguments as? Bool else {
          result(FlutterMethodNotImplemented)
          return
        }
        UIApplication.shared.isIdleTimerDisabled = on
        result(nil)
      }
    #endif
  }

  /// The bridges, alive for the app's life as their channels are.
  #if os(macOS)
    private static let pdfBridge = PdfBridge()
  #else
    private static let pdfBridge = PdfBridgeIOS()
  #endif
  private static let pageReaderBridge = PageReaderBridge()

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "decodeToWav":
      guard let args = call.arguments as? [String: Any],
        let source = args["source"] as? String,
        let target = args["target"] as? String
      else {
        result(FlutterError(code: "bad-args", message: "source and target", details: nil))
        return
      }
      // Off the main thread: a long clip takes a while, and the UI must not.
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try AudioDecoder.decodeToWav(
            source: URL(fileURLWithPath: source), target: URL(fileURLWithPath: target))
          DispatchQueue.main.async { result(nil) }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "decode-failed", message: error.localizedDescription, details: nil))
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
