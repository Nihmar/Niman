import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/keep_awake.dart';
import 'package:niman/src/ui/kinds/slides/slide_place.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slides_present_screen.dart';
import 'package:niman/src/ui/window_controller.dart';

bool _presenting = false;

/// Whether [context] is a phone: Android, and narrow on its short side.
bool isSlidesPhone(BuildContext context) =>
    Platform.isAndroid && MediaQuery.sizeOf(context).shortestSide < 600;

/// Presents the slides of the note at [notePath], whose text is [text]
/// (#534): the whole screen for the slide alone, or the presenter view.
///
/// The desktops take the window full screen, Android hides the system
/// bars, and the screen stays on until the talk ends. A phone is turned
/// to landscape for the talk, wherever it was started from — unless
/// [byTurning], the talk the phone started by being turned sideways,
/// which ends when it is turned upright again.
Future<void> presentSlides(
  BuildContext context, {
  required String text,
  required String notePath,
  required Future<String?> Function(String target) resolveEmbed,
  bool presenter = false,
  bool byTurning = false,
}) async {
  if (_presenting) return;
  final slides = splitSlides(text);
  final phone = isSlidesPhone(context);
  final window = _windowOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  final lockLandscape = phone && !byTurning;
  _presenting = true;
  // The screen is asked for, not waited on: the slide shows at once, and a
  // platform that answers late (or never, as in tests) holds nothing up.
  unawaited(_takeScreen(window, on: true, lockLandscape: lockLandscape));
  try {
    await navigator.push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => SlidesPresentScreen(
          slides: slides,
          place: slidePlaceOf(notePath),
          resolveEmbed: resolveEmbed,
          presenter: presenter,
          touch: Platform.isAndroid,
          exitWhenUpright: phone && byTurning,
        ),
      ),
    );
  } finally {
    unawaited(_takeScreen(window, on: false, lockLandscape: lockLandscape));
    _presenting = false;
  }
}

/// The desktop window, or null where the screen shows no app providers
/// (widget tests) or has no window to make full screen (Android).
WindowController? _windowOf(BuildContext context) {
  if (Platform.isAndroid) return null;
  try {
    return ProviderScope.containerOf(
      context,
      listen: false,
    ).read(windowControllerProvider);
    // Riverpod reports a missing scope only by throwing; its scope widget
    // is private, so there is nothing to look up first.
    // ignore: avoid_catching_errors
  } on StateError {
    return null;
  }
}

Future<void> _takeScreen(
  WindowController? window, {
  required bool on,
  required bool lockLandscape,
}) async {
  if (Platform.isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(
      on ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    if (lockLandscape) {
      await SystemChrome.setPreferredOrientations(
        on
            ? const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : const [],
      );
    }
  } else {
    await window?.setFullScreen(on: on);
  }
  await keepScreenOn(on: on);
}
