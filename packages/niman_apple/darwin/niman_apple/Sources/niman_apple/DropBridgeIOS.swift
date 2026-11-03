#if os(iOS)
  import Flutter
  import UIKit

  /// Files dragged onto Niman from another app on an iPad (#1250): Split
  /// View, Slide Over, Stage Manager. Reported over `niman/drop` as the
  /// desktop runners and Android report theirs — `dragEntered`,
  /// `dragExited`, `drop` with the paths — so the one Dart target
  /// (`lib/src/ui/drop_target.dart`) takes them all.
  ///
  /// The other app hands over item providers; each one's file is copied
  /// into `tmp/drop/` first ([ClipboardFiles.copy]), since only a path is
  /// copied on into the library. A drag that carries only text is not
  /// taken.
  final class DropBridgeIOS: NSObject, FlutterSceneLifeCycleDelegate,
    UIDropInteractionDelegate
  {
    var channel: FlutterMethodChannel?

    // The scene's view is there once it is active: the interaction goes on
    // it then, once.
    func sceneDidBecomeActive(_ scene: UIScene) {
      guard let view = (scene as? UIWindowScene)?.windows.first?.rootViewController?.view
      else { return }
      let taken = view.interactions.contains {
        ($0 as? UIDropInteraction)?.delegate === self
      }
      if !taken {
        view.addInteraction(UIDropInteraction(delegate: self))
      }
    }

    func dropInteraction(
      _ interaction: UIDropInteraction, canHandle session: UIDropSession
    ) -> Bool {
      session.items.contains {
        ClipboardFiles.fileType($0.itemProvider.registeredTypeIdentifiers) != nil
      }
    }

    func dropInteraction(
      _ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession
    ) {
      channel?.invokeMethod("dragEntered", arguments: ["link": false])
    }

    func dropInteraction(
      _ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession
    ) -> UIDropProposal {
      UIDropProposal(operation: .copy)
    }

    func dropInteraction(
      _ interaction: UIDropInteraction, sessionDidExit session: UIDropSession
    ) {
      channel?.invokeMethod("dragExited", arguments: nil)
    }

    func dropInteraction(
      _ interaction: UIDropInteraction, performDrop session: UIDropSession
    ) {
      ClipboardFiles.copy(session.items.map(\.itemProvider), into: "drop") { [weak self] paths in
        self?.channel?.invokeMethod("drop", arguments: paths)
      }
    }
  }
#endif
