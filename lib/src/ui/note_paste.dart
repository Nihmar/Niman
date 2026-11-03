/// What a paste into a note does before it is plain text (#1248): cells
/// copied from a spreadsheet, or a CSV file's lines, become a Markdown
/// table, and a snackbar offers the text as it was.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/block_padding.dart';
import 'package:niman/src/markdown/table/clipboard_table.dart';
import 'package:niman/src/ui/note_view_handle.dart' show PastedText;
import 'package:niman/src/ui/strings.dart';

/// The text just before and just after a note's selection, two characters
/// each ([padBlock]'s reading).
typedef SelectionSurroundings = ({String before, String after});

/// A note's paste, asked by the editor before it pastes text: true when it
/// took the clipboard.
final class NotePaste {
  /// A paste into the note the callbacks reach.
  const new({
    required this.canInsert,
    required this.caretInCode,
    required this.surroundings,
    required this.plainText,
    required this.pasteText,
    required this.replacePasted,
    required this.messenger,
  });

  /// Whether the note takes text now.
  final bool Function() canInsert;

  /// Whether the caret is in code, where a paste stays text.
  final bool Function() caretInCode;

  /// The text around the selection, or null when there is no note.
  final SelectionSurroundings? Function() surroundings;

  /// Reads the clipboard's plain text.
  final Future<String?> Function() plainText;

  /// Puts text in place of the selection, one undo step.
  final PastedText? Function(String text) pasteText;

  /// Puts text back in place of a paste, while the note still holds it.
  final void Function(PastedText pasted, String text) replacePasted;

  /// Where the snackbar goes.
  final ScaffoldMessengerState? Function() messenger;

  static const _log = AppLogger(name: 'paste');

  /// Takes the clipboard when it holds a table: true when it did.
  Future<bool> paste() async {
    if (!canInsert() || caretInCode()) return false;
    final text = await plainText();
    if (text == null || text.isEmpty) return false;
    final table = tableFromClipboard(text);
    final around = surroundings();
    if (table == null || around == null) return false;
    final block = padBlock(
      table.toLines().join('\n'),
      before: around.before,
      after: around.after,
    );
    final pasted = pasteText(block);
    if (pasted == null) return false;
    _log.info('table: ${table.columns} columns, ${table.rows.length + 1} rows');
    messenger()
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('paste-table-done'),
          // An action would keep it up until it is dismissed by hand (#508).
          persist: false,
          content: Text(AppStrings.pastedAsTable),
          action: SnackBarAction(
            label: AppStrings.pasteAsText,
            onPressed: () => replacePasted(pasted, text),
          ),
        ),
      );
    return true;
  }
}
