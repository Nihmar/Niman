/// The wide layout's right-hand pane (#51): the note editor, or the
/// launcher while no note shows (#1134). Pure props in, [NoteView] out.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/epub/epub_progress.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/detail_deck.dart';
import 'package:niman/src/ui/note_editor_options.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:path/path.dart' as p;

/// Right-hand pane: the note editor, or the launcher while no note shows.
final class ShellDetailPane extends StatelessWidget {
  /// Creates the pane; every value arrives as a prop.
  const new({
    required this.root,
    required this.tabs,
    required this.options,
    required this.barActions,
    required this.onEditorKindChanged,
    required this.kindMode,
    required this.onNoteKindChanged,
    required this.statusActions,
    required this.launcher,
    this.services = const NoteServices(),
    this.caretPath,
    this.caretRequest = 0,
    this.onPasteAsMarkdown,
    this.onMoveToTasks,
    this.reloadToken = 0,
    this.linksFollowed = 0,
    this.onAnnotate,
    this.onConvertBook,
    this.ocr,
    this.marks,
    this.zen = false,
    this.outlineInDock = false,
    this.spellCheckInDock = false,
    this.relatedInDock = false,
    this.onToggleTypewriter,
    this.onMemento,
    this.onLoaded,
    this.onEditedNoteClosed,
    this.header,
    this.shellFocus,
    this.onTabKind,
    this.onEditEpubLook,
    this.onEpubTextScale,
    this.onEpubProgressView,
    this.epubFullScreen,
    super.key,
  });

  /// Told each note's kind (the frontmatter `type`, null for a plain note)
  /// as its view finds it, whichever tab it is in and whichever pane has the
  /// focus: what a pane's own controls are decided by (#1081).
  /// [onNoteKindChanged] is still the focused pane's showing note's alone.
  final void Function(String path, String? kind)? onTabKind;

  /// The node the shell keeps its accelerators on, for the pane to tell the
  /// keyboard is in the shell and hand it to the note that shows (#1074).
  final FocusNode? shellFocus;

  /// What goes above a note, by its library-relative path, or null for
  /// nothing: the journal's strip over an entry (#7).
  final Widget? Function(String path)? header;

  /// Opens the sheet that sets how the books look (#280), from the
  /// button's place.
  final ValueChanged<Rect?>? onEditEpubLook;

  /// Keeps the books' text size a pinch or a zoom key reached (#538).
  final ValueChanged<double>? onEpubTextScale;

  /// Keeps the view of the books' progress line (#1275).
  final ValueChanged<EpubProgressView>? onEpubProgressView;

  /// Which book is read in full screen (#621).
  final ValueNotifier<Object?>? epubFullScreen;

  /// What the open library lends the note (#1257).
  final NoteServices services;

  /// Absolute library root; null until the session is ready.
  final String? root;

  /// The open notes whose editor is mounted (#23): the one showing, and
  /// the ones kept alive behind it.
  final List<DetailTab> tabs;

  /// Receives where a note was left, as its tab goes behind another.
  final void Function(String path, NoteMemento memento)? onMemento;

  /// Told each note's length once it loads.
  final void Function(String path, int length)? onLoaded;

  /// Forwarded to every [NoteView] ([NoteView.onEditedNoteClosed]): the
  /// absolute path of a note edited and closed. Absolute as the view has
  /// it, since the note closed is not always the tab's current one — a
  /// link followed in a tab closes the note it left.
  final void Function(String path)? onEditedNoteClosed;

  /// How the library's settings say the note is edited (#1257).
  final NoteEditorOptions options;

  /// The note's own controls at the end of its top row (#173).
  final List<Widget> barActions;

  /// The note the Files pane last opened (#727): only that tab's note view
  /// is asked, so a tab kept alive behind, or the other pane, is left
  /// where it is.
  final String? caretPath;

  /// How many times the pane has asked that note for the caret.
  final int caretRequest;

  /// The status row's editor switch (T-WYS-12); null hides it, which is
  /// what a library with a single enabled editor passes.
  final ValueChanged<EditorKind>? onEditorKindChanged;

  /// Note kind mode (T-TK-02).
  final bool kindMode;

  /// Whether the panel has the outline, so a note's own row leaves its
  /// outline button out.
  final bool outlineInDock;

  /// See [NoteView.spellCheckInDock]: the panel has the spelling review
  /// too, so the row leaves its spelling button out.
  final bool spellCheckInDock;

  /// See [NoteView.relatedInDock].
  final bool relatedInDock;

  /// Reports the loaded note's kind.
  final void Function(String? type) onNoteKindChanged;

  /// Forwarded to every [NoteView] ([NoteView.onPasteAsMarkdown]).
  final ValueChanged<NoteViewHandle>? onPasteAsMarkdown;

  /// Forwarded to every [NoteView] ([NoteView.onMoveToTasks]).
  final ValueChanged<NoteViewHandle>? onMoveToTasks;

  /// The view controls forwarded into the note's status row (T-PP-22).
  final List<Widget> statusActions;

  /// Zen mode (#69): the notes without their chrome.
  final bool zen;

  /// Flips [NoteEditorOptions.typewriter].
  final VoidCallback? onToggleTypewriter;

  /// External-change reload requests for the open note (home-screen
  /// widget toggles); forwarded to the NoteView.
  final int reloadToken;

  /// Counts the links followed, for a PDF or a book to go back to a link's
  /// place when the same link is followed again (#282).
  final int linksFollowed;

