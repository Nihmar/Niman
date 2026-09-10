import 'package:copist/src/ui/window_controller.dart';

/// The platform window, recorded instead of driven.
final class FakeWindowController implements WindowController {
  new({this.failInit = false});

  /// Makes [init] throw, like a host without the plugin.
  final bool failInit;

  /// Every prevent flag pushed to the platform, in order.
  final List<bool> preventHistory = [];

  /// How many times the window was closed for real.
  int closeCalls = 0;

  /// How many times the window was brought to the front.
  int showCalls = 0;

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
  Future<void> dispose() async {}
}
