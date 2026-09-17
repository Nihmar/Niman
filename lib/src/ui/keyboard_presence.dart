import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tracks whether a physical keyboard has been seen since launch, for the
/// settings home (issue #104): the keyboard-shortcuts row stays out until
/// one is seen.
///
/// Desktop platforms always have one; on phones and tablets only keys the
/// soft keyboard never sends — modifiers, arrows and the function row —
/// count as the first sign of hardware.
final class KeyboardPresence extends ChangeNotifier {
  /// A physical keyboard has been seen (or the platform always has one).
  bool attached = !Platform.isAndroid && !Platform.isIOS;

  /// The key handler, to hand to [HardwareKeyboard] and back.
  KeyEventCallback? _handler;

  /// Starts listening for keys.
  void listen() {
    final handler = _handler ??= _onKey;
    HardwareKeyboard.instance.addHandler(handler);
  }

  /// Stops listening.
  void stopListening() {
    final handler = _handler;
    if (handler != null) {
      HardwareKeyboard.instance.removeHandler(handler);
    }
    _handler = null;
  }

  /// Claims nothing: the event keeps going to the app's shortcuts.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || attached) {
      return false;
    }
    attached = _hardwareSign(event.logicalKey);
    if (attached) {
      notifyListeners();
    }
    return false;
  }

  /// Keys the soft keyboard never sends: the sign of hardware.
  static final Set<LogicalKeyboardKey> _hardwareKeys = {
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.f1,
    LogicalKeyboardKey.f2,
    LogicalKeyboardKey.f3,
    LogicalKeyboardKey.f4,
    LogicalKeyboardKey.f5,
    LogicalKeyboardKey.f6,
    LogicalKeyboardKey.f7,
    LogicalKeyboardKey.f8,
    LogicalKeyboardKey.f9,
    LogicalKeyboardKey.f10,
    LogicalKeyboardKey.f11,
    LogicalKeyboardKey.f12,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.insert,
  };

  static bool _hardwareSign(LogicalKeyboardKey key) =>
      _hardwareKeys.contains(key);
}
