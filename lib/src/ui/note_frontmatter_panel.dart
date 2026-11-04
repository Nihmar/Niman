/// The frontmatter fields panel over the open note (#157): how much of it
/// shows, and the field edits it makes (issue #100 moved it out of
/// `note_view.dart`).
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/frontmatter_fields.dart';
import 'package:niman/src/ui/note_frontmatter_head.dart';

/// The **one** panel both surfaces show (#157): the read pane puts it above
/// its preview, the live editor above its note, and neither keeps a copy of
/// the note — both hand the same head to the same widget and read the file
/// back through it.
///
/// How much of it shows is kept here ([open], [headInView]), so the two
/// panes cannot drift: closed on opening a note, open while the reader says
/// so, and away while the note is scrolled off its head.
final class NoteFrontmatterPanel {
  /// The panel over the note on [surface], following [previewScroll] over the
  /// read pane and [sourceScroll] over the editor.
  new({
    required this.enabled,
    required this.surface,
    required this.reading,
    required this.typewriter,
    required this.caretLine,
    required this.previewScroll,
    required this.sourceScroll,
    required this.mounted,
    required this.onChanged,
    required this.onEdited,
  });

  /// Whether the library wants a panel at all (`NoteView.frontmatterPanel`):
  /// a library that wants none gets none.
  final bool Function() enabled;

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// Whether the read pane is the one on stage.
  final bool Function() reading;

  /// Whether typewriter mode is on (`NoteView.typewriter`).
  final bool Function() typewriter;

  /// The line the editor's caret is on (1-based), or null before it has
  /// reported one.
  final int? Function() caretLine;

  /// The read pane's scroll.
  final ScrollController previewScroll;

  /// The editor surface's scroll.
  final ScrollController sourceScroll;

  /// Whether the view is still mounted.
  final bool Function() mounted;

  /// The panel changed: the view draws it again.
  final VoidCallback onChanged;

  /// A field edit went into the note: the preview and the statistics follow.
  final VoidCallback onEdited;

  /// Whether the reader opened the fields panel (#157).
  ///
  /// Closed until they do: the panel belongs to the note's first lines, and
  /// what it shows is a tap away rather than in the way of every note opened.
  bool open = false;

  /// Whether the pane on stage still shows the note's head (#157): the panel
  /// goes away the moment the note is scrolled past it, and comes back with
  /// the head, as the reader left it.
  bool _atHead = true;

  /// The note's head in the pane's own pixels (#157): the frontmatter block's
  /// lines at the row height the editor draws them, and nothing at all over
  /// the read pane, whose preview gives the block no room
  /// (`markdown_read_view`) — there the panel above the note *is* the head.
  double _headExtent = 0;

  /// Another note's head is not this one's (#157): the panel opens closed
  /// again, and the note on screen is taken at its head until it scrolls.
  void reset() {
    open = false;
    _atHead = true;
  }

  /// The frontmatter fields panel, or null when the note has no readable
  /// block.
  Widget? fields() {
    if (!enabled()) return null;
    final head = frontmatterHeadOf(surface()?.buffer);
    if (head == null) return null;
    return FrontmatterFields(
      note: head,
      onSet: applyFieldEdit,
      onRemove: (key) => applyFieldEdit(key, null),
      panel: !headInView()
          ? FrontmatterPanel.hidden
          : open
          ? FrontmatterPanel.open
          : FrontmatterPanel.closed,
      onToggle: toggle,
    );
  }

  /// Opens the closed fields panel, or closes the open one (#157).
  void toggle() {
    open = !open;
    onChanged();
  }

  /// Whether the pane on stage still shows the note's head (#157).
  ///
  /// A pane that has not been laid out yet — a note just opened — counts as
  /// showing its head: the panel opens with the note it belongs to.
  ///
  /// In typewriter mode the scroll is the caret's, not the reader's, and the
  /// panel's own height moves the scroll's extent (the editor sits in the
  /// room the panel leaves). Asking the offset there would make the two
  /// chase each other: centering pushes the offset past the head, the panel
  /// hides, the smaller extent clamps the offset back under the head, and
  /// the panel shows again — once per keystroke on a short note (#522). The
  /// caret's line does not move with the panel, so it decides instead.
  bool headInView() {
    if (typewriter() && !reading()) {
      return caretInFrontmatterHead(surface()?.buffer, caretLine());
    }
    final controller = reading() ? previewScroll : sourceScroll;
    return !controller.hasClients || controller.offset <= _headExtent;
  }

  /// The panel follows the note's head (#157): away once the note is scrolled
  /// past it, back when the head is on screen again.
  ///
  /// The reader's own choice is kept as it was, so coming back to the top of a
  /// note finds the panel closed or open exactly as they left it.
  void scrolled() {
    if (!mounted()) return;
    final atHead = headInView();
    if (atHead == _atHead) return;
    _atHead = atHead;
    onChanged();
  }

  /// Measures the note's head for the pane about to be built (#157):
  /// [scrolled] reads it on every scroll tick, and building a theme there
  /// would cost a frame's worth on each one.
  ///
  /// The frontmatter block's lines at the row height the surface draws them —
  /// the same `theme.lineHeight`, at the note's own text scale, that the
  /// source view's rows are measured with. Nothing over the read pane, whose
  /// preview gives the block no room at all (`markdown_read_view`): there the
  /// panel is what the head costs, so any scroll past the top is past the
  /// head.
  void measure(BuildContext context, {required bool showPreview}) {
    _headExtent = _headExtentOf(context, showPreview: showPreview);
  }

  double _headExtentOf(BuildContext context, {required bool showPreview}) {
    if (showPreview) return 0;
    final rows = frontmatterHeadRows(surface()?.buffer);
    if (rows == 0) return 0;
    final scaler = noteTextScalerOf(context);
    final row = scaler.scale(
      markdownThemeOf(context, scaler: scaler).lineHeight,
    );
    return row * rows;
  }

  /// Writes one frontmatter field through the editor's own door (#157).
  ///
  /// The named key's line only, so the rest of the block — its key order, its
  /// comments, its quoting — does not move; one `.md` file, one undo step,
  /// saved like any other edit. A null [value] removes the key. The read
  /// pane and the fields both follow from the surface's buffer, so there is no
  /// second source of truth to keep in step.
  void applyFieldEdit(String key, String? value) {
    final surface = this.surface();
    if (surface == null) return;
    final edit = frontmatterFieldEdit(surface.buffer, key, value);
    if (edit == null) return;
    // The caret is an offset into the old text: it moves by what the head
    // grew or shrank by, or stays where it is when it sits in the head
    // (clamped into the new one). And it is not followed — the edit is made
    // where the panel is, and the view jumping to a caret in the body would
    // take the panel off the screen.
    surface.replaceRange(
      0,
      edit.end,
      edit.text,
      caret: selectionAfterFieldEdit(surface.selection, edit),
      follow: false,
    );
    onEdited();
  }
}
