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

/// The size of the window the platform gave the app, in dp: what the
/// device is, as opposed to the room a subtree has.
///
/// It is read from the app's [View], not from [MediaQuery]: a subtree may
/// override the [MediaQuery] and lay its pages out as if another size were
/// the screen -- a floating window does, so that its pages choose their
/// shape by the panel -- and none of that is a different device. The
/// [View] is the window itself, so rotation, a foldable, split-screen and
/// DeX all move it.
///
/// A [View] says nothing when its metrics change, and a widget asking has
/// to be rebuilt when they do, so this also depends on the [MediaQuery]
/// nearest [context], whose size moves with the window; only the
/// dependency is taken from it, never the value.
Size deviceWindowSize(BuildContext context) {
  final room = MediaQuery.maybeSizeOf(context);
  final view = View.maybeOf(context);
  if (view == null) return room ?? Size.zero;
  return view.physicalSize / view.devicePixelRatio;
}

/// Whether the window is a phone's: Android, with a shortest side under
/// [phoneShortestSide].
///
/// The window, not the display: split-screen hands a tablet a narrow window
/// where the phone layout is right, and DeX or an external display hands a
/// phone a desktop-sized one where it is not. The desktops are never a
/// phone, however small their window is dragged; their shape follows the
/// width ([isWideShell]).
///
/// The answer is the device's wherever it is asked ([deviceWindowSize]):
/// inside a subtree that overrides its [MediaQuery] it is the same as
/// outside.
bool isPhone(BuildContext context) =>
    defaultTargetPlatform == TargetPlatform.android &&
    deviceWindowSize(context).shortestSide < phoneShortestSide;

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
