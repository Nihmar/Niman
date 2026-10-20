import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // The quit channel (lib/src/ui/mac_quit.dart): the app delegate asks
    // over it before terminating, and Dart answers `confirm`.
    let quit = FlutterMethodChannel(
      name: "niman/quit", binaryMessenger: flutterViewController.engine.binaryMessenger)
    quit.setMethodCallHandler { call, result in
      guard call.method == "confirm", let app = NSApp.delegate as? AppDelegate else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(nil)
      app.confirmQuit()
    }
    (NSApp.delegate as? AppDelegate)?.quitChannel = quit

    super.awakeFromNib()
  }
}
