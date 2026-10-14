import 'package:flutter/widgets.dart';

/// The app's Esc, a [DismissIntent], as the first of [actions] that is on
/// answers it: the shell has more than one thing Esc leaves (Zen, the
/// side panel laid over the note), and only one of them shows at a time.
final class DismissChain extends Action<DismissIntent> {
  /// Answers with the first enabled of [actions].
  new(this.actions);

  /// In order of precedence.
  final List<Action<DismissIntent>> actions;

  @override
  bool isEnabled(DismissIntent intent) =>
      actions.any((action) => action.isEnabled(intent));

  @override
  void invoke(DismissIntent intent) {
    for (final action in actions) {
      if (action.isEnabled(intent)) {
        action.invoke(intent);
        return;
      }
    }
  }
}
