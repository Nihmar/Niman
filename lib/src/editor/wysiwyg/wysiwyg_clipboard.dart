/// The WYSIWYG surface's clipboard: Markdown in, Markdown out (#165).
///
/// Quill's own clipboard puts `document.getPlainText()` on the system
/// clipboard — the text with every block and inline attribute dropped.
/// That is right for an editor whose document is a Delta. It is wrong for
/// Niman, whose document *is* Markdown: a line that shows as a bullet is
/// `- ` on disk, the source editor copies it as `- `, and the two
/// surfaces have to agree about what leaving the app looks like.
///
/// It also fixes a loss that survives a round trip inside the editor. In
/// a Delta a line's block attribute lives on its **`\n`**, not on its
/// text, so a selection that stops at the end of the last item never
/// includes the newline that says "bullet" — and that item comes back a
/// plain paragraph while every item before it keeps its marker (device
/// report, 2026-09-18). Quill's internal restore does not save it: the
/// delta it keeps is sliced at the same place.
library;

// `ClipboardServiceProvider` is only exported from `internal.dart` and is
// marked experimental; it is the one way to ask what the clipboard holds
// without duplicating the platform bridge. `GuardedClipboardService`
// installs over the same seam.
// ignore_for_file: experimental_member_use

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/internal.dart' show ClipboardServiceProvider;
import 'package:flutter_quill/quill_delta.dart' as qd;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/wysiwyg/markdown_document_codec.dart';

/// Copy, cut and paste for a Quill document that is really Markdown.
final class WysiwygClipboard {
  /// Reads the live document through [controller] — the surface builds a
  /// new one every time a note is opened.
  new({required this.controller, this.codec = const MarkdownDocumentCodec()});

  /// The surface's current controller.
  final quill.QuillController Function() controller;

  /// Markdown <-> Delta, the same codec the note is loaded and saved with.
  final MarkdownDocumentCodec codec;

  static const AppLogger _log = AppLogger(name: 'wysiwyg');
  static const String _nl = '\n';

  /// The selection's Markdown, or null when nothing is selected.
  String? selectionMarkdown() {
    final live = controller();
    final selection = live.selection;
    if (!selection.isValid || selection.isCollapsed) return null;
    final document = live.document;
    final end = _throughLineEnd(document, selection.end);
    final slice = document.toDelta().slice(selection.start, end);
    if (slice.isEmpty) return null;
    final markdown = codec.encode(quill.Document.fromDelta(slice));
    // The last newline was taken because it carries the line's block
    // attribute, not because the writer selected it: it does not belong
    // in what they get back.
    return end == selection.end
        ? markdown
        : _withoutOneTrailingNewLine(markdown);
  }

  /// Puts the selection's Markdown on the clipboard.
  ///
  /// Returns false when there was nothing to copy, so the caller can fall
  /// back to whatever the package would have done.
  Future<bool> copy({bool cut = false}) async {
    final markdown = selectionMarkdown();
    if (markdown == null) return false;
    final live = controller();
    // Read before the clipboard write: a cut deletes what the writer
    // selected, not the newline the copy borrowed.
    final selection = live.selection;
    await Clipboard.setData(ClipboardData(text: markdown));
    _log.debug('${cut ? 'cut' : 'copy'}: ${markdown.length} chars of Markdown');
    if (cut && !live.readOnly) {
      live.replaceText(
        selection.start,
        selection.end - selection.start,
        '',
        TextSelection.collapsed(offset: selection.start),
      );
    }
    return true;
  }

  /// Pastes the clipboard as Markdown, returning whether it did.
  ///
  /// Wired to `QuillClipboardConfig.onClipboardPaste`, which runs before
  /// everything else — so it declines when the clipboard carries an HTML
  /// flavour and lets Quill's rich paste have it: a styled page from a
  /// browser is the package's job and it does it well. Anything else is
  /// text, and in this app text is Markdown.
  Future<bool> paste() async {
    if (await _hasHtml()) return false;
    final text = await _plainText();
    if (text == null || text.isEmpty) return false;
    final live = controller();
    if (live.readOnly || !live.selection.isValid) return false;
    final quill.Document pasted;
    try {
      pasted = codec.decode(text).document;
    } on Object catch (error) {
      // Hostile text is not worth a crash, and the package's plain path
      // is a fine answer for it.
      _log.warning('paste not decoded as Markdown ($error)');
      return false;
    }
    final selection = live.selection;
    final data = _insertable(pasted.toDelta(), plain: text);
    live.replaceText(
      selection.start,
      selection.end - selection.start,
      data,
      null,
    );
    _log.debug('paste: ${text.length} chars as Markdown');
    return true;
  }

  /// The clipboard's plain text, or null when there is none to be had.
  ///
  /// Guarded for the same reason as [_hasHtml], and one of its own:
  /// `Clipboard.getData` casts the platform's answer and throws on a
  /// shape it did not expect. A paste is not worth a crash.
  Future<String?> _plainText() async {
    try {
      return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } on Object catch (error) {
      _log.warning('clipboard text unavailable ($error)');
      return null;
    }
  }

  /// Whether the clipboard carries an HTML flavour.
  ///
  /// Guarded on its own account rather than leaning on
  /// `GuardedClipboardService`, which `main()` installs: a surface that
  /// only pastes when some other file ran first is not a contract worth
  /// having. A probe that cannot answer is read as "no HTML", because
  /// text is what a clipboard almost always holds.
  Future<bool> _hasHtml() async {
    try {
      return await ClipboardServiceProvider.instance.getHtmlText() != null;
    } on Object catch (error) {
      _log.warning('clipboard HTML probe failed ($error)');
      return false;
    }
  }

  /// The end of the line [end] falls on, newline included.
  ///
  /// A Quill document always ends with one, so the search always lands.
  static int _throughLineEnd(quill.Document document, int end) {
    final text = document.toPlainText();
    final next = text.indexOf(_nl, end);
    return next < 0 ? text.length : next + 1;
  }

  static String _withoutOneTrailingNewLine(String markdown) =>
      markdown.endsWith(_nl)
      ? markdown.substring(0, markdown.length - 1)
      : markdown;

  /// What to hand `replaceText`: the delta, or the plain string when the
  /// Markdown turned out to be one unadorned line.
  ///
  /// A document's delta always ends with a newline, and inserting it puts
  /// a line break after the paste. That is right when the text had block
  /// structure — the trailing newline is what carries the last line's
  /// bullet, so trimming it would recreate the very bug this file exists
  /// for. It is wrong for a word dropped into the middle of a sentence,
  /// and a word has nothing to carry.
  static Object _insertable(qd.Delta delta, {required String plain}) {
    if (plain.contains(_nl)) return delta;
    final buffer = StringBuffer();
    for (final op in delta.toList()) {
      final data = op.data;
      // An embed, or anything styled, is structure: it goes in whole.
      if (data is! String || op.attributes != null) return delta;
      buffer.write(data);
    }
    final text = buffer.toString();
    if (!text.endsWith(_nl)) return delta;
    final body = text.substring(0, text.length - 1);
    return body.contains(_nl) ? delta : body;
  }
}
