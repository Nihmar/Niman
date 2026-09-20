/// Close to tray (#209): whether the window's × hides Niman and leaves
/// it running, and the tray's way of asking for a real quit.
///
/// The tray icon was a decoration before this: closing the window ended
/// the process, so the desktop reminders — which need Niman alive to fire
/// — died with it. With close-to-tray on, the × hides the window, the
/// tray's *Open Niman* brings it back, and its *Quit* is the way out,
/// with the same ask about unsaved notes the × always had.
///
/// Two notifiers rather than a service: the setting is read at start and
/// written by its settings row, the close guard watches it, and the quit
/// is one signal from the tray to that guard. Held statically, like the
/// key map, because the guard sits above the library and the row sits
/// deep inside it.
library;

import 'package:flutter/foundation.dart';

/// The close-to-tray state of this session.
final class CloseToTray {
  const new _();

  /// Whether the × hides the window instead of quitting; false on a
  /// platform with no tray to hide into, and whatever the device's
  /// settings say on the desktops.
  static final ValueNotifier<bool> enabled = ValueNotifier(false);

  /// Bumped when the tray's Quit is chosen: the close guard closes the
  /// window for real, asking about unsaved notes first.
  static final ValueNotifier<int> quitRequests = ValueNotifier(0);

  /// Asks for the real quit.
  static void quit() => quitRequests.value++;
}
