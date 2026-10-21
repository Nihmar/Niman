#if os(iOS)
  import Flutter
  import UIKit

  /// What an iPhone's scene hands the app, as a Mac's app delegate does:
  ///
  /// - the home screen's quick actions, on `niman/shortcuts` as Android's
  ///   launcher shortcuts (lib/src/core/shortcuts.dart): `publish` sets
  ///   them, `consumeLaunchAction` answers the one the app was started
  ///   with, `shortcut` reports one chosen while it runs;
  /// - the notes the Files app asks it to open, on `niman/apple_app`
  ///   (lib/src/core/apple_app_events.dart): kept until Dart first asks
  ///   (`takePendingFiles`), then sent as `open`.
  final class SceneBridge: NSObject, FlutterSceneLifeCycleDelegate {
    var shortcutChannel: FlutterMethodChannel?
    var appChannel: FlutterMethodChannel?

    private var launchShortcut: String?
    private var pendingFiles: [String] = []
    private var dartTakesFiles = false

    /// The SF Symbol each quick action shows, by its id.
    private static let symbols = [
      "quick_note": "square.and.pencil",
      "journal_today": "calendar",
      "new_todo": "checkmark.circle",
      "new_note": "doc.badge.plus",
      "new_list": "list.bullet",
      "new_voice": "mic",
    ]

    func handleShortcuts(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "publish":
        let specs = call.arguments as? [[String: String]] ?? []
        UIApplication.shared.shortcutItems = specs.compactMap { spec in
          guard let id = spec["id"], let label = spec["label"] else { return nil }
          let icon = Self.symbols[id].map { UIApplicationShortcutIcon(systemImageName: $0) }
          return UIApplicationShortcutItem(
            type: id, localizedTitle: label, localizedSubtitle: nil, icon: icon, userInfo: nil)
        }
        result(nil)
      case "consumeLaunchAction":
        result(launchShortcut)
        launchShortcut = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    func handleApp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "takePendingFiles":
        dartTakesFiles = true
        result(pendingFiles)
        pendingFiles = []
      case "setDockMenu":
        // A Mac's; an iPhone has no Dock menu.
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Launched by a quick action, or by a note opened from Files.
    func scene(
      _ scene: UIScene, willConnectTo session: UISceneSession,
      options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
      if let item = connectionOptions?.shortcutItem {
        launchShortcut = item.type
      }
      if let contexts = connectionOptions?.urlContexts, !contexts.isEmpty {
        open(contexts)
      }
      return false
    }

    // A quick action chosen while the app runs.
    func windowScene(
      _ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
      completionHandler: @escaping (Bool) -> Void
    ) -> Bool {
      shortcutChannel?.invokeMethod("shortcut", arguments: shortcutItem.type)
      completionHandler(true)
      return true
    }

    // A note opened from Files while the app runs.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
      open(URLContexts)
      return true
    }

    /// The files [contexts] name, to Dart or kept until it asks. A note
    /// outside the app's own folders is opened in place: its access is
    /// taken for the app's life, as the editor keeps it open.
    private func open(_ contexts: Set<UIOpenURLContext>) {
      let paths = contexts.map(\.url).filter(\.isFileURL).map { url -> String in
        _ = url.startAccessingSecurityScopedResource()
        return url.path
      }
      guard dartTakesFiles, let channel = appChannel else {
        pendingFiles += paths
        return
      }
      for path in paths {
        channel.invokeMethod("open", arguments: path)
      }
    }
  }
#endif
