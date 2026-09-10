import 'package:copist/src/ui/window_controller.dart';
import 'package:flutter/foundation.dart';

/// The platform window, recorded instead of driven.
final class FakeWindowController implements WindowController {
  new({this.failInit = false, this.customTitleBar = false});

  /// Makes [init] throw, like a host without the plugin.
  final bool failInit;

  @override
  final bool customTitleBar;

  /// Every prevent flag pushed to the platform, in order.
  final List<bool> preventHistory = [];

  /// How many times the window was closed for real.
  int closeCalls = 0;

  /// How many times the window was brought to the front.
  int showCalls = 0;

  /// The title bar's buttons.
  int minimizeCalls = 0;
  int maximizeCalls = 0;

  /// Whether the window is maximized (the title bar's icon).
  @override
  final ValueNotifier<bool> maximized = ValueNotifier<bool>(false);

  @override
  void Function()? onCloseRequested;

  @override
  Future<void> init() async {
    if (failInit) throw StateError('no window here');
  }

  @override
  Future<void> setPreventClose({required bool prevent}) async {
    preventHistory.add(prevent);
  }

  @override
  Future<void> close() async => closeCalls++;

  @override
  Future<void> show() async => showCalls++;

  @override
  Future<void> applyCustomTitleBar() async {}

  @override
  Future<void> minimize() async => minimizeCalls++;

  @override
  Future<void> toggleMaximize() async => maximizeCalls++;

  @override
  Future<void> dispose() async {}
}
