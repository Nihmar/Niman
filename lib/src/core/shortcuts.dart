// Launcher quick actions (T-SC-01/02): the actions Android shows when
// the app icon is long-pressed.
//
// The actions are dynamic shortcuts published at app start, so their
// labels come from the app and not from a build-time XML. Each one only
// launches the app with an id attached; the shell then runs the very
// flow the equivalent in-app control runs, so a shortcut can never drift
// from the button it mirrors.

import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A launcher quick action.
///
/// [id] travels over the method channel and identifies the shortcut to
/// the platform, so it is part of the wire format: renaming one renames
/// the published shortcut.
enum ShortcutAction {
  /// Opens the quick note (the Quick note tab).
  quickNote('quick_note'),

  /// Opens the Todo tab's add-task dialog.
  newTodo('new_todo'),

  /// Opens the new-note flow (the Files FAB's "New note").
  newNote('new_note'),

  /// Opens the new list-note flow (the Files FAB's "New list note").
  newList('new_list');

  new(this.id);

  /// The platform-side shortcut id.
  final String id;

  /// The action with this [id], or null (an unknown or absent id: an
  /// older shortcut still pinned to the launcher).
  static ShortcutAction? fromId(String? id) {
    for (final action in ShortcutAction.values) {
      if (action.id == id) return action;
    }
    return null;
  }
}

/// What the shell needs from the launcher's quick-action layer.
///
/// Implemented by [PlatformShortcutService] (Android) and
/// [NoopShortcutService] (elsewhere), plus a fake in widget tests.
abstract interface class ShortcutService {
  /// Publishes exactly [labels], in order: the first entry ranks first,
  /// and a launcher showing fewer than all of them keeps the leading
  /// ones.
  Future<void> publish(Map<ShortcutAction, String> labels);

  /// Shortcut taps arriving while the app runs.
  Stream<ShortcutAction> get actions;

  /// The action a cold start was launched with (once, then null).
  Future<ShortcutAction?> consumeLaunchAction();

  /// Releases resources.
  Future<void> dispose();
}

/// Creates the platform service: launcher shortcuts on Android, a no-op
/// elsewhere (no desktop has the equivalent menu).
///
/// [isAndroid] overrides the host platform so a plain test can cover the
/// branch that does not run here (T-PP-01).
ShortcutService createShortcutService({bool? isAndroid}) {
  if (isAndroid ?? Platform.isAndroid) return PlatformShortcutService();
  return const NoopShortcutService();
}

/// The single shortcut service for the app session.
final shortcutServiceProvider = Provider<ShortcutService>((ref) {
  final service = createShortcutService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Android quick actions over the `copist/shortcuts` method channel.
final class PlatformShortcutService implements ShortcutService {
  /// Creates the service; [channel] is injected in tests.
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('copist/shortcuts') {
    _channel.setMethodCallHandler(_onCall);
  }

  static const AppLogger _log = AppLogger(name: 'shortcuts');

  final MethodChannel _channel;
  final StreamController<ShortcutAction> _actions =
      StreamController<ShortcutAction>.broadcast();

  @override
  Stream<ShortcutAction> get actions => _actions.stream;

  @override
  Future<void> publish(Map<ShortcutAction, String> labels) async {
    final specs = [
      for (final entry in labels.entries)
        <String, String>{'id': entry.key.id, 'label': entry.value},
    ];
    try {
      await _channel.invokeMethod<void>('publish', specs);
    } on PlatformException catch (error) {
      // A launcher that refuses the set is a missing convenience, not a
      // reason to fail the launch.
      _log.warning('publish failed ($error)');
    } on MissingPluginException {
      _log.warning('publish unavailable (no host handler)');
    }
  }

  @override
  Future<ShortcutAction?> consumeLaunchAction() async {
    try {
      final id = await _channel.invokeMethod<String>('consumeLaunchAction');
      return ShortcutAction.fromId(id);
    } on PlatformException catch (error) {
      _log.warning('launch action unavailable ($error)');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// The host forwards a tap that reached an already-running app.
  Future<void> _onCall(MethodCall call) async {
    if (call.method != 'shortcut') return;
    final action = ShortcutAction.fromId(call.arguments as String?);
    if (action == null) {
      _log.warning('unknown shortcut ${call.arguments}');
      return;
    }
    _log.debug('shortcut tapped: ${action.id}');
    _actions.add(action);
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _actions.close();
  }
}

/// The off-Android service: nothing to publish, nothing ever arrives.
final class NoopShortcutService implements ShortcutService {
  /// Creates the no-op service.
  const new();

  @override
  Future<void> publish(Map<ShortcutAction, String> labels) async {}

  @override
  Stream<ShortcutAction> get actions => const Stream<ShortcutAction>.empty();

  @override
  Future<ShortcutAction?> consumeLaunchAction() async => null;

  @override
  Future<void> dispose() async {}
}
