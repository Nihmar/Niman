/// Back and forward through the notes shown (#700), and the mouse's two
/// side buttons that ask for it on a desktop.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/shell_workspace.dart';

/// Takes the window back and forward through its [ShellWorkspace.history].
final class NoteHistoryNavigator {
  /// Steps through [workspace]'s history; [missing] answers which of the
  /// paths it is given the disk no longer has, and [show] shows a note the
  /// way the shell shows any other.
  const new({
    required this.workspace,
    required this.missing,
    required this.show,
  });

  /// The window's notes and their history.
  final ShellWorkspace workspace;

  /// The paths among those given that are gone from disk.
  final Future<Set<String>> Function(Iterable<String> paths) missing;

  /// Shows the note at a library-relative path.
  final void Function(String path) show;

  /// Shows the note before, if there is one.
  Future<void> back() => _step(back: true);

  /// Shows the note after, once the history went back.
  Future<void> forward() => _step(back: false);

  /// Shows the next note in that direction the disk still has: a deleted
  /// one leaves the history and the step goes on past it. A note closed
  /// since opens again, in a tab of its own; one open shows its tab.
  Future<void> _step({required bool back}) async {
    final history = workspace.history;
    while (true) {
      final target = back ? history.previous : history.next;
      if (target == null) return;
      final gone = await missing([target]);
      if (gone.contains(target)) {
        history.forget(target);
        continue;
      }
      // Something was shown while the disk answered: step from there.
      if ((back ? history.previous : history.next) != target) continue;
      if (back) {
        history.back();
      } else {
        history.forward();
      }
      if (workspace.value.locate(target) == null) {
        workspace.openNextInNewTab();
      }
      show(target);
      return;
    }
  }
}

/// Answers the mouse's back and forward buttons over [child] — the side
/// buttons a desktop mouse has — with [onBack] and [onForward].
final class MouseHistoryButtons extends StatelessWidget {
  /// The buttons over [child].
  const new({
    required this.onBack,
    required this.onForward,
    required this.child,
    super.key,
  });

  /// The back button was pressed.
  final VoidCallback onBack;

  /// The forward button was pressed.
  final VoidCallback onForward;

  /// What the buttons are heard over.
  final Widget child;

  @override
  Widget build(BuildContext context) => Listener(
    // Heard wherever the pointer is, and passed on: a pane under it still
    // takes the press as its own (it focuses on any button).
    behavior: HitTestBehavior.translucent,
    onPointerDown: (event) {
      if (event.buttons & kBackMouseButton != 0) {
        onBack();
      } else if (event.buttons & kForwardMouseButton != 0) {
        onForward();
      }
    },
    child: child,
  );
}
