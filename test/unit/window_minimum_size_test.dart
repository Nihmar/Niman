// #771: at its minimum width the Windows window fell under the wide
// breakpoint, because the minimum bounds the outer window and the frame
// takes 16 physical pixels off the Flutter view.
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/window_minimum_size.dart';

/// The Flutter view's width, in logical pixels, of a Windows window held
/// at [minimum] on a monitor at [dpr], as window_manager 0.5.2 makes it:
/// `WM_GETMINMAXINFO` sets `ptMinTrackSize.x` to the logical minimum times
/// the monitor's ratio, truncated to a LONG, and the hidden title bar's
/// `WM_NCCALCSIZE` takes 8 physical pixels off each side.
double viewWidthAtMinimum(Size minimum, double dpr) {
  final outer = (minimum.width * dpr).truncate();
  return (outer - windowsFrameWidth) / dpr;
}

void main() {
  // The scale steps Windows offers (100 % to 350 %).
  const ratios = [1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 3.0, 3.5];

  test('Windows: the view at the minimum is never under the breakpoint', () {
    final minimum = minimumWindowSize(windows: true);
    for (final dpr in ratios) {
      expect(
        viewWidthAtMinimum(minimum, dpr),
        greaterThanOrEqualTo(wideBreakpoint),
        reason: 'at a device pixel ratio of $dpr',
      );
    }
  });

  test('the breakpoint alone was not enough on Windows', () {
    // What the window asked for before #771: 600 − 16 / dpr.
    const before = Size(wideBreakpoint, minimumWindowHeight);
    expect(viewWidthAtMinimum(before, 1), lessThan(wideBreakpoint));
  });

  test('Linux: frameless, the minimum is the breakpoint itself', () {
    expect(
      minimumWindowSize(windows: false),
      const Size(wideBreakpoint, minimumWindowHeight),
    );
  });
}
