import 'dart:async';

import 'package:niman/src/core/shortcuts.dart';

/// An in-memory [ShortcutService]: the test plays the launcher.
///
/// [launchAction] is the cold-start action the shell consumes when it
/// mounts; [emit] is a tap arriving while it runs.
final class FakeShortcutService implements ShortcutService {
  final StreamController<ShortcutAction> _actions =
      StreamController<ShortcutAction>.broadcast();

  /// The action a cold start was launched with, cleared once consumed.
  ShortcutAction? launchAction;

  /// The last published set, in publish order.
  Map<ShortcutAction, String>? published;

  /// Delivers [action] as a tap on the running app.
  void emit(ShortcutAction action) => _actions.add(action);

  @override
  Stream<ShortcutAction> get actions => _actions.stream;

  @override
  Future<void> publish(Map<ShortcutAction, String> labels) async {
    published = labels;
  }

  @override
  Future<ShortcutAction?> consumeLaunchAction() async {
    final action = launchAction;
    launchAction = null;
    return action;
  }

  @override
  Future<void> dispose() async {
    await _actions.close();
  }
}
