/// Handing a note's file to the OS (issue #76).
///
/// A note is also a file, and sometimes the user wants it where Niman is
/// not: in the file manager, or in whatever application the system opens
/// `.md` with. Both entries sit on the tree row's menu and touch nothing
/// but the OS — the note itself stays open and unchanged.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// What the tree row's OS entries do with a note's file.
enum TreeContextAction {
  /// Shows the file in the OS file manager, selected where the platform
  /// can say which file (Windows always, Linux when a file manager
  /// answers the freedesktop interface).
  openInFileManager,

  /// Hands the file to the OS default application for its type.
  openInDefaultApp,
}

/// How a [TreeContextAction] ended.
enum TreeContextOutcome {
  /// The OS took the file.
  opened,

  /// Nothing is on disk at that path.
  missing,

  /// The platform has no launcher for the action (Android).
  unsupported,

  /// The launcher was there and refused the file.
  failed,
}

/// The OS calls behind [runTreeContextAction], as one seam.
///
/// Real work on a desktop, subclassed in tests: nothing here can run
/// under `flutter test` without opening a window on the host.
base class OsLauncher {
  /// The launcher every non-test caller gets.
  const new();

  /// Opens [path] with the OS default application for its type.
  Future<bool> openFile(String path) => launchUrl(Uri.file(path));

  /// Shows [path] in the OS file manager.
  Future<bool> revealFile(String path) async {
    if (Platform.isWindows) {
      // `explorer` reports exit code 1 even when it opens the window, so
      // its result says nothing: only a failure to start is a failure.
      try {
        await Process.run('explorer', ['/select,$path']);
        return true;
      } on ProcessException {
        return false;
      }
    }
    if (Platform.isLinux) {
      // The freedesktop interface is the only one that can select the
      // file rather than just open its folder; Nautilus, Dolphin, Nemo
      // and Thunar all answer it. Everything else falls back below.
      if (await _showItemsOverDbus(path)) return true;
      try {
        final opened = await Process.run('xdg-open', [p.dirname(path)]);
        return opened.exitCode == 0;
      } on ProcessException {
        return false;
      }
    }
    return false;
  }

  /// Asks the session's file manager to show [path] selected, over the
  /// `org.freedesktop.FileManager1` interface. False when no file
  /// manager answers, or when `dbus-send` is not installed.
  Future<bool> _showItemsOverDbus(String path) async {
    try {
      final shown = await Process.run('dbus-send', [
        '--session',
        '--print-reply',
        '--dest=org.freedesktop.FileManager1',
        '/org/freedesktop/FileManager1',
        'org.freedesktop.FileManager1.ShowItems',
        'array:string:${Uri.file(path)}',
        'string:',
      ]);
      return shown.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}

/// Whether this platform can hand a file to the OS at all.
///
/// Desktop only: Android reaches its files through the system picker,
/// has no file manager to select a path in, and cannot be given a
/// filesystem path for an app to open.
bool get supportsTreeContextActions => Platform.isLinux || Platform.isWindows;

/// Runs [action] on the file at [absolutePath], through [launcher].
///
/// Reports rather than throws: every outcome but [TreeContextOutcome.opened]
/// is something the user is told about, and none of them leaves the note
/// in a different state than before.
Future<TreeContextOutcome> runTreeContextAction(
  String absolutePath,
  TreeContextAction action, {
  OsLauncher launcher = const OsLauncher(),
}) async {
  if (!supportsTreeContextActions) return TreeContextOutcome.unsupported;
  // Off the UI isolate like every other stat in the app: the library may
  // sit on a network share, where one `existsSync` is a round trip.
  final onDisk = await Isolate.run(() => File(absolutePath).existsSync());
  if (!onDisk) return TreeContextOutcome.missing;
  final opened = switch (action) {
    TreeContextAction.openInFileManager => await launcher.revealFile(
      absolutePath,
    ),
    TreeContextAction.openInDefaultApp => await launcher.openFile(absolutePath),
  };
  return opened ? TreeContextOutcome.opened : TreeContextOutcome.failed;
}
