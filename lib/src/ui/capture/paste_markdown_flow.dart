/// Paste as Markdown (#531), from Ctrl+Shift+V, the command palette or the
/// editor's menu: the clipboard's HTML goes into the note as Markdown,
/// linked to its page when the browser said which, and a snackbar offers
/// Undo — which puts the clipboard's plain text in its place.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/capture/paste/clipboard_html.dart';
import 'package:niman/src/capture/paste/paste_markdown.dart';
import 'package:niman/src/capture/paste/platform_clipboard_html.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';

/// Where a paste reads the clipboard: its HTML, and its plain text.
final class PasteServices {
  /// Services reading the HTML with [html] and the text with [plainText].
  const new({required this.html, this.plainText = readPlainClipboard});

  /// Reads the clipboard's HTML, and the page it came from.
  final ClipboardHtmlReader html;

  /// Reads the clipboard's plain text.
  final Future<String?> Function() plainText;
}

/// The clipboard's plain text, as Flutter reads it.
Future<String?> readPlainClipboard() async =>
    (await Clipboard.getData(Clipboard.kTextPlain))?.text;

/// The platform's own clipboard readers — or a test's.
final pasteServicesProvider = Provider<PasteServices>(
  (ref) => PasteServices(html: platformClipboardHtml()),
);

/// Pastes the clipboard into [note] as Markdown, and says so with Undo;
/// with no HTML on the clipboard, pastes its plain text and says nothing.
Future<void> pasteAsMarkdown(
  BuildContext context,
  NoteViewHandle note,
  PasteServices services,
) async {
  if (!note.canInsert) return;
  final clip = await services.html.read();
  final plain = await services.plainText();
  final choice = choosePaste(clip: clip, plain: plain);
  if (choice == null || !context.mounted) return;
  final pasted = note.pasteText(choice.text);
  if (pasted == null || !choice.markdown) return;
  final link = choice.link;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const Key('paste-markdown-done'),
        content: Text(
          link == null
              ? AppStrings.pastedAsMarkdown
              : AppStrings.pastedAsMarkdownWithLink(link.host),
        ),
        action: plain == null || plain.isEmpty
            ? null
            : SnackBarAction(
                label: AppStrings.actionUndo,
                onPressed: () => note.replacePasted(pasted, plain),
              ),
      ),
    );
}
