/// What kind of device the window is on, and so which shell it gets (#849).
///
/// The shell used to pick its shape from the window's width alone, and a
/// phone turned to landscape is 780-915 dp wide: it crossed
/// [wideBreakpoint] and got the desktop's rail, panes and floating
/// Settings, with none of the phone's Back, insets or palette. A phone is a
/// phone on every orientation; the width only says whether a row has room.
library;

import 'dart:ui' show FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show wideBreakpoint;

/// The window's shortest side, in dp, from which an Android device is a
/// tablet rather than a phone.
///
/// A device class of its own, not [wideBreakpoint]: that one is a layout
/// floor (the room the rail, the tree and a note need side by side), this
/// one says what is held in the hand. The two are both 600 today and are
/// free to part.
const double phoneShortestSide = 600;

/// Whether the window [view] is a phone's: Android, with a shortest side
/// under [phoneShortestSide].
bool _phoneIn(FlutterView view) =>
    defaultTargetPlatform == TargetPlatform.android &&
    (view.physicalSize / view.devicePixelRatio).shortestSide <
        phoneShortestSide;

/// Whether the window is a phone's: Android, with a shortest side under
/// [phoneShortestSide].
///
/// The window, not the display: split-screen hands a tablet a narrow window
/// where the phone layout is right, and DeX or an external display hands a
/// phone a desktop-sized one where it is not. The desktops are never a
/// phone, however small their window is dragged; their shape follows the
/// width ([isWideShell]).
///
/// It is the app's [View] that is read, not the [MediaQuery]: a subtree may
/// override the [MediaQuery] and lay its pages out as if another size were
/// the screen -- a floating window does, so that its pages choose their
/// shape by the panel -- and none of that is a different device.
///
/// The answer comes from the [DeviceShapeScope] the app mounts at its root,
/// which tells its dependents when the class changes, however the subtree
/// between is built. Without one -- an isolated widget test -- the [View]
/// is read as asked, and the answer does not follow the window; a test
/// that turns the window mounts a scope.
bool isPhone(BuildContext context) =>
    DeviceShapeScope.maybeOf(context) ?? _phoneIn(View.of(context));

/// Tells its subtree whether the window is a phone's ([isPhone]), at the
/// root of the app (#849).
///
/// It listens for the window's metrics itself, so it needs nothing of the
/// [MediaQuery] and no subtree's override of it can make an answer stale.
/// What it publishes is the class, not the size: a resize that keeps the
/// class rebuilds nothing below.
final class DeviceShapeScope extends StatefulWidget {
  /// Mounts the scope over [child]; once, above every route and override.
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  /// The nearest scope's answer, registering the dependency, or null
  /// without one.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DeviceShape>()?.phone;

  /// In debug, checks that [context] is under a scope: the app mounts one
  /// and every screen of it is under it.
  static void debugCheck(BuildContext context) {
    assert(
      context.getInheritedWidgetOfExactType<_DeviceShape>() != null,
      'The app has no DeviceShapeScope at its root: isPhone would answer '
      'once and never follow the window.',
    );
  }

  @override
  State<DeviceShapeScope> createState() => _DeviceShapeScopeState();
}

final class _DeviceShapeScopeState extends State<DeviceShapeScope>
    with WidgetsBindingObserver {
  late bool _phone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The view is the app's window: it changes only if the app is moved
    // to another.
    _phone = _phoneIn(View.of(context));
  }

  @override
  void didChangeMetrics() {
    final phone = _phoneIn(View.of(context));
    if (phone != _phone) setState(() => _phone = phone);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _DeviceShape(phone: _phone, child: widget.child);
}

final class _DeviceShape extends InheritedWidget {
  const new({required this.phone, required super.child});

  final bool phone;

  @override
  bool updateShouldNotify(_DeviceShape oldWidget) => phone != oldWidget.phone;
}

/// Whether the shell is the wide one: the rail, the tree and the panes
/// beside each other. A phone never is, whichever way it is turned; any
/// other window is from [wideBreakpoint] up.
///
/// This is the question "which chrome": the rail or the bottom bar, the
/// tabs, Settings as a window, the sheets or the dialogs. The device half
/// is [isPhone], the window's; the width half is the [MediaQuery]'s, the
/// room this subtree has, which a panel narrows on purpose. A reader asking
/// "is there room for this row" keeps asking the width alone.
bool isWideShell(BuildContext context) =>
    !isPhone(context) && MediaQuery.sizeOf(context).width >= wideBreakpoint;
