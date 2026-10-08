import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:niman/src/ui/window_controller.dart';

/// The platform window, recorded instead of driven.
final class FakeWindowController implements WindowController {
  new({this.failInit = false, this.customTitleBar = false});

  /// Makes [init] throw, like a host without the plugin.
  final bool failInit;

  @override
  final bool customTitleBar;

  /// Every prevent flag pushed to the platform, in order.
  final List<bool> preventHistory = [];

  /// Every caption-button report the title bar made (#169), in order.
  final List<({Rect minimize, Rect maximize, Rect close})> captionButtons = [];

  /// How many times the window was closed for real.
  int closeCalls = 0;

  /// How many times the window was brought to the front.
  int showCalls = 0;

  /// How many times the window was hidden to the tray (#209).
  int hideCalls = 0;

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
  Future<void> hide() async => hideCalls++;

  @override
  Future<void> applyCustomTitleBar() async {}

  @override
  void reportCaptionButtons({
    required Rect minimize,
    required Rect maximize,
    required Rect close,
  }) {
    captionButtons.add((minimize: minimize, maximize: maximize, close: close));
  }

  @override
  Future<void> minimize() async => minimizeCalls++;

  @override
  Future<void> toggleMaximize() async {
    maximizeCalls++;
    maximized.value = !maximized.value;
  }

  @override
  Future<bool> isMaximized() async => maximized.value;

  /// Whether the window was last put in full screen.
  bool fullScreen = false;

  @override
  Future<void> setFullScreen({required bool on}) async => fullScreen = on;

  @override
  Future<void> dispose() async {}
}
