import 'package:niman/src/core/shortcuts.dart';

/// What the command line asked the app to do at start.
///
/// The desktops have no launcher-shortcut API, so the CLI is the shared
/// floor: the four flags map to the same [ShortcutAction]s the Android
/// launcher shortcuts and the tray use, which is what keeps the flows from
/// drifting. A bare argument is a file to open — the P3 single-instance /
/// drag-and-drop slice — and is parsed here but not opened yet.
final class LaunchArgs {
  /// Creates the parsed result (both fields null is an ordinary start).
  const new({this.action, this.openPath});

  /// The launch action a flag asked for, if any.
  final ShortcutAction? action;

  /// A file passed positionally (feeds P3; not opened yet).
  final String? openPath;
}

/// Parses [args] (without the executable name, exactly as `main` receives
/// them) into a [LaunchArgs].
///
/// Unknown flags are ignored rather than refused: a desktop session or a
/// wrapper may add its own (`--ozone-platform`, a portal marker), and
/// failing to start over one would be worse than starting normally. When
/// several action flags appear the first one wins.
LaunchArgs parseLaunchArgs(List<String> args) {
  ShortcutAction? action;
  String? openPath;
  for (final arg in args) {
    if (arg.startsWith('-')) {
      action ??= _flags[arg];
      continue;
    }
    openPath ??= arg;
  }
  return LaunchArgs(action: action, openPath: openPath);
}

const Map<String, ShortcutAction> _flags = {
  '--quick-note': ShortcutAction.quickNote,
  '--new-note': ShortcutAction.newNote,
  '--new-todo': ShortcutAction.newTodo,
  '--new-list': ShortcutAction.newList,
};
