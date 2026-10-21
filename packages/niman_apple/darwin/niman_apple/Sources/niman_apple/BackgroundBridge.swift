#if os(iOS)
  import Flutter
  import UIKit

  /// The time iOS gives work under way once the app leaves the screen, on
  /// `niman/background` (lib/src/core/background_time.dart): a sync or a
  /// capture asks for it with `begin`, which answers a task's id, and lets
  /// it go with `end`. Without one the app is suspended within seconds,
  /// halfway through.
  ///
  /// The scene going to the background takes a short task of its own, so
  /// the work Dart starts then reaches `begin` before the app sleeps.
  final class BackgroundBridge: NSObject, FlutterSceneLifeCycleDelegate {
    /// How long the scene's own task lasts.
    private static let grace: TimeInterval = 3

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "begin":
        let name = call.arguments as? String ?? "niman"
        result(Self.begin(name).rawValue)
      case "end":
        if let id = call.arguments as? Int {
          UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: id))
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
      let task = Self.begin("niman.grace")
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.grace) {
        UIApplication.shared.endBackgroundTask(task)
      }
    }

    /// A background task, ended by the system's expiry if nothing ends it
    /// first: a task still running then would have the app killed.
    private static func begin(_ name: String) -> UIBackgroundTaskIdentifier {
      var task = UIBackgroundTaskIdentifier.invalid
      task = UIApplication.shared.beginBackgroundTask(withName: name) {
        UIApplication.shared.endBackgroundTask(task)
      }
      return task
    }
  }
#endif
