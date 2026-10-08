/// A book's text zoomed as a note's is (#538): by a pinch, by the zoom keys
/// (`Ctrl+=`, `Ctrl+-`, `Ctrl+0`, or whatever they were changed to) and by
/// the palette's zoom commands.
///
/// The size is the books' own, the one the look sheet's slider sets
/// ([EpubLook.textScale]): the gestures and the sheet move one value, kept
/// per library as the sheet keeps it. It moves on the note zoom's grid —
/// a pinch on the slider's 5% steps, a key by a 10% step — and stays in
/// the slider's range.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/text_zoom_pinch.dart';

/// Keeps [scale] as the books' text size in [session]'s library, the rest
/// of their look as it was.
Future<void> keepEpubTextScale(LibrarySession session, double scale) async {
  final look = await session.epubLook;
  await session.setEpubLook(
    look.copyWith(textScale: normalizeTextScale(scale)),
  );
}

/// Zooms the books' text: shows each size at once on every open book, and
/// hands the one reached to [keep].
final class EpubTextZoom {
  /// A zoom whose sizes [keep] keeps.
  const new(this.keep);

  /// Keeps a size reached: a key pressed, a pinch's fingers lifted.
  final ValueChanged<double> keep;

  /// The books' text size now.
  static double get scale => EpubLooks.look.textScale;

  /// Puts [scale] on the open books, as the sheet's slider does while it
  /// moves; nothing is kept.
  static void show(double scale) => EpubLooks.apply(
    EpubLooks.look.copyWith(textScale: normalizeTextScale(scale)),
    theme: EpubLooks.theme,
  );

  /// The text [steps] zoom steps larger (smaller when negative), or back
  /// to the shipped size at zero, shown and kept.
  void zoom(int steps) {
    final zoomed = AppTextScales.zoomed(scale, steps);
    show(zoomed);
    keep(zoomed);
  }

  /// The zoom keys, as the user has them, bound to this zoom.
  Map<ShortcutActivator, VoidCallback> get bindings => appShortcutBindings({
    AppCommand.zoomIn: () => zoom(1),
    AppCommand.zoomOut: () => zoom(-1),
    AppCommand.zoomReset: () => zoom(0),
  });

  /// [child] zoomed by a pinch: each step shown at once, the size kept
  /// when the fingers lift.
  Widget pinch(Widget child) => TextZoomPinch(
    scale: () => scale,
    onZoom: (scale, {required done}) {
      show(scale);
      if (done) keep(scale);
    },
    child: child,
  );
}
