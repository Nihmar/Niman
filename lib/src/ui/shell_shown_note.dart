import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/note_editor_keys.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/note_view_memento.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_settings.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/workspace/note_memento.dart';

/// The note on screen, as the shell's commands, menus and panels ask
/// after it (#1256): which it is, how its tab shows it, and the view that
/// edits it. On a wide window it is the showing tab, whatever the tree has
/// selected (a folder leaves the tabs alone); on a phone the selection.
final class ShellShownNote {
  /// The note [workspace] and [selection] put on screen.
  new({
    required this.workspace,
    required this.selection,
    required this.settings,
    required this.features,
    required this.wide,
  });

  /// The panes and their tabs.
  final ShellWorkspace workspace;

  /// What is selected.
  final ShellSelection selection;

  /// The editors the library offers, and the one it opens in.
  final ShellSettings settings;

  /// The library's features: a kind that is off is no attachment.
  final Features Function() features;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// One key per mounted note of the panes: a tab moved to the other
  /// pane, or a note renamed, takes its editor along — undo and all
  /// (#1076).
  final NoteEditorKeys keys = NoteEditorKeys();

  /// The phone's one note view, so its sheets reach its outline.
  final GlobalKey phoneKey = GlobalKey();

  /// The note on screen (library-relative), if one is.
  String? get path => wide()
      ? workspace.value.activePath
      : (selection.isDir ? null : selection.path);

  /// Whether the note on screen is a picture, a PDF or a book: shown by
  /// the pane rather than edited, so none of the editor's controls apply.
  bool get isAttachment => switch (path) {
    final path? => isShownAttachment(path, features()),
    null => false,
  };

  /// Which editor [memento]'s tab shows: its own, while the library
  /// still offers it; otherwise the library's.
  EditorKind editorOf(NoteMemento memento) {
    final kind = switch (memento.editorKind) {
      wysiwygEditorKind => EditorKind.wysiwyg,
      sourceEditorKind => EditorKind.source,
      _ => null,
    };
    final editor = settings.editor;
    return kind != null && editor.editorsEnabled.contains(kind)
        ? kind
        : editor.editorKind;
  }

  /// The memento of the tab showing, or an empty one.
  NoteMemento get memento =>
      workspace.value.focusedPane.activeTab?.memento ?? const NoteMemento();

  /// The editor the note on screen shows.
  EditorKind get editorKind =>
      wide() ? editorOf(memento) : settings.editor.editorKind;

  /// The memento of the tab showing [path], or an empty one: a note is
  /// shown the way it was left (#23).
  ///
  /// On a phone a note whose tab this build's follow has not made yet has
  /// no memento to read — an empty one answers that frame, not the note
  /// before it.
  NoteMemento mementoOf(String? path) {
    if (path == null) return const NoteMemento();
    final tab = workspace.value.tabs
        .where((tab) => tab.path == path)
        .firstOrNull;
    return tab?.memento ?? const NoteMemento();
  }

  /// Whether the note on screen shows its preview: the showing tab's own
  /// flag, on either layout.
  bool get preview => mementoOf(path).preview ?? false;

  /// The view of the note on screen, which the dock and the sheets speak
  /// for: the focused pane's on a wide window, the phone's on a phone.
  NoteViewHandle? get handle {
    final wide = this.wide();
    final path = wide ? workspace.value.activePath : selection.noteOnScreen;
    if (path == null) return null;
    final key = wide ? keys[path] : phoneKey;
    final Object? state = key?.currentState;
    return state is NoteViewHandle ? state : null;
  }

  /// Changes the showing tab's own way of showing its note (#23).
  void updateTab(NoteMemento Function(NoteMemento memento) change) {
    final path = workspace.value.activePath;
    if (path == null) return;
    workspace.controller.update((w) => w.withMemento(path, change(memento)));
  }

  /// Flips the note on screen between its editor and its preview.
  void togglePreview() {
    // The preview has no editable: flipping to it dismisses the keyboard
    // instead of leaving the IME up over a read-only pane.
    final show = !preview;
    if (show) FocusManager.instance.primaryFocus?.unfocus();
    updateTab((m) => m.copyWith(preview: show));
  }

  /// Flips the preview of the tab showing [path], wherever it is.
  void togglePreviewOf(String path) {
    final tab = workspace.value.tabs.where((t) => t.path == path).firstOrNull;
    if (tab == null) return;
    final show = !(tab.memento.preview ?? false);
    // The preview has no editable: flipping to it lets the keyboard go.
    if (show) FocusManager.instance.primaryFocus?.unfocus();
    workspace.controller.update(
      (w) => w.withMemento(path, tab.memento.copyWith(preview: show)),
    );
  }
}
