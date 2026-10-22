import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show wideBreakpoint;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_board_view.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_placeholder_view.dart';

/// The kanban kind's body (#1154): the board in the shape of the surface.
///
/// A body [wideBreakpoint] wide on a desktop or a tablet gets the board of
/// columns side by side ([KanbanBoardView]); a phone, and any body narrower
/// than that, gets the placeholder until the phone's board (#1168) takes its
/// place. The shape follows the body's own width, not the window's: beside a
/// pane it is the room the board has that counts.
final class KanbanNoteView extends StatelessWidget {
  /// Shows the board of [text], the note [host] holds.
  const new({required this.text, required this.host, super.key});

  /// The full note text.
  final String text;

  /// The note's window: its text, its edits, its links.
  final NoteKindHost host;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          isPhone(context) || constraints.maxWidth < wideBreakpoint
          ? KanbanPlaceholderView(text: text)
          : KanbanBoardView(text: text, host: host),
    );
  }
}