  /// Annotates a place of a book or a PDF in its companion note (#284).
  final void Function(Annotation annotation)? onAnnotate;

  /// Converts a book into notes (#1138), by its absolute path.
  final ValueChanged<String>? onConvertBook;

  /// Recognizes a PDF's or a picture's text (#594); null offers none.
  final OcrFileActions? ocr;

  /// Where the library's books and PDFs were annotated (#285).
  final AnnotationMarkSource? marks;

  /// What the pane shows while no note does: a new tab, or nothing open.
  final Widget launcher;

  @override
  Widget build(BuildContext context) {
    final root = this.root;
    if (root == null) {
      return Center(
        key: const ValueKey('detail-empty'),
        child: Text(AppStrings.selectANote),
      );
    }
    // Over the deck, which stays where it is: the notes kept alive behind
    // a new tab keep their buffer, undo and place.
    return Stack(
      fit: StackFit.expand,
      children: [_deck(root), if (!tabs.any((tab) => tab.active)) launcher],
    );
  }

  /// Every mounted note keeps its place in the stack by its path: a
  /// switch only flips which one shows, and a tab kept alive keeps its
  /// buffer, undo, find and scroll. The ones behind are offstage, with
  /// their tickers (the caret, the spinner) and their keyboard stopped
  /// (#1074).
  Widget _deck(String root) {
    return DetailDeck(
      paneFocused: tabs.every((tab) => tab.focused),
      shellFocus: shellFocus,
      slots: [
        for (final tab in tabs)
          DeckSlot(
            id: tab.path,
            active: tab.active,
            child: _note(root, tab),
            takeFocus: () {
              final Object? state = tab.key?.currentState;
              if (state is NoteViewHandle) state.takeFocus();
            },
          ),
      ],
    );
  }

  Widget _note(String root, DetailTab tab) {
    final view = _view(root, tab);
    // Zen is the note and nothing else: no strip over a journal entry.
    final above = zen ? null : header?.call(tab.path);
    if (above == null) return view;
    return Column(
      children: [
        above,
        Expanded(child: view),
      ],
    );
  }

  Widget _view(String root, DetailTab tab) =>
      isShownAttachment(tab.path, services.features?.value ?? const Features())
      // A picture, a PDF or a book, shown rather than read as a note.
      ? AttachmentView(
          key: tab.key,
          path: p.join(root, tab.path),
          column: options.noteColumn,
          onEditEpubLook: onEditEpubLook,
          onEpubTextScale: onEpubTextScale,
          onEpubProgressView: onEpubProgressView,
          positions: ReadingPositions(root),
          anchor: tab.anchor,
          reloadToken: linksFollowed,
          linkType: options.linkType,
          onAnnotate: onAnnotate,
          onConvertBook: onConvertBook,
          ocr: ocr,
          marks: marks,
          fullScreen: epubFullScreen,
        )
      : _noteView(root, tab);

  Widget _noteView(String root, DetailTab tab) => NoteView(
    // On the view itself, so the dock reaches its state (#175), and a tab
    // moved to the other pane takes its editor along.
    key: tab.key,
    path: p.join(root, tab.path),
    active: tab.active,
    initialMemento: tab.memento,
    movedFrom: tab.movedFrom == null ? null : p.join(root, tab.movedFrom),
    onMemento: onMemento == null
        ? null
        : (_, memento) => onMemento!(tab.path, memento),
    onLoaded: onLoaded == null
        ? null
        : (_, length) => onLoaded!(tab.path, length),
    onEditedNoteClosed: onEditedNoteClosed,
    options: options,
    barActions: barActions,
    caretRequest: tab.path == caretPath ? caretRequest : 0,
    // Wide only: the formatting toolbar sits above the editor (desktop
    // chrome); the phone keeps it under the editor, extending the
    // keyboard.
    toolbarTop: true,
    zen: zen,
    onToggleTypewriter: onToggleTypewriter,
    showPreview: tab.showPreview,
    showWysiwyg: tab.showWysiwyg,
    onEditorKindChanged: onEditorKindChanged,
    services: services,
    initialAnchor: tab.anchor,
    anchorRequests: linksFollowed,
    initialCaretOffset: tab.caret,
    initialFind: tab.find,
    kindMode: kindMode,
    outlineInDock: outlineInDock,
    spellCheckInDock: spellCheckInDock,
    relatedInDock: relatedInDock,
    // Only the note showing in the focused pane tells the shell what
    // kind it is.
    onNoteKindChanged: (kind) {
      onTabKind?.call(tab.path, kind);
      if (tab.active && tab.focused) onNoteKindChanged(kind);
    },
    onPasteAsMarkdown: onPasteAsMarkdown,
    onMoveToTasks: onMoveToTasks,
    statusActions: statusActions,
    reloadToken: reloadToken,
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
    this.key,
    this.focused = true,
    this.anchor,
    this.caret,
    this.find,
    this.movedFrom,
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

  /// Where the note was a moment ago, when its file was renamed or moved:
  /// the tab's editor stays, with its undo (#1076).
  final String? movedFrom;

  /// A heading to land on as it loads (a link's anchor).
  final String? anchor;

  /// Where the caret lands as it loads: a template's `{{cursor}}` (#53).
  final int? caret;

  /// The words a search result matched, for the note to show as it loads
  /// (#1045).
  final List<String>? find;
}
