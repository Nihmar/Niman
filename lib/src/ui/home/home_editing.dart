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

  /// Reads the Home again: after an edit elsewhere, or a sync.
  Future<void> load() async {
    final home = await _ops.home;
    _library = home.library;
    onDevice = home.device != null;
    layout = home.device ?? home.library ?? HomeLayout.defaults;
    loaded = true;
    notifyListeners();
  }

  /// Shows [next] at once and writes it where the Home is kept.
  Future<void> change(HomeLayout next) async {
    layout = next;
    notifyListeners();
    await _write(() => _ops.setHome(next, onDevice: onDevice));
    if (!onDevice) _library = next;
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

  /// Puts the default Home back, where the Home is kept.
  Future<void> reset() => change(HomeLayout.defaults);

  /// Runs a write; a failed one is logged and leaves the Home on screen
  /// as it was edited, to be written by the next change.
  Future<void> _write(Future<void> Function() write) async {
    try {
      await write();
    } on Object catch (error) {
      _log.warning('could not save the Home: $error');
    }
  }
}
