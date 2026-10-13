/// The dead-link offer (issue #78, split out of `note_links.dart`): propose
/// where the missing note would be created, ask, and create it through the
/// library's own path — the same one the tree's New note goes through.
///
/// A Ctrl/Cmd+click (#477) is its own confirmation: the proposal and the
/// creation are the same, only the asking is skipped, so the note lands
/// where an ordinary new note would, and the writer is left in it.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/ui/link_snack.dart';
import 'package:niman/src/ui/missing_note_dialog.dart';
import 'package:niman/src/ui/note_link_targets.dart';
import 'package:niman/src/ui/strings.dart';

/// Offers to create the note [target] names, and opens it through [link]
/// when it was made. A declined offer changes nothing (no error, no second
/// prompt); an impossible one, or a note with nowhere to open, keeps the
/// dead-link outcome's snackbar.
Future<void> offerDeadLink(
  BuildContext context,
  String target,
  NoteLinkTargets link,
) async {
  const log = AppLogger(name: 'links');
  final outcome = await _handleDeadLink(context, target, link);
  log.debug('link outcome: ${describeOutcome(outcome)}');
  if (outcome is DeadLinkCreated) {
    final open = link.onOpenNote;
    if (open == null) {
      if (context.mounted) linkSnack(context, AppStrings.unresolvedLinkTitle);
      return;
    }
    open(outcome.path, null);
  } else if (outcome is DeadLinkNotOffered && context.mounted) {
    linkSnack(context, AppStrings.unresolvedLinkTitle);
  }
  // DeadLinkDeclined: nothing — no error, no second prompt (issue #78).
}

Future<DeadLinkOutcome> _handleDeadLink(
  BuildContext context,
  String target,
  NoteLinkTargets link,
) async {
  final create = link.createMissingNote;
  final root = link.libraryRoot;
  if (create == null || root == null) return const DeadLinkNotOffered();
  final linkContext = LinkContext(
    libraryRoot: root,
    currentNote: link.notePath,
  );
  final handler = MissingNoteHandler(
    location: link.newItemLocation,
    confirm: link.modifier
        ? (_) async => true
        : (path) async {
            // The dialog needs a live context; an unmounted note declines,
            // and a dismiss (outside tap) reads as one.
            if (!context.mounted) return false;
            final confirmed = await showMissingNoteDialog(context, path: path);
            return confirmed ?? false;
          },
    createNote: create,
  );
  try {
    return await handler.handleDeadLink(target, linkContext);
  } on FileSystemException catch (error) {
    // A name on the way is a file, or the disk refuses: nothing was made
    // that the writer can open, and the link stays dead.
    const AppLogger(name: 'links')
        .warning('dead link "$target" not created: $error');
    return const DeadLinkNotOffered();
  }
}

/// A dead-link outcome for the log: `Created: Notes/Foo.md`.
String describeOutcome(DeadLinkOutcome outcome) => switch (outcome) {
  DeadLinkCreated(:final path) => 'created $path',
  DeadLinkDeclined() => 'creation declined — nothing shown',
  DeadLinkNotOffered() => 'no offer — snackbar',
};
