// How the Windows tray menu is tracked, kept apart from the Win32 calls that
// do it (`core/windows_tray_menu.dart`) so the order they come in can be
// tested on any host.
//
// A notification-area menu owes Windows one thing after it closes: its
// owner's thread has to take a message off its queue. `TrackPopupMenu`'s
// remarks say it plainly — the second time the menu is shown, it "appears and
// then immediately disappears" unless a benign message is posted to the owner
// after the menu returns — and the posted `WM_NULL` only does its work when
// the thread's message loop retrieves it. A window procedure's thread always
// comes back to its loop; the thread this menu runs on has none: it is a
// worker the Dart VM lends to the isolate, which runs one call and goes back
// to the pool. The `WM_NULL` stayed in its queue, the owner was destroyed
// under it, and nothing else posted there was handled either — so once a menu
// had been dismissed, every later one tracked on that worker came up and
// closed again within a frame (12 to 25 ms, `result 0, error 0`), until the
// app was restarted. So the thread is pumped here, while the owner is still
// there to receive what is due to it, and again after it is gone: the worker
// goes back to the pool with nothing waiting in its queue.

/// What opening the menu gave: the chosen item's id, or 0 when it was
/// dismissed, and a line for the log.
typedef TrayMenuChoice = ({int chosen, String report});

/// The Win32 calls tracking the tray menu makes, all on the thread that
/// tracks it. Windows are handles as addresses; 0 is none.
abstract interface class TrayMenuThread {
  /// Makes the menu's owner, a window of this thread: its handle, or 0.
  int createOwner();

  /// `GetLastError`.
  int lastError();

  /// `SetForegroundWindow`: whether [owner] took the foreground.
  bool setForeground(int owner);

  /// `TrackPopupMenu` of [menu] at [x], [y] from [owner]: the chosen item's
  /// id, or 0 when the menu was dismissed.
  int track(int menu, int x, int y, int owner);

  /// Posts `WM_NULL` to [owner].
  void postNull(int owner);

  /// Takes the next message off this thread's queue and dispatches it; false
  /// when there was none waiting.
  bool dispatchOne();

  /// `DestroyWindow`.
  void destroy(int owner);
}

/// Tracks [menu] at [x], [y] on [thread], and leaves the thread's queue empty
/// behind it (see the file's header). [theme] goes into the report.
TrayMenuChoice trackTrayMenu(
  TrayMenuThread thread,
  int menu,
  int x,
  int y, {
  String theme = 'default',
}) {
  final owner = thread.createOwner();
  if (owner == 0) {
    return (chosen: 0, report: 'no owner window (error ${thread.lastError()})');
  }
  try {
    final foreground = thread.setForeground(owner);
    final chosen = thread.track(menu, x, y, owner);
    final error = thread.lastError();
    // The task switch the remarks ask for: posted, then retrieved.
    thread.postNull(owner);
    final handled = _drain(thread);
    return (
      chosen: chosen,
      report:
          'at $x,$y, theme $theme, foreground $foreground, result $chosen, '
          'error $error, handled $handled',
    );
  } finally {
    thread.destroy(owner);
    _drain(thread);
  }
}

/// Dispatches every message waiting on [thread]: how many there were.
int _drain(TrayMenuThread thread) {
  var count = 0;
  while (thread.dispatchOne()) {
    count++;
  }
  return count;
}
