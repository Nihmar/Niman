/// The note kinds a folder's menu creates in place (#997, #1013): one table
/// for the entries both menus show — a folder row's and the tree's
/// background — and for what the chosen one does.
///
/// A kind added here is in both menus and in every place that runs the
/// choice, with nothing else to touch. A list note is left out — it is bound
/// to the list folder — and so are the journal and the capture, each bound
/// to a folder of its own.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/strings.dart';

/// One kind a menu creates inside a folder.
final class CreateKind {
  /// Describes a kind: the menu's [value] for it, the [keySuffix] its keys
  /// share, its [command], its [icon] and [label], and how [create] makes
  /// it.
  const new({
    required this.value,
    required this.command,
    required this.keySuffix,
    required this.icon,
    required this.label,
    required this.create,
  });

  /// What the menu resolves to when this entry is chosen.
  final String value;

  /// The command that makes the same kind: the entry is offered when the
  /// command's feature is on (#1109).
  final AppCommand command;

  /// The rest of the entry's key: `menu-<suffix>` on a row's menu,
  /// `tree-menu-<suffix>` on the tree's background menu.
  final String keySuffix;

  /// The entry's outline icon.
  final IconData icon;

  /// The entry's label, read when a menu is built: it follows the language
  /// in use at that moment, not the one the table was first read in.
  final String Function() label;

  /// Makes the kind in the folder `parent` through the create flow.
  final Future<void> Function(
    ShellCreateFlow flow,
    BuildContext context, {
    required String parent,
  })
  create;
}

/// The kinds, in the order the menus list them.
final List<CreateKind> createKinds = <CreateKind>[
  CreateKind(
    value: 'audio',
    command: AppCommand.newAudioNote,
    keySuffix: 'new-audio-note',
    icon: Icons.mic_outlined,
    label: () => AppStrings.newAudioNoteHere,
    create: (flow, context, {required parent}) =>
        flow.createAudioNote(context, parent: parent),
  ),
  CreateKind(
    value: 'slides',
    command: AppCommand.newSlides,
    keySuffix: 'new-slides',
    icon: Icons.slideshow_outlined,
    label: () => AppStrings.newSlidesHere,
    create: (flow, context, {required parent}) =>
        flow.createSlidesNote(context, parent: parent),
  ),
  CreateKind(
    value: 'flashcards',
    command: AppCommand.newFlashcards,
    keySuffix: 'new-flashcards',
    icon: Icons.style_outlined,
    label: () => AppStrings.newFlashcardsHere,
    create: (flow, context, {required parent}) =>
        flow.createFlashcards(context, parent: parent),
  ),
  CreateKind(
    value: 'kanban',
    command: AppCommand.newKanban,
    keySuffix: 'new-kanban',
    icon: Icons.view_kanban_outlined,
    label: () => AppStrings.newKanbanHere,
    create: (flow, context, {required parent}) =>
        flow.createKanban(context, parent: parent),
  ),
];

/// The kind a menu's [action] chose, or null when it is not one of them.
CreateKind? createKindOf(String? action) {
  for (final kind in createKinds) {
    if (kind.value == action) return kind;
  }
  return null;
}

/// Runs a creating [action] of a menu in [parent] through [flow]: true when
/// it was one of the [createKinds] (and was made), false for any other
/// choice, which the caller runs.
Future<bool> createKindFromMenu(
  String? action,
  ShellCreateFlow flow,
  BuildContext context, {
  required String parent,
}) async {
  final kind = createKindOf(action);
  if (kind == null) return false;
  await kind.create(flow, context, parent: parent);
  return true;
}
