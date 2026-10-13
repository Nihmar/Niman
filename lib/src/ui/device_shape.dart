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
bool isPhone(BuildContext context) =>
    defaultTargetPlatform == TargetPlatform.android &&
    MediaQuery.sizeOf(context).shortestSide < phoneShortestSide;

/// Whether the shell is the wide one: the rail, the tree and the panes
/// beside each other. A phone never is, whichever way it is turned; any
/// other window is from [wideBreakpoint] up.
///
/// This is the question "which chrome": the rail or the bottom bar, the
/// tabs, Settings as a window, the sheets or the dialogs. A reader asking
/// "is there room for this row" keeps asking the width.
bool isWideShell(BuildContext context) =>
    !isPhone(context) && MediaQuery.sizeOf(context).width >= wideBreakpoint;
