import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// What the open note's ⋮ menu can do.
enum NoteMenuAction {
  /// The note's headings (#175): the dock's pane where there is room for
  /// the dock, a sheet on a phone.
  outline,

  /// The note's tags, and the notes that share them.
  tags,

  /// Browse and restore past versions.
  history,

  /// Rename the note.
  rename,

  /// Move the note to another folder.
  move,

  /// Delete the note (into the trash while it is on).
  delete,
}

/// The open note's ⋮ menu (mockup H2): History, Rename, Move, Delete —
/// the file actions, next to the view controls on the note's bar.
final class NoteMenuButton extends StatelessWidget {
  /// A menu reporting the picked action to [onSelected].
  const new({required this.onSelected, super.key});

  /// Called with the action picked.
  final ValueChanged<NoteMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NoteMenuAction>(
      key: const Key('note-menu'),
      tooltip: AppStrings.noteMenuTooltip,
      icon: const Icon(Icons.more_vert),
      onSelected: onSelected,
      itemBuilder: (context) => [
        _item(NoteMenuAction.outline, Icons.toc, AppStrings.outlineTooltip),
        _item(NoteMenuAction.tags, Icons.sell_outlined, AppStrings.tagsTitle),
        _item(
          NoteMenuAction.history,
          Icons.history,
          AppStrings.noteHistoryTitle,
        ),
        _item(
          NoteMenuAction.rename,
          Icons.edit_outlined,
          AppStrings.actionRename,
        ),
        _item(
          NoteMenuAction.move,
          Icons.drive_folder_upload_outlined,
          AppStrings.actionMove,
        ),
        _item(
          NoteMenuAction.delete,
          Icons.delete_outline,
          AppStrings.actionDelete,
        ),
      ],
    );
  }

  PopupMenuItem<NoteMenuAction> _item(
    NoteMenuAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      key: Key('note-menu-${action.name}'),
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
