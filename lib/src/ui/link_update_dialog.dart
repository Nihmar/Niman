/// The question a rename or a move asks under the library's
/// `LinkUpdate.ask` (#848): how many notes link to what moved, and whether
/// their links are to follow.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks whether the links in [notes] notes are to be rewritten; true to
/// rewrite them. A dismissed dialog leaves them as written: nothing is
/// written to a note that was not agreed to.
///
/// The move itself is already done when this appears, so there is no
/// cancel: the choices are the two things that can happen to the links.
Future<bool> askLinkUpdate(BuildContext context, int notes) async {
  final update = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('link-update-ask'),
      title: Text(AppStrings.linkUpdateAskTitle),
      content: Text(AppStrings.linkUpdateAskBody(notes)),
      actions: [
        TextButton(
          key: const Key('link-update-keep'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppStrings.linkUpdateKeep),
        ),
        TextButton(
          key: const Key('link-update-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppStrings.linkUpdateConfirm),
        ),
      ],
    ),
  );
  return update ?? false;
}
