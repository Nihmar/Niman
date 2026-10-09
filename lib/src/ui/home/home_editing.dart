/// The Home being shown and edited (#535): which layout, whether it is the
/// library's or this device's own, and every change written as it is made.
///
/// One object for the grid's editor and the phone's: both change the same
/// layout through it, and the Home itself shows what it holds.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/library/session.dart';

/// The Home's state, as loaded and as edited.
final class HomeEditing extends ChangeNotifier {
  /// The Home of the library [_ops] act on.
  new(this._ops);

  final NoteOperations _ops;

  static const _log = AppLogger(name: 'home');

  /// The Home shown: this device's own, else the library's, else the
  /// defaults.
  HomeLayout layout = HomeLayout.defaults;

  /// Whether [layout] has been read yet.
  bool loaded = false;

  /// Whether this device keeps its own Home (*Only on this device*).
  bool onDevice = false;

  /// The library's own Home; null while it never was edited.
  HomeLayout? _library;

  /// The writes not landed yet, one after the other: a read waits for
  /// them, or it reads the file from before the last edit (#684).
  Future<void> _writes = Future<void>.value();

  /// Bumped by every edit: what a read begun before one says is stale.
  int _edits = 0;

  bool _disposed = false;

  /// Reads the Home again: after an edit elsewhere, or a sync.
  Future<void> load() async {
    final at = _edits;
    await _writes;
    final home = await _ops.home;
    // Gone (#689), or edited while reading: what was read is older than
    // the Home on screen.
    if (_disposed || at != _edits) return;
    _library = home.library;
    onDevice = home.device != null;
    layout = home.device ?? home.library ?? HomeLayout.defaults;
    loaded = true;
    notifyListeners();
  }

  /// Shows [next] at once and makes the edit where the Home is kept: on
  /// the Home kept there now, which a sync or a rename may have moved on
  /// since it was read, and not over it (#691). What that gives is shown
  /// once written, unless another edit came first.
  Future<void> change(HomeLayout next) async {
    final from = layout;
    final device = onDevice;
    layout = next;
    notifyListeners();
    final at = _edits + 1;
    await _write(() async {
      final kept = await _ops.editHome(from: from, to: next, onDevice: device);
      if (!device) _library = kept;
      if (_disposed || at != _edits || kept == layout) return;
      layout = kept;
      notifyListeners();
    });
  }

  /// Puts the default Home back, where the Home is kept: the whole of it,
  /// whatever the file holds.
  Future<void> reset() async {
    const next = HomeLayout.defaults;
    final device = onDevice;
    layout = next;
    notifyListeners();
    await _write(() => _ops.setHome(next, onDevice: device));
    if (!device) _library = next;
  }

  /// Detaches this device's Home, starting from the one shown.
  Future<void> keepOnDevice() async {
    onDevice = true;
    notifyListeners();
    await _write(() => _ops.setHome(layout, onDevice: true));
  }

  /// Drops this device's own Home for the library's.
  Future<void> useLibrary() async {
    onDevice = false;
    layout = _library ?? HomeLayout.defaults;
    notifyListeners();
    await _write(_ops.clearDeviceHome);
  }

  /// Queues a write behind the ones not landed yet; a failed one is
  /// logged and leaves the Home on screen as it was edited, to be written
  /// by the next change.
  Future<void> _write(Future<void> Function() write) {
    _edits++;
    return _writes = _writes.then((_) async {
      try {
        await write();
      } on Object catch (error) {
        _log.warning('could not save the Home: $error');
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
