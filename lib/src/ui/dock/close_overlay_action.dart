import 'package:flutter/widgets.dart';

/// Esc closes the side panel while it lies over the note.
final class CloseOverlayAction extends Action<DismissIntent> {
  /// Closes with [_close] while [_shown] says the overlay is up.
  new(this._shown, this._close);

  final bool Function() _shown;
  final VoidCallback _close;

  @override
  bool isEnabled(DismissIntent intent) => _shown();

  @override
  void invoke(DismissIntent intent) => _close();
}
