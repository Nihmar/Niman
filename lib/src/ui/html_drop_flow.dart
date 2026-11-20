/// Web pages dropped on the window (#1293): the question
/// (`html_drop_dialog.dart`), then what was chosen — the files attached to
/// the note on screen, as a drop always did (#1250), converted into notes
/// (`html_convert_flow.dart`), or both, attached first.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/html_convert_flow.dart';
import 'package:niman/src/ui/html_drop_dialog.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What a drop of web pages does.
final class HtmlDropFlow {
  /// Converts through [convert]; [attach] attaches files to the note on
  /// screen (answering whether a note took them) and [canAttach] says
  /// whether there is one to.
  const new({
    required this.convert,
    required this.attach,
    required this.canAttach,
  });

  /// Converts the pages.
  final HtmlConvertFlow convert;

  /// Attaches files to the note on screen; false when none took them.
  final Future<bool> Function(List<String> paths) attach;

  /// Whether a note is on screen that takes attachments.
  final bool Function() canAttach;

  /// Asks what to do with the pages at [paths], and does it.
  Future<void> run(BuildContext context, List<String> paths) async {
    final choice = await showHtmlDropDialog(
      context,
      paths: paths,
      canAttach: canAttach(),
    );
    if (choice == null || !context.mounted) return;
    if (choice != HtmlDropChoice.convert) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      // The note may have gone while the dialog was up: said, as a drop of
      // anything else is, and the conversion still goes on if it was asked.
      if (!await attach(paths)) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.dropRejected(paths.map(p.basename).join(', ')),
            ),
          ),
        );
      }
    }
    if (choice == HtmlDropChoice.attach || !context.mounted) return;
    await convert.runAll(context, paths);
  }
}
