import 'package:niman/src/core/shortcuts.dart';
import 'package:path/path.dart' as p;

/// What the command line asked the app to do at start.
///
/// The desktops have no launcher-shortcut API, so the CLI is the shared
/// floor: the four flags map to the same [ShortcutAction]s the Android
/// launcher shortcuts and the tray use, which is what keeps the flows from
/// drifting. A bare argument is a file to open (#41): the desktop's file
/// association launches `niman <file>`, and the file opens the way Open
/// file opens one (#77).
final class LaunchArgs {
  /// Creates the parsed result (both fields null is an ordinary start).
  const new({this.action, this.openPath});

  /// A launch a later instance handed over; anything unreadable in it is
  /// left out.
  factory fromJson(Map<String, Object?> json) => LaunchArgs(
    action: switch (json['action']) {
      final String id => ShortcutAction.fromId(id),
      _ => null,
    },
    openPath: switch (json['open']) {
      final String path when p.isAbsolute(path) => path,
      _ => null,
    },
  );

  /// The launch action a flag asked for, if any.
  final ShortcutAction? action;

  /// A file passed positionally, as an absolute path.
  final String? openPath;

  /// The launch as the first instance receives it from a later one (#41).
  Map<String, Object?> toJson() => {
    if (action case final action?) 'action': action.id,
    'open': ?openPath,
  };
}

/// Parses [args] (without the executable name, exactly as `main` receives
/// them) into a [LaunchArgs].
///
/// Unknown flags are ignored rather than refused: a desktop session or a
/// wrapper may add its own (`--ozone-platform`, a portal marker), and
/// failing to start over one would be worse than starting normally. When
/// several action flags appear the first one wins.
///
/// A file is made absolute against [cwd]: a later launch hands it to an
/// instance that started somewhere else. A `file://` URI, which some file
/// managers pass instead of a path, is read as the path it names.
LaunchArgs parseLaunchArgs(List<String> args, {String? cwd}) {
  ShortcutAction? action;
  String? openPath;
  for (final arg in args) {
    if (arg.startsWith('-')) {
      action ??= _flags[arg];
      continue;
    }
    openPath ??= _pathOf(arg, cwd);
  }
  return LaunchArgs(action: action, openPath: openPath);
}

String? _pathOf(String arg, String? cwd) {
  if (arg.startsWith('file:')) {
    final uri = Uri.tryParse(arg);
    // A file on another host is not a file this process can open.
    if (uri == null || uri.host.isNotEmpty) return null;
    return uri.toFilePath();
  }
  return cwd == null ? arg : p.normalize(p.absolute(cwd, arg));
}

const Map<String, ShortcutAction> _flags = {
  '--quick-note': ShortcutAction.quickNote,
  '--journal-today': ShortcutAction.journalToday,
  '--new-note': ShortcutAction.newNote,
  '--new-todo': ShortcutAction.newTodo,
  '--new-list': ShortcutAction.newList,
  '--new-voice': ShortcutAction.newVoice,
};
