/// The introduction of Settings → Features, asked for when a library opens
/// (#1109; split out of `shell.dart`).
///
/// A library whose settings carry no `featuresReviewed` opens the Features
/// screen once, by itself — but only for a *normal* open: the library
/// picker, the switcher, the last library at launch. A share, a widget tap,
/// a notification, a reminder, a launcher action, a file or a link from
/// outside opens its own target and leaves the flag as it was, so the
/// prompt waits for the next normal open.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/library/session.dart';

/// Decides, once per shell, whether the introduction is shown.
final class ShellFeaturesIntro {
  /// An introduction over [controller]'s library; [open] shows the screen
  /// and [mounted] says whether the shell is still on screen.
  new({required this.controller, required this.open, required this.mounted});

  /// The open library.
  final LibrarySession controller;

  /// Shows Settings → Features with the introduction above the presets.
  final void Function(FeaturesIntroduction introduction) open;

  /// Whether the shell is still on screen.
  final bool Function() mounted;

  bool _requested = false;

  /// Something from outside asked the shell to open something: this open is
  /// not a normal one, and the introduction waits for the next.
  void requested() => _requested = true;

  /// Whether this open came with a request, so far.
  bool get wasRequested => _requested;

  /// Offers the introduction once the launch requests the shell has asked
  /// for ([launches]: the ones a cold start carries, each of which calls
  /// [requested] when it finds one) have answered, and the first frame has
  /// handed the file a launch was given to the shell.
  ///
  /// The screen opens only when the library has not been through it, and
  /// nothing is written here: the flag is written when the screen is left.
  Future<void> offer(Iterable<Future<void>> launches) async {
    await Future.wait([
      for (final launch in launches) launch.catchError((Object _) {}),
    ]);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted() || _requested) return;
    final introduction = await controller.featuresIntroduction;
    if (!mounted() || _requested) return;
    if (introduction == FeaturesIntroduction.none) return;
    open(introduction);
  }
}
