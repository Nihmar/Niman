import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/keep_awake.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/kinds/slides/slide_place.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slides_present_screen.dart';
import 'package:niman/src/ui/window_controller.dart';

bool _presenting = false;

/// Whether [context] is a phone: Android, and narrow on its short side.
bool isSlidesPhone(BuildContext context) =>
    Platform.isAndroid && MediaQuery.sizeOf(context).shortestSide < 600;

/// Whether [event] is the key presenting runs on, by the map in force
/// (#159): true for [AppCommand.presenterView]'s, false for
/// [AppCommand.presentSlides]', null for neither.
bool? slidesPresentKey(KeyEvent event) {
  final map = AppKeyMap.current.value;
  bool on(AppCommand command) =>
      map.bindingOf(command)?.accepts(event, HardwareKeyboard.instance) ??
      false;
  if (on(AppCommand.presenterView)) return true;
  if (on(AppCommand.presentSlides)) return false;
  return null;
}

/// Presents the slides of the note at [notePath], whose text is [text]
/// (#534): the whole screen for the slide alone, or the presenter view.
///
/// The desktops take the window full screen, Android hides the system
/// bars, and the screen stays on until the talk ends. A phone is turned
/// to landscape for the talk, wherever it was started from — unless
/// [byTurning], the talk the phone started by being turned sideways,
/// which ends when it is turned upright again.
///
/// [window] is the desktop window; Android has none to make full screen.
Future<void> presentSlides(
  BuildContext context, {
  required String text,
  required String notePath,
  required Future<String?> Function(String target) resolveEmbed,
  required WindowController window,
  bool presenter = false,
  bool byTurning = false,
}) async {
  if (_presenting) return;
  final slides = splitSlides(text);
  final phone = isSlidesPhone(context);
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

Future<void> _takeScreen(
  WindowController window, {
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
    await window.setFullScreen(on: on);
  }
  await keepScreenOn(on: on);
}
