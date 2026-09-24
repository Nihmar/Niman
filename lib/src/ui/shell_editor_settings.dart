/// The library settings the shell paints with (issue #100, split out of
/// `shell.dart`): fourteen loose fields and the eighty-line read that
/// filled them, now one value the shell holds and swaps.
///
/// They are per library and refresh on session events — the settings
/// screen calls `notify()` after a change — so an open editor picks a
/// change up without the note being reopened. Holding them as one value
/// is what makes that cheap to check: the shell rebuilds only when the
/// value it holds is not the value it just read.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/missing_note_handler.dart';

/// What the shell needs to know about the open library to draw it.
@immutable
final class ShellEditorSettings {
  /// Creates a settings value; every field defaults to what a library
  /// that has never been configured reads back as.
  const new({
    this.lineNumbers = true,
    this.noteColumn = const NoteColumn(),
    this.typewriter = false,
    this.autofocusEditor = false,
    this.editorKind = EditorKind.source,
    this.editorsEnabled = const {EditorKind.source, EditorKind.wysiwyg},
    this.linkType = LinkType.wikilink,
    this.missingNoteLocation = MissingNoteLocation.currentFolder,
    this.attachmentsFolder = defaultAttachmentsFolder,
    this.indentWidth = 2,
    this.treeSort = TreeSort.nameAsc,
    this.treeWidth = defaultTreeWidth,
    this.toolbarLayout = ToolbarLayout.defaults,
    this.tidyOnClose = true,
  });

  /// What the shell shows before the first read lands.
  static const ShellEditorSettings defaults = ShellEditorSettings();

  /// Whether the editor shows the row-number column.
  final bool lineNumbers;

  /// Where the note's text sits across its pane (issue #171).
  final NoteColumn noteColumn;

  /// Whether the caret's row keeps to the middle of the editor (#70).
  final bool typewriter;

  /// Whether opening a note raises the keyboard.
  final bool autofocusEditor;

  /// Which editor the library writes in (T-WYS-05).
  final EditorKind editorKind;

  /// Which editors the library offers (T-WYS-03): both, or one alone.
  /// The note's status row switches editors only when both are on.
  final Set<EditorKind> editorsEnabled;

  /// What the editor's link button inserts.
  final LinkType linkType;

  /// Where a dead link's new note lands (issue #78).
  final MissingNoteLocation missingNoteLocation;

  /// The folder new attachments are copied into (issue #56).
  final String attachmentsFolder;

  /// Spaces added per indent level.
  final int indentWidth;

  /// The library tree's sort order (T-UI-03).
  final TreeSort treeSort;

  /// The tree pane's width in the wide layout, dragged and persisted per
  /// library (T-PP-21).
  final double treeWidth;

  /// The editor toolbar the user arranged (T-TB-04).
  final ToolbarLayout toolbarLayout;

  /// Whether a note edited and then closed has its Markdown tidied, as
  /// the "Tidy the Markdown" command does.
  final bool tidyOnClose;

  /// Reads the open library's settings.
  ///
  /// Two of them are answered rather than reported: an `editorsEnabled`
  /// a hand-edited file left empty reads back as both editors, the way
  /// the store reads it, and an `editorKind` the settings screen has
  /// since switched off falls back to an editor the library still
  /// offers — better than stranding the note on a surface that is gone.
  static Future<ShellEditorSettings> read(LibrarySession session) async {
    final lineNumbers = await session.lineNumbersEnabled;
    final readableLineLength = await session.readableLineLength;
    final noteColumnWidth = await session.noteColumnWidth;
    final typewriter = await session.typewriter;
    final autofocus = await session.editorAutofocusEnabled;
    final linkType = await session.linkType;
    final missingNoteLocation = await session.missingNoteLocation;
    final attachmentsFolder =
        await session.ops?.attachmentsFolder ?? defaultAttachmentsFolder;
    final indentWidth = await session.indentWidth;
    final treeSort = await session.treeSort;
    final treeWidth = await session.treeWidth;
    final toolbar = await session.editorToolbar;
    final tidyOnClose = await session.tidyOnClose;
    final editorKind = await session.editorKind;
    final editorsEnabled = await session.enabledEditors;
    final enabled = editorsEnabled.isEmpty
        ? const {EditorKind.source, EditorKind.wysiwyg}
        : editorsEnabled;
    return ShellEditorSettings(
      lineNumbers: lineNumbers,
      noteColumn: NoteColumn(
        enabled: readableLineLength,
        width: noteColumnWidth,
      ),
      typewriter: typewriter,
      autofocusEditor: autofocus,
      editorKind: enabled.contains(editorKind)
          ? editorKind
          : enabled.contains(EditorKind.source)
          ? EditorKind.source
          : EditorKind.wysiwyg,
      editorsEnabled: {...enabled},
      linkType: linkType,
      missingNoteLocation: missingNoteLocation,
      attachmentsFolder: attachmentsFolder,
      indentWidth: indentWidth,
      treeSort: treeSort,
      treeWidth: treeWidth,
      toolbarLayout: ToolbarLayout.parse(toolbar),
      tidyOnClose: tidyOnClose,
    );
  }

  /// A copy with the given fields replaced: what the controls that change
  /// one setting on the spot (the tree sort, the editor switch) hand back
  /// to the shell.
  ///
  /// Every other field is carried over: one that was not came back as its
  /// default, and switching typewriter on once swapped the editor under
  /// the writer (a 246 MB note froze the app).
  ShellEditorSettings copyWith({
    EditorKind? editorKind,
    TreeSort? treeSort,
    double? treeWidth,
    bool? typewriter,
    bool? tidyOnClose,
  }) {
    return ShellEditorSettings(
      lineNumbers: lineNumbers,
      noteColumn: noteColumn,
      typewriter: typewriter ?? this.typewriter,
      autofocusEditor: autofocusEditor,
      editorKind: editorKind ?? this.editorKind,
      editorsEnabled: editorsEnabled,
      linkType: linkType,
      missingNoteLocation: missingNoteLocation,
      attachmentsFolder: attachmentsFolder,
      indentWidth: indentWidth,
      treeSort: treeSort ?? this.treeSort,
      treeWidth: treeWidth ?? this.treeWidth,
      toolbarLayout: toolbarLayout,
      tidyOnClose: tidyOnClose ?? this.tidyOnClose,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShellEditorSettings &&
        lineNumbers == other.lineNumbers &&
        noteColumn == other.noteColumn &&
        typewriter == other.typewriter &&
        autofocusEditor == other.autofocusEditor &&
        editorKind == other.editorKind &&
        setEquals(editorsEnabled, other.editorsEnabled) &&
        linkType == other.linkType &&
        missingNoteLocation == other.missingNoteLocation &&
        attachmentsFolder == other.attachmentsFolder &&
        indentWidth == other.indentWidth &&
        treeSort == other.treeSort &&
        treeWidth == other.treeWidth &&
        tidyOnClose == other.tidyOnClose &&
        // The layout compares by what it is written as: two parses of the
        // same string are two objects.
        toolbarLayout.encode() == other.toolbarLayout.encode();
  }

  @override
  int get hashCode => Object.hash(
    lineNumbers,
    noteColumn,
    typewriter,
    autofocusEditor,
    editorKind,
    Object.hashAllUnordered(editorsEnabled),
    linkType,
    missingNoteLocation,
    attachmentsFolder,
    indentWidth,
    treeSort,
    treeWidth,
    toolbarLayout.encode(),
    tidyOnClose,
  );
}
