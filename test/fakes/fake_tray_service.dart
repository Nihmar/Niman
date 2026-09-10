import 'dart:async';

import 'package:copist/src/core/shortcuts.dart';
import 'package:copist/src/core/tray.dart';

/// An in-memory [TrayService]: the test plays the tray.
///
/// [emit] is a menu tap, [activate] an icon click, and [labels] records
/// what the app asked the tray to offer.
final class FakeTrayService implements TrayService {
  final StreamController<ShortcutAction> _actions =
      StreamController<ShortcutAction>.broadcast();
  final StreamController<void> _activated = StreamController<void>.broadcast();

  /// The last labels the app offered, in order.
  Map<ShortcutAction, String>? labels;

  /// Delivers [action] as a menu tap.
  void emit(ShortcutAction action) => _actions.add(action);

  /// Delivers a click on the icon itself.
  void activate() => _activated.add(null);

  @override
  Stream<ShortcutAction> get actions => _actions.stream;

  @override
  Stream<void> get activated => _activated.stream;

  @override
  Future<void> init(Map<ShortcutAction, String> labels) async {
    this.labels = labels;
  }

  @override
  Future<void> dispose() async {
    await _actions.close();
    await _activated.close();
  }
}
