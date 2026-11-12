/// Whether the software keyboard is up (#1266), told only when it comes
/// or goes: the window's insets change on every frame of its animation,
/// and nothing that listens here rebuilds for those.
library;

import 'dart:ui' show FlutterView;

import 'package:flutter/widgets.dart';

/// Calls [onChanged] when the keyboard comes up or goes down.
final class SoftKeyboardWatch extends StatefulWidget {
  /// Watches the window [child] is in.
  const new({required this.onChanged, required this.child, super.key});

  /// Told whether the keyboard is up, on each change.
  final ValueChanged<bool> onChanged;

  /// What the watch wraps, untouched.
  final Widget child;

  @override
  State<SoftKeyboardWatch> createState() => _SoftKeyboardWatchState();
}

final class _SoftKeyboardWatchState extends State<SoftKeyboardWatch>
    with WidgetsBindingObserver {
  bool _up = false;
  FlutterView? _view;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _check();

  void _check() {
    final view = _view;
    if (!mounted || view == null) return;
    final up = view.viewInsets.bottom > 0;
    if (up == _up) return;
    _up = up;
    widget.onChanged(up);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
