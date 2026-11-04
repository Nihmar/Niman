/// The phone's full-screen note fading in over the tabs (issue #4; issue
/// #100 moved it out of the shell): the tabs stay painted under the note
/// until it has covered them, and come back at once when it closes.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Whether the tab shell hides under the open note, and when it starts to.
final class ShellNoteFade {
  /// The fade of the note [noteOnScreen] says is open, every change
  /// through [update], the shell's `setState`, while [mounted] holds.
  new({
    required this.noteOnScreen,
    required this.update,
    required this.mounted,
  });

  /// Whether a note is open full screen: the selection is a note and the
  /// tree is not up.
  final bool Function() noteOnScreen;

  /// The shell's `setState`: the layout is drawn from [hidingTabs].
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// The full-note open fade (matches the layout's AnimatedSwitcher).
  static const duration = Duration(milliseconds: 220);

  /// Whether the tab shell stays hidden under the open note. It flips on
  /// only once the open fade has covered it (issue #4): hiding the shell
  /// in the same frame as the open exposes the window background through
  /// the fading note — a black frame in dark mode. Tickers stop at once;
  /// layout and paint follow the fade.
  bool get hidingTabs => _hidingTabs;
  bool _hidingTabs = false;

  /// The pending tab-hide after a note open (canceled on close).
  Timer? _hideTimer;

  /// Guards the pending hide against a rapid close/reopen.
  int _hideRevision = 0;

  /// Records a note open: the tabs stay painted under the fading note
  /// (issue #4, see [hidingTabs]) and hide once it has covered them.
  /// A no-op when they are already hidden (opening another note while one
  /// is open swaps the content opaquely — no fade, nothing to cover).
  void opened() {
    if (_hidingTabs) return;
    _hidingTabs = false;
    _hideTimer?.cancel();
    final token = ++_hideRevision;
    _hideTimer = Timer(duration + const Duration(milliseconds: 40), () {
      _hideTimer = null;
      if (!mounted() || token != _hideRevision) return;
      if (!noteOnScreen()) return;
      update(() => _hidingTabs = true);
    });
  }

  /// Records a note close: the tabs show at once so the fading note
  /// cross-fades over them instead of over the window background.
  void closed() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _hideRevision++;
    _hidingTabs = false;
  }

  /// Lets go of the pending hide.
  void dispose() => _hideTimer?.cancel();
}
