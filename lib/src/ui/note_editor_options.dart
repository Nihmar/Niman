import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/library_config.dart'
    show defaultSourceFont;
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/library/new_item_folder.dart';

/// How the library's settings say a note is edited (#1257): one value the
/// shell reads once and every note view takes, in place of fourteen loose
/// arguments repeated wherever a note is shown.
@immutable
final class NoteEditorOptions {
  /// The options a library's settings give.
  const new({
    required this.showLineNumbers,
    required this.autofocusEditor,
    this.noteColumn = NoteColumn.off,
    this.linkType = LinkType.wikilink,
    this.newItemLocation = NewItemLocation.openNoteFolder,
    this.attachmentsFolder = defaultAttachmentsFolder,
    this.templateFolder,
    this.indentWidth = 2,
    this.sourceFont = defaultSourceFont,
    this.toolbarLayout = ToolbarLayout.defaults,
    this.typewriter = false,
    this.cascadeChecklist = true,
    this.frontmatterPanel = true,
    this.linkPreview = true,
  });

  /// Whether the editor shows the row-number column (settings toggle).
  final bool showLineNumbers;

  /// Whether the editor shows the keyboard on open (settings toggle).
  final bool autofocusEditor;

  /// Where the note's text sits across the pane (issue #171): both
  /// editors, the preview, the toolbar, the find bars and the status row
  /// keep to it.
  final NoteColumn noteColumn;

  /// The link format the link button inserts (settings).
  final LinkType linkType;

  /// Where a note created from a dead link lands (settings, issue #78).
  final NewItemLocation newItemLocation;

  /// The folder (library-relative) picked images are copied into
  /// (settings, issue #56).
  final String attachmentsFolder;

  /// The folder (library-relative) of the library's templates (settings):
  /// a note in it has its template commands coloured in the source. Null
  /// colours none.
  final String? templateFolder;

  /// The indent/outdent width in spaces (settings).
  final int indentWidth;

  /// The face the source pane is set in (settings, issue #259).
  final SourceFont sourceFont;

  /// The toolbar the user arranged (settings, T-TB-04): which buttons
  /// show and in what order.
  final ToolbarLayout toolbarLayout;

  /// Typewriter mode (#70): the caret's row keeps to the middle of the
  /// editor, in both editors. Independent of Zen: either may be on without
  /// the other.
  final bool typewriter;

  /// Whether ticking a checklist item ticks the tasks nested under it
  /// (#326), in the live editor and in the read view alike.
  final bool cascadeChecklist;

  /// Whether the note's frontmatter is drawn as the properties panel above
  /// it (settings toggle, #157). Off, the note is its own text in both
  /// surfaces.
  final bool frontmatterPanel;

  /// Whether hovering a link — with Ctrl (⌘) held in the editor — or
  /// pressing and holding it in the read view on a touch screen previews
  /// the note it points at (settings, #846).
  final bool linkPreview;
}
