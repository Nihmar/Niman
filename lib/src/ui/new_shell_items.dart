/// What the create menu offers — the tree footer's **New** and the touch
/// rail's (#1266) — and the entries that offer it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/menu_row.dart';
import 'package:niman/src/ui/palette/command_features.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/strings.dart';

/// What the tree footer's create menu offers.
enum NewShellItem {
  /// Today's journal entry, made first when there is none (#7).
  journal,

  /// A plain Markdown note.
  note,

  /// A list note (frontmatter type: list) in the list folder.
  listNote,

  /// A voice note (frontmatter type: audio) in the current folder.
  audioNote,

  /// A slides note (frontmatter type: slides) in the current folder.
  slides,

  /// A flashcard deck (frontmatter type: flashcard) in the current folder.
  flashcards,

  /// A Kanban board (frontmatter type: kanban) in the current folder.
  kanban,

  /// A note copied from a template.
  template,

  /// A web page captured as a note (#531).
  captureWebPage,

  /// A folder.
  folder,
}

/// The create menu's entries, those of a [features] that is off left out
/// (#1109) — and the divider that set the journal apart with them: the
/// tree footer's **New**, and the touch rail's (#1266).
List<PopupMenuEntry<NewShellItem>> newShellItemEntries(
  BuildContext context,
  Features features,
) {
  bool offers(AppCommand command) => commandFeatureOn(command, features);
  return [
    // The one thing done every day (#7), set apart like the FAB's.
    if (offers(AppCommand.journalToday)) ...[
      _item(
        context,
        NewShellItem.journal,
        Icons.today_outlined,
        AppStrings.journalFabToday,
        key: const Key('journal-today-action'),
      ),
      menuDivider(context),
    ],
    _item(
      context,
      NewShellItem.note,
      Icons.note_add_outlined,
      AppStrings.newNoteTitle,
      key: const Key('new-note-action'),
    ),
    if (offers(AppCommand.newListNote))
      _item(
        context,
        NewShellItem.listNote,
        Icons.checklist_outlined,
        AppStrings.newListNoteTitle,
        key: const Key('new-list-note-action'),
      ),
    if (offers(AppCommand.newAudioNote))
      _item(
        context,
        NewShellItem.audioNote,
        Icons.mic_outlined,
        AppStrings.newAudioNoteTitle,
        key: const Key('new-audio-note-action'),
      ),
    if (offers(AppCommand.newSlides))
      _item(
        context,
        NewShellItem.slides,
        Icons.slideshow_outlined,
        AppStrings.newSlidesTitle,
        key: const Key('new-slides-action'),
      ),
    if (offers(AppCommand.newFlashcards))
      _item(
        context,
        NewShellItem.flashcards,
        Icons.style_outlined,
        AppStrings.newFlashcardsTitle,
        key: const Key('new-flashcards-action'),
      ),
    if (offers(AppCommand.newKanban))
      _item(
        context,
        NewShellItem.kanban,
        Icons.view_kanban_outlined,
        AppStrings.newKanbanTitle,
        key: const Key('new-kanban-action'),
      ),
    if (features.isOn(LibraryFeature.templates))
      _item(
        context,
        NewShellItem.template,
        Icons.file_copy_outlined,
        AppStrings.newFromTemplateTitle,
        key: const Key('new-from-template-action'),
      ),
    if (offers(AppCommand.captureWebPage))
      _item(
        context,
        NewShellItem.captureWebPage,
        Icons.language_outlined,
        AppStrings.captureWebPage,
        key: const Key('capture-web-page-action'),
      ),
    menuDivider(context),
    _item(
      context,
      NewShellItem.folder,
      Icons.create_new_folder_outlined,
      AppStrings.newFolderTitle,
      key: const Key('new-folder-action'),
    ),
  ];
}

/// One entry of the create menu.
PopupMenuItem<NewShellItem> _item(
  BuildContext context,
  NewShellItem item,
  IconData icon,
  String label, {
  Key? key,
}) {
  return menuItem<NewShellItem>(
    context,
    key: key,
    value: item,
    child: MenuRow(icon: icon, label: label),
  );
}
