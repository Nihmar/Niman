import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// The quit channel (`niman/quit`), set up by the main window once its
  /// engine runs.
  var quitChannel: FlutterMethodChannel?

  /// Set when Dart has run its close guard and lets the quit through.
  var quitConfirmed = false

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // The × hides the window rather than closing it (decision 11 of
  // docs/records/apple-platforms.md): a click on the Dock icon brings it
  // back.
  override func applicationShouldHandleReopen(
    _ sender: NSApplication, hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      mainFlutterWindow?.makeKeyAndOrderFront(nil)
    }
    return true
  }

  // ⌘Q, the menu's and the Dock's Quit, a logout: Dart asks about unsaved
  // notes first, then confirms over the channel. A Dart side that does not
  // answer — still starting, or its guard gone — lets the quit through.
  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard !quitConfirmed, let channel = quitChannel else {
      return .terminateNow
    }
    channel.invokeMethod("requested", arguments: nil) { result in
      if result is FlutterError || (result as? NSObject) == FlutterMethodNotImplemented {
        self.confirmQuit()
      }
    }
    return .terminateCancel
  }

  /// Lets the quit through and terminates.
  func confirmQuit() {
    quitConfirmed = true
    NSApp.terminate(nil)
  }
}
