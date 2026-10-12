/// The desktop window's minimum size (#712, #771).
library;

import 'dart:ui' show Size;

import 'package:niman/src/core/settings/library_settings.dart';

/// What the Windows window's frame takes from its width, in physical
/// pixels (#771).
///
/// `window_manager` (0.5.2) applies a minimum size to `ptMinTrackSize`,
/// which bounds the *outer* window, and in the hidden-title-bar mode the
/// app uses there its `WM_NCCALCSIZE` handler moves the client area's
/// left edge 8 px in and its right edge 8 px back
/// (`windows/window_manager_plugin.cpp`): the Flutter view is 16 physical
/// pixels narrower than the window. The 8 are physical — not scaled by
/// the monitor's DPI — so in logical pixels the frame is `16 / dpr`.
const double windowsFrameWidth = 16;

/// The least height the window keeps: only so it stays usable.
const double minimumWindowHeight = 400;

/// The minimum outer size to ask the window manager for, so the Flutter
/// view at that size is never under [wideBreakpoint] (#712): under it the
/// layout turns into the phone's, and a desktop window is still driven by
/// a mouse.
///
/// Linux is frameless with no inset: the outer width is the view's. On
/// Windows the frame is added at the device pixel ratio of 1, where it is
/// widest in logical pixels: the plugin keeps the logical minimum and
/// scales it by the ratio of whichever monitor the window is on, so a
/// minimum measured at one ratio must hold at every other the window can
/// be dragged to — and at a ratio of 1 or above, `16 / dpr` is at most 16.
Size minimumWindowSize({required bool windows}) => Size(
  wideBreakpoint + (windows ? windowsFrameWidth : 0),
  minimumWindowHeight,
);
