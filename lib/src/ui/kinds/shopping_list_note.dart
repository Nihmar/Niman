import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/list_note.dart';

/// The `shopping-list` note kind (#309): the list body with a quantity
/// per item.
///
/// A subtype of `list`, reached from the open list note's ⋮ menu and
/// never from the create menu: the file is the same, the lines are the
/// same, and only the frontmatter's `type` tells the body to read (and
/// write) the `×2` a shopping item may carry.
final class ShoppingListKindGui implements NoteKindGUI {
  @override
  String get type => 'shopping-list';

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) {
    return ListNoteView(
      text: host.text,
      onChanged: host.applyEdit,
      shopping: true,
    );
  }
}
