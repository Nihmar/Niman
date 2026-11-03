import Foundation
import UniformTypeIdentifiers

#if os(iOS)
  import Flutter
  import UIKit
#else
  import AppKit
  import FlutterMacOS
#endif

/// The files on the pasteboard (#1249, lib/src/capture/paste/clipboard_files.dart):
/// `readFiles` answers their paths, an empty list when it holds none.
///
/// On a Mac, Finder's Copy writes file URLs, and the paths are the files'
/// own. On iOS, the Files app and Photos write item providers whose data
/// lives nowhere a path reaches, so each one's file is copied into the
/// app's temporary folder first, under the name it carries.
enum ClipboardFiles {
  static func read(result: @escaping FlutterResult) {
    #if os(iOS)
      readProviders(result: result)
    #else
      let urls =
        NSPasteboard.general.readObjects(
          forClasses: [NSURL.self],
          options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
      result(urls.filter { $0.isFileURL }.map { $0.path })
    #endif
  }

  #if os(iOS)
    /// The type a provider's file is read as: the first it registers that
    /// is data and not text — text pastes as text, and a link copied in a
    /// browser is a link, not a file.
    static func fileType(_ identifiers: [String]) -> String? {
      identifiers.first { identifier in
        guard let type = UTType(identifier) else { return false }
        return type.conforms(to: .data) && !type.conforms(to: .text)
          && !type.conforms(to: .url)
      }
    }

    /// The name a copied file keeps: the one the provider suggests, with
    /// the extension its type or its file has when the name lacks one.
    static func fileName(suggested: String?, file: URL, type: String) -> String {
      var name = (suggested ?? file.deletingPathExtension().lastPathComponent)
        .replacingOccurrences(of: "/", with: "-")
      if name.isEmpty { name = "pasted" }
      let ext =
        file.pathExtension.isEmpty
        ? (UTType(type)?.preferredFilenameExtension ?? "") : file.pathExtension
      if (name as NSString).pathExtension.isEmpty && !ext.isEmpty {
        name += "." + ext
      }
      return name
    }

    static func readProviders(result: @escaping FlutterResult) {
      let board = UIPasteboard.general
      // The types are metadata: asking them does not read the pasteboard,
      // so a text paste is not held up — nor announced twice — by this.
      let hasFile = board.types.contains { fileType([$0]) != nil }
      guard hasFile else {
        result([String]())
        return
      }
      let folder = FileManager.default.temporaryDirectory
        .appendingPathComponent("clipboard", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
      let group = DispatchGroup()
      let lock = NSLock()
      var paths = [Int: String]()
      for (index, provider) in board.itemProviders.enumerated() {
        guard let type = fileType(provider.registeredTypeIdentifiers) else { continue }
        group.enter()
        provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
          defer { group.leave() }
          guard let url else { return }
          let name = fileName(suggested: provider.suggestedName, file: url, type: type)
          let target = folder.appendingPathComponent(index.description, isDirectory: true)
            .appendingPathComponent(name)
          do {
            try FileManager.default.createDirectory(
              at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            // The provider's file is gone once this callback returns.
            try FileManager.default.copyItem(at: url, to: target)
            lock.lock()
            paths[index] = target.path
            lock.unlock()
          } catch {
            NSLog("niman: clipboard file not copied: \(error)")
          }
        }
      }
      group.notify(queue: .main) {
        result(paths.keys.sorted().compactMap { paths[$0] })
      }
    }
  #endif
}
