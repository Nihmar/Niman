/// What kind of device the window is on, and so which shell it gets (#849).
///
/// The shell used to pick its shape from the window's width alone, and a
/// phone turned to landscape is 780-915 dp wide: it crossed
/// [wideBreakpoint] and got the desktop's rail, panes and floating
/// Settings, with none of the phone's Back, insets or palette. A phone is a
/// phone on every orientation; the width only says whether a row has room.
library;

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

/// Whether the window is a phone's: Android, with a shortest side under
/// [phoneShortestSide].
///
/// The window, not the display: split-screen hands a tablet a narrow window
/// where the phone layout is right, and DeX or an external display hands a
/// phone a desktop-sized one where it is not. The desktops are never a
/// phone, however small their window is dragged; their shape follows the
/// width ([isWideShell]).
///
/// A [PhoneScope] above [context] answers for the device instead: a
/// floating window lays its pages out as if the panel were the screen, and
/// a tablet's 552 dp-tall panel is not a phone.
bool isPhone(BuildContext context) =>
    PhoneScope.maybeOf(context) ??
    (defaultTargetPlatform == TargetPlatform.android &&
        MediaQuery.sizeOf(context).shortestSide < phoneShortestSide);

/// Carries the answer of [isPhone] past a subtree that resizes its
/// [MediaQuery] (#849).
///
/// The floating windows (Settings, the libraries) hand their pages the
/// panel's size as the screen's, so that a page choosing its shape by
/// width chooses it by the room it has. The device does not shrink with
/// its panel: asked inside one, [isPhone] reads the answer taken outside.
final class PhoneScope extends InheritedWidget {
  /// Fixes [isPhone] to [phone] for [child].
  const new({required this.phone, required super.child, super.key});

  /// What [isPhone] answered where the scope was made.
  final bool phone;

  /// The nearest scope's answer, or null without one.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PhoneScope>()?.phone;

  @override
  bool updateShouldNotify(PhoneScope oldWidget) => phone != oldWidget.phone;
}

/// Whether the shell is the wide one: the rail, the tree and the panes
/// beside each other. A phone never is, whichever way it is turned; any
/// other window is from [wideBreakpoint] up.
///
/// This is the question "which chrome": the rail or the bottom bar, the
/// tabs, Settings as a window, the sheets or the dialogs. A reader asking
/// "is there room for this row" keeps asking the width.
bool isWideShell(BuildContext context) =>
    !isPhone(context) && MediaQuery.sizeOf(context).width >= wideBreakpoint;
