/// The floating windows over the shell (#202, #203; split out of
/// `shell.dart` for #710): Settings and the known libraries, one at a
/// time, and the phone's full-screen library switcher in their place.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/library_window.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_window.dart';
import 'package:niman/src/ui/switch_library_screen.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// Opens the shell's floating windows, one at a time.
final class ShellWindows {
  /// Creates the windows over [controller]'s library.
  new({
    required this.controller,
    required this.spellCheck,
    required this.transcription,
    required this.ocr,
    required this.unsaved,
    required this.wide,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// The spell checker, which Settings edits.
  final EditorSpellCheck spellCheck;

  /// The transcription models, which Settings edits.
  final TranscriptionModels? transcription;

  /// The text recognition install, which Settings edits.
  final OcrInstallation? ocr;

  /// The open notes' unsaved edits, saved before a library switch (#351).
  final UnsavedTracker unsaved;

  /// Whether the window is wide: a floating window there, a page on a
  /// phone.
  final bool Function() wide;

  /// The floating window up over the shell, if any: its key does not open
  /// a second, and a library that closes from inside it takes it down.
  Route<void>? _window;

  /// Pushes [route] as the shell's floating window, unless one is up.
  Future<void> show(BuildContext context, Route<void> route) async {
    if (_window != null) return;
    _window = route;
    try {
      await Navigator.of(context).push(route);
    } finally {
      if (identical(_window, route)) _window = null;
    }
  }

  /// Settings as a floating window (#202), at [target] when one is given
  /// (#229).
  Future<void> openSettings(BuildContext context, {SettingsTarget? target}) =>
      show(
        context,
        settingsWindowRoute(
          context,
          controller: controller,
          spellCheck: spellCheck,
          transcription: transcription,
          ocr: ocr,
          target: target,
        ),
      );

  /// The known libraries: a floating window on a wide window (#203), the
  /// full screen on a phone.
  void switchLibrary(BuildContext context) {
    if (wide()) {
      unawaited(
        show(
          context,
          libraryWindowRoute(context, controller: controller, unsaved: unsaved),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SwitchLibraryScreen(
          controller: controller,
          // The phone screen saves the open notes before it switches
          // (#351), as the library window above does.
          unsaved: unsaved,
          onSwitched: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Takes the floating window down with the shell it was over: a
  /// library closed or switched from inside it (#202, #203). Off the
  /// teardown, which must not change the navigator it runs under.
  void close() {
    final window = _window;
    if (window == null) return;
    scheduleMicrotask(() {
      if (window.isActive) window.navigator?.removeRoute(window);
    });
  }
}
