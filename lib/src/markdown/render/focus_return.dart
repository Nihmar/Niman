/// The keys given back to a note when its window comes back to the front
/// (#539).
///
/// On the desktops the window's own `View` parks the focus on the root
/// scope as the window loses the front, and gives it, as it comes back, to
/// the first control that takes it — not to the note that had it. Flutter
/// would put the focus back where it was suspended, but the view's request
/// comes first and that restore stands down: typing went nowhere until a
/// click on the note.
library;

import 'dart:ui' show ViewFocusEvent, ViewFocusState;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';

/// Watches a surface's [focus] across its window leaving and coming back.
final class FocusReturn with WidgetsBindingObserver {
  /// Gives [focus] back when the window returns, through [restore].
  new({required this.focus, required this.restore});

  /// The surface's focus, read whenever it is needed: the surface may be
  /// handed another node.
  final FocusNode Function() focus;

  /// Takes the keys again: the focus, and the input connection with it —
  /// or the connection alone, when the focus came back on its own.
  final VoidCallback restore;

  static const AppLogger _log = AppLogger(name: 'edit');

  /// Whether the focus was taken from the surface by the window or the app
  /// leaving the front: parked on the root scope, not moved to another
  /// control.
  bool _parked = false;

  /// Starts watching.
  void start() => WidgetsBinding.instance.addObserver(this);

  /// Stops watching.
  void dispose() => WidgetsBinding.instance.removeObserver(this);

  /// The surface's focus changed; call it from its focus callback.
  void focusChanged({required bool hasFocus}) {
    if (hasFocus) {
      _parked = false;
      return;
    }
    final manager = FocusManager.instance;
    _parked = manager.primaryFocus == manager.rootScope;
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    _log.info('window ${event.state.name}: ${_where()}');
    if (event.state == ViewFocusState.focused) _comeBack();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info('app ${state.name}: ${_where()}');
    if (state == AppLifecycleState.resumed) _comeBack();
  }

  /// After the frame the window's own focus request lands in, the note's
  /// focus is taken back — so it is the last word.
  void _comeBack() {
    if (!_parked || !_desktop) return;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (!_parked) return;
        _parked = false;
        _log.info('keys back to the note, from ${_primary()}');
        restore();
      })
      ..scheduleFrame();
  }

  /// Where the keys are, for the log: what a report needs to say which
  /// step lost them.
  String _where() =>
      'parked $_parked, note focused ${focus().hasFocus}, '
      'keys at ${_primary()}';

  static String _primary() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null) return 'nothing';
    if (primary == FocusManager.instance.rootScope) return 'the root';
    return primary.debugLabel ?? primary.runtimeType.toString();
  }

  static bool get _desktop => switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.windows ||
    TargetPlatform.macOS => true,
    _ => false,
  };
}
