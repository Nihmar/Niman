import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_placeholder_view.dart';
import 'package:niman/src/ui/strings.dart';

/// The text a new board is created with: the type and three empty columns,
/// so the format shows itself and a first card has somewhere to go.
String kanbanNoteContent() =>
    '---\ntype: kanban\n---\n\n'
    '## ${AppStrings.kanbanColumnTodo}\n\n'
    '## ${AppStrings.kanbanColumnDoing}\n\n'
    '## ${AppStrings.kanbanColumnDone}\n';

/// The `kanban` note kind (#1154): a board, one column per `##` heading and
/// one card per top-level list item under it.
///
/// The body is a temporary, read-only placeholder: the wide board (#1167)
/// and the phone board (#1168) replace it.
final class KanbanKindGui implements NoteKindGUI {
  @override
  String get type => 'kanban';

  @override
  LibraryFeature get feature => LibraryFeature.kindKanban;

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) =>
      KanbanPlaceholderView(text: host.text);
}
