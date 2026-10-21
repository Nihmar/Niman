import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  /// The quit channel (`niman/quit`), set up by the main window once its
  /// engine runs.
  var quitChannel: FlutterMethodChannel?

  /// Set when Dart has run its close guard and lets the quit through.
  var quitConfirmed = false

  /// The app's channel (`niman/apple_app`, lib/src/core/apple_app_events.dart):
  /// the files Finder asks to open, and the Dock menu.
  var appChannel: FlutterMethodChannel?

  /// Files asked for before Dart listens — a double-clicked note starts
  /// the app — handed over when it first asks.
  private var pendingFiles: [String] = []
  private var dartListens = false

  /// The Dock menu's quick actions, as Dart named them: id and label.
  private var dockItems: [(id: String, label: String)] = []

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

  // A note opened from Finder (Open With, a double click, a drop on the
  // Dock icon): to Dart, or kept until it listens.
  override func application(_ application: NSApplication, open urls: [URL]) {
    // The plugins hear of them as without this: Flutter forwards them.
    super.application(application, open: urls)
    let paths = urls.filter(\.isFileURL).map(\.path)
    guard dartListens, let channel = appChannel else {
      pendingFiles += paths
      return
    }
    for path in paths {
      channel.invokeMethod("open", arguments: path)
    }
  }

  // The Dock icon's menu: the quick actions the menu bar extra holds.
  override func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    guard !dockItems.isEmpty else { return nil }
    let menu = NSMenu()
    for item in dockItems {
      let entry = NSMenuItem(title: item.label, action: #selector(dockChosen(_:)), keyEquivalent: "")
      entry.target = self
      entry.representedObject = item.id
      menu.addItem(entry)
    }
    return menu
  }

  @objc private func dockChosen(_ item: NSMenuItem) {
    guard let id = item.representedObject as? String else { return }
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
    appChannel?.invokeMethod("dockAction", arguments: id)
  }

  /// Dart's side of `niman/apple_app`.
  func handleApp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "takePendingFiles":
      dartListens = true
      result(pendingFiles)
      pendingFiles = []
    case "setDockMenu":
      let items = call.arguments as? [[String]] ?? []
      dockItems = items.compactMap { $0.count == 2 ? (id: $0[0], label: $0[1]) : nil }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Lets the quit through and terminates.
  func confirmQuit() {
    quitConfirmed = true
    NSApp.terminate(nil)
  }
}
