import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/editor/plain_text.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/note_editor_frame.dart';
import 'package:niman/src/ui/note_view_parts.dart';
import 'package:niman/src/ui/tree_link_drop.dart';
import 'package:path/path.dart' as p;

/// How wide the caret is in Zen mode (#69): thicker, to be found at a
/// glance on a page with nothing else on it.
const double zenCaretWidth = 3;

/// The editor pane as the unified surface (#245, #246).
///
/// The same widget the read mode's engine is built from, in one of its
/// modes:
/// `source` is the note as written, `live` is the same note with the
/// markers hidden and the caret's own revealed — the WYSIWYG the phase 4
/// round is about. Both hold the caret, the motions, the undo history and
/// the windowing, and both report the text and the caret line through
/// [NoteViewParts.noteChanged] — so saving, the preview and the
/// statistics do not know which mode is on screen.
final class NoteSourcePane extends StatelessWidget {
  /// The source pane of the note [parts] hold.
  const new({required this.parts, super.key});

  /// The note view's collaborators.
  final NoteViewParts parts;

  @override
  Widget build(BuildContext context) {
    final surface = parts.session.ensureSurface();
    final buffer = surface.buffer;
    // The fields panel, when the note has a block for it: the same widget the
    // read pane puts above its note, above this one too, so the two surfaces
    // cannot drift (#157).
    final frontmatter = parts.frontmatter.fields();
    // At the *note* text size, as the preview is (T-M6-12): without this the
    // surface drew the note at the interface size, so the note's size setting
    // did nothing. The find bar above it keeps the interface's.
    final live = MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: noteTextScalerOf(context)),
      child: MarkdownSurface(
        viewKey: parts.sourceViewKey,
        buffer: buffer,
        surface: surface,
        lineTokens: plainTextTokensOf(p.basename(parts.view.path)),
        templateCommands: NoteViewParts.templateIn(parts.view),
        wikilinkSuggester: parts.view.services.wikilinkSuggester,
        deadLinks: parts.deadLinks,
        onLinkHover: parts.preview.editorHover,
        onPaste: parts.paste.paste,
        notePath: parts.libraryPath,
        blockAnchors: parts.links.blockAnchors,
        // The shell's own focus node: the phone toolbar, the format keys,
        // save-on-blur and the refocus when the preview goes all ask *it*
        // whether the editor has the focus.
        focusNode: parts.focus,
        // The view keeps the scroll, so the fields panel can tell how far the
        // note has been scrolled from its head (#157).
        controller: parts.sourceScroll,
        mode: parts.unifiedMode,
        // Its metrics at the note's size: this context is above the scaler
        // set just around the surface.
        theme: markdownThemeOf(context, scaler: noteTextScalerOf(context)),
        showLineNumbers: parts.view.options.showLineNumbers && !parts.view.zen,
        // The live pane's overlay children (the code blocks' copy
        // buttons) draw over the whole app: only the pane on stage keeps
        // them.
        onStage: parts.view.active && !NoteViewParts.previewIn(parts.view),
        caretWidth: parts.view.zen ? zenCaretWidth : null,
        typewriter: parts.view.options.typewriter,
        cascadeChecklist: parts.view.options.cascadeChecklist,
        // The keyboard-on-open setting, and a template `{{cursor}}` landing,
        // which always takes the focus (#53).
        autofocus:
            parts.view.options.autofocusEditor ||
            parts.view.initialCaretOffset != null,
        indentWidth: parts.view.options.indentWidth,
        sourceFont: parts.view.options.sourceFont,
        column: parts.view.options.noteColumn,
        formatMenu: parts.commands.formatMenu,
        editorMenu: parts.commands.contextMenu,
        spellCheck: parts.view.services.spellCheck,
        // Only a template is checked: a `{{…}}` in an ordinary note is text
        // like any other (T-TPL-09).
        templateCheck: NoteViewParts.templateIn(parts.view)
            ? parts.templateCheck
            : null,
        activeItems: parts.activeFormats,
        // What `live` draws in place of the source it hides: the formulas
        // and pictures the read view draws, from the same cache and disk.
        mathCache: parts.mathCache,
        embedResolver: parts.links.resolveEmbed,
        findMatches: parts.sourceFind,
        onOpenLink: (kind, raw, href) =>
            unawaited(parts.links.openLinkToken(kind, raw, href)),
        onChanged: (edit) {
          parts.sourceFind.noteEdited();
          parts.noteChanged(
            caretLine: parts.surfaceCaretLine ?? parts.lastCaretLine,
            edit: edit,
          );
        },
        onSelection: (selection) {
          parts.surfaceCaretLine = buffer.lineOf(selection.extent) + 1;
          // In typewriter mode the fields panel rides the caret, not the
          // scroll the follow drives (#522).
          if (parts.view.options.typewriter) parts.frontmatter.scrolled();
        },
      ),
    );
    final note = TodoBlockScope(builder: parts.todoBlocks, child: live);
    // A row of the tree let go on the note writes a link to its file
    // where the pointer let it go (#704).
    final dropping = TreeLinkDrop(
      viewKey: parts.sourceViewKey,
      onDrop: (path) => unawaited(parts.links.insertDroppedLink(path)),
      child: note,
    );
    return NoteEditorFrame(
      find: parts.sourceFind,
      column: parts.view.options.noteColumn,
      frontmatter: frontmatter,
      onKey: parts.findKeys.onKey,
      child: dropping,
    );
  }
}
