/// The wide layout's right-hand pane (#51): the note editor, or a prompt
/// until a note is chosen. Pure props in, [NoteView] out.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

/// Right-hand pane: the note editor, or a prompt until a note is chosen.
final class ShellDetailPane extends StatelessWidget {
  /// Creates the pane; every value arrives as a prop.
  const new({
    required this.root,
    required this.selectedPath,
    required this.selectedIsDir,
    required this.showLineNumbers,
    required this.autofocusEditor,
    required this.linkType,
    required this.indentWidth,
    required this.toolbarLayout,
    required this.splitPreview,
    required this.showPreview,
    required this.showWysiwyg,
    required this.onEditorKindChanged,
    required this.splitFraction,
    required this.onSplitFractionChanged,
    required this.onSplitDragEnd,
    required this.linkSource,
    required this.onOpenNote,
    required this.initialAnchor,
    required this.kindMode,
    required this.onNoteKindChanged,
    required this.unsavedTracker,
    required this.statusActions,
    required this.spellCheck,
    super.key,
  });

  /// Absolute library root; null until the session is ready.
  final String? root;

  /// Library-relative path of the selection.
  final String? selectedPath;

  /// Whether the selection is a folder.
  final bool selectedIsDir;

  /// Editor setting forwards.
  final bool showLineNumbers;

  /// Whether the editor takes focus on open.
  final bool autofocusEditor;

  /// The link format the link button inserts.
  final LinkType linkType;

  /// The indent/outdent width in spaces.
  final int indentWidth;

  /// The arranged formatting toolbar.
  final ToolbarLayout toolbarLayout;

  /// Preview layout (T-M2-08).
  final bool splitPreview;

  /// The editor/preview width share.
  final double splitFraction;

  /// Persists the dragged divider share.
  final ValueChanged<double> onSplitFractionChanged;

  /// Persists the divider share on drag end.
  final VoidCallback onSplitDragEnd;

  /// Editor/preview switch state (T-UI-06): the shared app bar owns it.
  final bool showPreview;

  /// Whether the WYSIWYG surface replaces the source editor (T-WYS-05).
  final bool showWysiwyg;

  /// The status row's editor switch (T-WYS-12); null hides it, which is
  /// what a library with a single enabled editor passes.
  final ValueChanged<EditorKind>? onEditorKindChanged;

  /// Link navigation (T-M3-07).
  final LinkSource? linkSource;

  /// Opens a note from a link, landing on a heading anchor when given.
  final void Function(String path, String? anchor) onOpenNote;

  /// A heading anchor to land on after the note loads.
  final String? initialAnchor;

  /// Note kind mode (T-TK-02).
  final bool kindMode;

  /// Reports the loaded note's kind.
  final void Function(String? type) onNoteKindChanged;

  /// The open notes' unsaved edits (T-PP-11): the detail editor reports
  /// its dirty state here for the window's close guard.
  final UnsavedTracker unsavedTracker;

  /// The view controls forwarded into the note's status row (T-PP-22).
  final List<Widget> statusActions;

  /// The editor's spelling state (T-PP-09).
  final EditorSpellCheck spellCheck;

  @override
  Widget build(BuildContext context) {
    final path = selectedPath;
    final root = this.root;
    final notePath = path == null || selectedIsDir || root == null
        ? null
        : path;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      // The outgoing pane leaves immediately: an editor and its twin must
      // never coexist (same controller).
      layoutBuilder: (currentChild, previousChildren) =>
          currentChild ?? const SizedBox.shrink(),
      child: notePath == null
          ? KeyedSubtree(
              key: const ValueKey('detail-empty'),
              child: Center(child: Text(AppStrings.selectANote)),
            )
          : KeyedSubtree(
              key: ValueKey('detail-note-$notePath'),
              child: NoteView(
                path: p.join(root!, notePath),
                showLineNumbers: showLineNumbers,
                autofocusEditor: autofocusEditor,
                linkType: linkType,
                indentWidth: indentWidth,
                toolbarLayout: toolbarLayout,
                // Wide only: the formatting toolbar sits above the editor
                // (desktop chrome); the phone keeps it under the editor,
                // extending the keyboard.
                toolbarTop: true,
                splitPreview: splitPreview,
                showPreview: showPreview,
                showWysiwyg: showWysiwyg,
                onEditorKindChanged: onEditorKindChanged,
                splitFraction: splitFraction,
                onSplitFractionChanged: onSplitFractionChanged,
                onSplitDragEnd: onSplitDragEnd,
                libraryRoot: root,
                linkSource: linkSource,
                onOpenNote: onOpenNote,
                initialAnchor: initialAnchor,
                kindMode: kindMode,
                onNoteKindChanged: onNoteKindChanged,
                unsavedTracker: unsavedTracker,
                statusActions: statusActions,
                spellCheck: spellCheck,
              ),
            ),
    );
  }
}
