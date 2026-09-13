import 'dart:async';

import 'package:niman/src/widget/widget_target.dart';

/// An in-memory [WidgetTargetService]: the test plays the home screen.
///
/// [launchTarget] is the cold-start tap the shell consumes when it
/// mounts; [emit] is a tap arriving while it runs.
final class FakeWidgetTargetService implements WidgetTargetService {
  final StreamController<WidgetTarget> _targets =
      StreamController<WidgetTarget>.broadcast();

  /// The tap a cold start was launched with, cleared once consumed.
  WidgetTarget? launchTarget;

  /// Delivers [target] as a tap on the running app.
  void emit(WidgetTarget target) => _targets.add(target);

  @override
  Stream<WidgetTarget> get targets => _targets.stream;

  @override
  Future<WidgetTarget?> consumeLaunchTarget() async {
    final target = launchTarget;
    launchTarget = null;
    return target;
  }

  @override
  Future<void> dispose() async {
    await _targets.close();
  }
}
