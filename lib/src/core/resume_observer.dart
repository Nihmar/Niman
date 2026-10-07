import 'package:flutter/widgets.dart';

/// Calls [onResume] whenever the app returns to the foreground.
///
/// A plain observer rather than `AppLifecycleListener`, which asserts on
/// the order of lifecycle states and so fails on the shortcuts platforms
/// and tests take (paused straight to resumed).
final class ResumeObserver with WidgetsBindingObserver {
  /// An observer calling [onResume].
  new(this.onResume);

  /// Called on each return to the foreground.
  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
