/// The wide layout's right-hand pane (#51): the note editor, or a prompt
/// until a note is chosen. Pure props in, [NoteView] out.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:path/path.dart' as p;

/// Right-hand pane: the note editor, or a prompt until a note is chosen.
final class ShellDetailPane extends StatelessWidget {
  /// Creates the pane; every value arrives as a prop.
  const new({
    required this.root,
    required this.tabs,
    required this.showLineNumbers,
    required this.noteColumn,
    required this.barActions,
    required this.autofocusEditor,
    required this.linkType,
    required this.missingNoteLocation,
    required this.attachmentsFolder,
    required this.indentWidth,
    required this.toolbarLayout,
    required this.onEditorKindChanged,
    required this.splitFraction,
    required this.onSplitFractionChanged,
    required this.onSplitDragEnd,
    required this.linkSource,
    required this.onOpenNote,
    required this.kindMode,
    required this.onNoteKindChanged,
    required this.unsavedTracker,
    required this.statusActions,
    required this.spellCheck,
    this.reloadToken = 0,
    this.zen = false,
    this.onMemento,
    this.onLoaded,
    this.readNote,
    this.writeNote,
    this.saveNote,
    this.createMissingNote,
    super.key,
  });

  /// Absolute library root; null until the session is ready.
  final String? root;

  /// The open notes whose editor is mounted (#23): the one showing, and
  /// the ones kept alive behind it.
  final List<DetailTab> tabs;

  /// Receives where a note was left, as its tab goes behind another.
  final void Function(String path, NoteMemento memento)? onMemento;

  /// Told each note's length once it loads.
  final void Function(String path, int length)? onLoaded;

  /// Test seams, handed to every [NoteView]: a widget test's library is
  /// not on disk.
  final Future<String> Function(String path)? readNote;

  /// See [readNote].
  final Future<void> Function(String path, String content)? writeNote;

  /// Editor setting forwards.
  final bool showLineNumbers;

  /// Where the note's text sits across the pane (issue #171).
  final NoteColumn noteColumn;

  /// The note's own controls at the end of its top row (#173).
  final List<Widget> barActions;

  /// Whether the editor takes focus on open.
  final bool autofocusEditor;

  /// The link format the link button inserts.
  final LinkType linkType;

  /// Where a dead link's new note lands (settings, issue #78).
  final MissingNoteLocation missingNoteLocation;

  /// The folder (library-relative) picked images are copied into.
  final String attachmentsFolder;

  /// The indent/outdent width in spaces.
  final int indentWidth;

  /// The arranged formatting toolbar.
  final ToolbarLayout toolbarLayout;

  /// The editor/preview width share.
  final double splitFraction;

  /// Persists the dragged divider share.
  final ValueChanged<double> onSplitFractionChanged;

  /// Persists the divider share on drag end.
  final VoidCallback onSplitDragEnd;

  /// The status row's editor switch (T-WYS-12); null hides it, which is
  /// what a library with a single enabled editor passes.
  final ValueChanged<EditorKind>? onEditorKindChanged;

  /// Link navigation (T-M3-07).
  final LinkSource? linkSource;

  /// Opens a note from a link, landing on a heading anchor when given.
  final void Function(String path, String? anchor) onOpenNote;

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

  /// Zen mode (#69): the notes without their chrome.
  final bool zen;

  /// External-change reload requests for the open note (home-screen
  /// widget toggles); forwarded to the NoteView.
  final int reloadToken;

  /// The library's note write path, forwarded to the NoteView; null (no
  /// open library) lets the editor write directly.
  final NoteSaver? saveNote;

  /// The dead-link note-creation path (issue #78); null (no open
  /// library) keeps the dead-link snackbar instead of the offer.
  final Future<String> Function(String path)? createMissingNote;

  @override
  Widget build(BuildContext context) {
    final root = this.root;
    if (root == null || !tabs.any((tab) => tab.active)) {
      return Center(
        key: const ValueKey('detail-empty'),
        child: Text(AppStrings.selectANote),
      );
    }
    // Every mounted note keeps its place in the stack by its path: a
    // switch only flips which one shows, and a tab kept alive keeps its
    // buffer, undo, find and scroll. The ones behind are offstage, with
    // their tickers (the caret, the spinner) stopped.
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final tab in tabs)
          Offstage(
            key: ValueKey('detail-note-${tab.path}'),
            offstage: !tab.active,
            child: TickerMode(enabled: tab.active, child: _note(root, tab)),
          ),
      ],
    );
  }

  Widget _note(String root, DetailTab tab) => NoteView(
    // On the view itself, so the dock reaches its state (#175), and a tab
    // moved to the other pane takes its editor along.
    key: tab.key,
    path: p.join(root, tab.path),
    active: tab.active,
    initialMemento: tab.memento,
    onMemento: onMemento == null
        ? null
        : (_, memento) => onMemento!(tab.path, memento),
    onLoaded: onLoaded == null
        ? null
        : (_, length) => onLoaded!(tab.path, length),
    showLineNumbers: showLineNumbers,
    noteColumn: noteColumn,
    barActions: barActions,
    autofocusEditor: autofocusEditor,
    linkType: linkType,
    missingNoteLocation: missingNoteLocation,
    attachmentsFolder: attachmentsFolder,
    indentWidth: indentWidth,
    toolbarLayout: toolbarLayout,
    // Wide only: the formatting toolbar sits above the editor (desktop
    // chrome); the phone keeps it under the editor, extending the
    // keyboard.
    toolbarTop: true,
    zen: zen,
    splitPreview: tab.splitPreview,
    showPreview: tab.showPreview,
    showWysiwyg: tab.showWysiwyg,
    onEditorKindChanged: onEditorKindChanged,
    splitFraction: splitFraction,
    onSplitFractionChanged: onSplitFractionChanged,
    onSplitDragEnd: onSplitDragEnd,
    libraryRoot: root,
    linkSource: linkSource,
    onOpenNote: onOpenNote,
    initialAnchor: tab.anchor,
    kindMode: kindMode,
    // Only the note showing in the focused pane tells the shell what
    // kind it is.
    onNoteKindChanged: tab.active && tab.focused ? onNoteKindChanged : null,
    unsavedTracker: unsavedTracker,
    statusActions: statusActions,
    spellCheck: spellCheck,
    reloadToken: reloadToken,
    saveNote: saveNote,
    createMissingNote: createMissingNote,
    readNote: readNote,
    writeNote: writeNote,
  );
}

/// One mounted note of the deck (#23), with how its tab shows it.
@immutable
final class DetailTab {
  /// The note at [path] (library-relative).
  const new({
    required this.path,
    required this.active,
    required this.memento,
    required this.showWysiwyg,
    required this.showPreview,
    required this.splitPreview,
    this.key,
    this.focused = true,
    this.anchor,
  });

  /// The note's library-relative path.
  final String path;

  /// Whether it is the one showing.
  final bool active;

  /// Whether its pane has the focus.
  final bool focused;

  /// Keeps its editor when the tab moves to the other pane (#23).
  final GlobalKey? key;

  /// Where it was left, for when its editor mounts.
  final NoteMemento memento;

  /// Whether the tab is in the WYSIWYG editor.
  final bool showWysiwyg;

  /// Whether the tab shows its preview.
  final bool showPreview;

  /// Whether editor and preview sit side by side.
  final bool splitPreview;

  /// A heading to land on as it loads (a link's anchor).
  final String? anchor;
}
