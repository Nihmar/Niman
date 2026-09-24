import 'dart:async';

import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/tray.dart';

/// An in-memory [TrayService]: the test plays the tray.
///
/// [emit] is a menu tap, [activate] an icon click, and [labels] records
/// what the app asked the tray to offer.
final class FakeTrayService implements TrayService {
  final StreamController<ShortcutAction> _actions =
      StreamController<ShortcutAction>.broadcast();
  final StreamController<void> _activated = StreamController<void>.broadcast();
  final StreamController<TrayCommand> _commands =
      StreamController<TrayCommand>.broadcast();

  /// The last labels the app offered, in order.
  Map<ShortcutAction, String>? labels;

  /// Delivers [action] as a menu tap.
  void emit(ShortcutAction action) => _actions.add(action);

  /// The menu's own two labels, as the app offered them (#209).
  String? openLabel;
  String? quitLabel;

  /// Whether the icon made it on screen; a test sets it false to play a
  /// host that declined it.
  @override
  bool shown = true;

  /// Delivers a click on the icon itself.
  void activate() => _activated.add(null);

  /// Delivers a click on the menu's Open or Quit (#209).
  void run(TrayCommand command) => _commands.add(command);

  @override
  Stream<ShortcutAction> get actions => _actions.stream;

  @override
  Stream<void> get activated => _activated.stream;

  @override
  Stream<TrayCommand> get commands => _commands.stream;

  @override
  Future<void> init({
    required Map<ShortcutAction, String> labels,
    required String openLabel,
    required String quitLabel,
  }) async {
    this.labels = labels;
    this.openLabel = openLabel;
    this.quitLabel = quitLabel;
  }

  @override
  Future<void> dispose() async {
    await _actions.close();
    await _activated.close();
    await _commands.close();
  }
}
