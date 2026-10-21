import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSDraggingDestination {
  /// The drop target's channel (lib/src/core/drop_in.dart), as the Linux and
  /// Windows runners speak it.
  private var dropChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let messenger = flutterViewController.engine.binaryMessenger

    // The quit channel (lib/src/ui/mac_quit.dart): the app delegate asks
    // over it before terminating, and Dart answers `confirm`.
    let quit = FlutterMethodChannel(name: "niman/quit", binaryMessenger: messenger)
    quit.setMethodCallHandler { call, result in
      guard call.method == "confirm", let app = NSApp.delegate as? AppDelegate else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(nil)
      app.confirmQuit()
    }
    (NSApp.delegate as? AppDelegate)?.quitChannel = quit

    // Finder's files and the Dock menu (lib/src/core/mac_app_events.dart).
    let app = FlutterMethodChannel(name: "niman/mac_app", binaryMessenger: messenger)
    if let delegate = NSApp.delegate as? AppDelegate {
      app.setMethodCallHandler(delegate.handleApp)
      delegate.appChannel = app
    }

    // The window is the drop target: the Flutter view under it takes no
    // drags of its own, so what is dragged over it reaches the window.
    dropChannel = FlutterMethodChannel(name: "niman/drop", binaryMessenger: messenger)
    registerForDraggedTypes([.fileURL, .URL])

    super.awakeFromNib()
  }

  /// The addresses a drag carries: files from Finder, pages from a browser.
  private static func urls(_ info: NSDraggingInfo) -> [URL] {
    let objects = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil)
    return (objects as? [URL]) ?? []
  }

  /// Whether [url] is a web page's address, which a drop captures (#531).
  private static func isWebPage(_ url: URL) -> Bool {
    let scheme = url.scheme?.lowercased()
    return scheme == "http" || scheme == "https"
  }

  func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    let urls = Self.urls(sender)
    let link = !urls.isEmpty && urls.allSatisfy(Self.isWebPage)
    dropChannel?.invokeMethod("dragEntered", arguments: ["link": link])
    return .copy
  }

  func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
    return .copy
  }

  func draggingExited(_ sender: NSDraggingInfo?) {
    dropChannel?.invokeMethod("dragExited", arguments: nil)
  }

  // Files go to Dart as paths ("drop"), web pages as their addresses
  // ("dropLinks"); an address that is neither is named in the log and left
  // out. A drop with nothing openable still reports an empty "drop", so the
  // window says so rather than sitting there (#224).
  func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    var paths: [String] = []
    var links: [String] = []
    for url in Self.urls(sender) {
      if url.isFileURL {
        paths.append(url.path)
      } else if Self.isWebPage(url) {
        links.append(url.absoluteString)
      } else {
        NSLog("drop: %@ is not a local file", url.absoluteString)
      }
    }
    if !links.isEmpty {
      dropChannel?.invokeMethod("dropLinks", arguments: links)
      if paths.isEmpty { return true }
    }
    dropChannel?.invokeMethod("drop", arguments: paths)
    return true
  }
}
