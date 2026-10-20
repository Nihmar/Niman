import AVFoundation

#if os(iOS)
  import Flutter
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
  }

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
