/// Where the open note is read: the memento it hands in as it is left, and
/// the place it is put back at (issue #23; #100 moved it out of
/// `note_view.dart`).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/scroll_anchor.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_view_memento.dart';
import 'package:niman/src/workspace/note_memento.dart';

/// Hands in where the note was left, and lands it where it was.
///
/// Reads the note's two panes through [readView] and [sourceView], and which
/// of them is on stage through [reading]; it owns the memento's countdown and
/// the place waiting for its pane, and nothing of the view's own.
final class NotePlace {
  /// A place keeper for the note [path] answers, on [surface].
  new({
    required this.path,
    required this.surface,
    required this.readView,
    required this.sourceView,
    required this.reading,
    required this.active,
    required this.ready,
    required this.mounted,
    required this.receiver,
    required this.wysiwyg,
    required this.preview,
  });

  /// The open note's path.
  final String Function() path;

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// The read pane's state, when it is built.
  final MarkdownReadViewState? Function() readView;

  /// The source pane's state, when it is built.
  final MarkdownSourceViewState? Function() sourceView;

  /// Whether the read pane is the one on stage.
  final bool Function() reading;

  /// Whether this is the tab on screen.
  final bool Function() active;

  /// Whether the note is loaded.
  final bool Function() ready;

  /// Whether the view is still mounted.
  final bool Function() mounted;

  /// Receives where the note is left (`NoteView.onMemento`), or null when
  /// nothing does.
  final void Function(String path, NoteMemento memento)? Function() receiver;

  /// Whether the note is shown in the WYSIWYG pane (`NoteView.showWysiwyg`):
  /// the editor kind the memento names.
  final bool Function() wysiwyg;

  /// Whether the note is shown in its preview (`NoteView.showPreview`).
  final bool Function() preview;

  /// Hands in where the note is, a moment after the reader stops (#23):
  /// a window closed with nothing to save goes without asking the app,
  /// so the memento cannot wait for the view to go away.
  Timer? _mementoTimer;

  /// How long after the last move, scroll or edit the memento goes in.
  static const _mementoDelay = Duration(seconds: 1);

  /// Hands where the note at [path] was left to the [receiver]: only a
  /// loaded note has a place to have been left at.
  void hand(String path) {
    final receive = receiver();
    if (receive == null || !ready()) return;
    final surface = this.surface();
    if (surface != null) {
      // Source offsets either way: `live` draws the same text, so an offset
      // means what it means in `source`, and a tab switch between the two
      // panes keeps the caret. The *editor kind* is the pane's, so the switch
      // comes back to the mode the note was left in.
      final selection = surface.selection;
      // The line at the top of the pane on stage, or, once the panes are
      // gone with the tab, the one it had as it went (#1077).
      final anchor = stageAnchor() ?? _leavingAnchor;
      receive(
        path,
        NoteMemento(
          selectionBase: selection.anchor,
          selectionExtent: selection.extent,
          scrollLine: anchor?.line,
          scrollFraction: anchor?.fraction,
          editorKind: wysiwyg() ? wysiwygEditorKind : sourceEditorKind,
          preview: preview(),
        ),
      );
      return;
    }
  }

  /// Restarts the countdown to handing in the showing note's memento.
  void schedule() {
    if (receiver() == null || !active() || !ready()) return;
    _mementoTimer?.cancel();
    _mementoTimer = Timer(_mementoDelay, () {
      if (mounted()) hand(path());
    });
  }

  /// Hands the showing note's memento in now, the countdown stopped: leaving
  /// the foreground may be the last thing this process does.
  void handNow() {
    _mementoTimer?.cancel();
    hand(path());
  }

  /// Stops the countdown: the view goes away.
  void dispose() => _mementoTimer?.cancel();

  /// Puts the note back where [memento] left it: the selection only in the
  /// editor it was taken in (their offsets count different things), the
  /// scroll either way. [inWysiwyg] says which editor shows now.
  void restore(NoteMemento? memento, {required bool inWysiwyg}) {
    if (memento == null || memento.isEmpty) return;
    final sameEditor =
        memento.editorKind ==
        (inWysiwyg ? wysiwygEditorKind : sourceEditorKind);
    // One surface, two modes, the same text and the same offsets: the
    // selection is restored whenever the memento was taken in this pane, and
    // the scroll either way. The buffer is already built (the load made it).
    final line = memento.scrollLine;
    surface()?.restore(
      base: sameEditor ? memento.selectionBase : null,
      extent: sameEditor ? memento.selectionExtent : null,
      // A memento written before the anchor held pixels: the editor still
      // takes them.
      scroll: line == null ? memento.scrollOffset : null,
    );
    if (line != null) {
      land((line: line, fraction: memento.scrollFraction ?? 0.0));
    }
  }

  /// Keeps the note where it was read when it moves between `source`,
  /// `live` and the read view: the line at the top of the pane going away,
  /// shown at the top of the one taking over once it has drawn. Pixels are
  /// no measure across them — a heading is taller in `live`, a definition
  /// takes no room in the read view — and a pane that kept its own offset
  /// showed wherever it had last been, the top of the note when it had not.
  ///
  /// [wasRead] and [read] say whether the read pane was and is on stage,
  /// [modeChanged] whether the editor moved between `source` and `live`.
  void keepAcrossModes({
    required bool wasRead,
    required bool read,
    required bool modeChanged,
  }) {
    if (wasRead == read && (read || !modeChanged)) return;
    final anchor = wasRead ? readView()?.topAnchor : sourceView()?.topAnchor;
    if (anchor == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted()) return;
      if (reading()) {
        readView()?.showAnchor(anchor);
      } else {
        sourceView()?.showAnchor(anchor);
      }
    });
  }

  /// The source line at the top of the pane on stage, or null while none is
  /// drawn.
  ScrollAnchor? stageAnchor() =>
      reading() ? readView()?.topAnchor : sourceView()?.topAnchor;

  /// The stage anchor taken as the view was leaving the tree: its panes are
  /// gone by the time it is disposed, and the memento is handed in then.
  ScrollAnchor? _leavingAnchor;

  /// The view is leaving the tree: the place on stage is taken now.
  void leaving() => _leavingAnchor = stageAnchor();

  /// The view is back in the tree.
  void back() => _leavingAnchor = null;

  /// A place to show once the pane on stage has the note drawn, and how
  /// many frames it has waited.
  ScrollAnchor? _anchorToLand;
  int _anchorFrames = 0;
  bool _landingScheduled = false;

  /// Whether a place is waiting for its pane.
  bool get landing => _anchorToLand != null;

  /// Shows [anchor] at the top of the pane on stage as soon as it can: the
  /// note's panes are built a frame or more after its text arrives, the
  /// preview later still, and a tab behind waits for its turn.
  void land(ScrollAnchor anchor) {
    _anchorToLand = anchor;
    _anchorFrames = 0;
    scheduleLanding();
  }

  /// Tries the waiting place after the next frame.
  void scheduleLanding() {
    if (_landingScheduled) return;
    _landingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _landingScheduled = false;
      if (mounted()) _tryLanding();
    });
  }

  void _tryLanding() {
    final anchor = _anchorToLand;
    // A tab behind is not drawn: it lands when it comes back.
    if (anchor == null || !active()) return;
    final read = reading();
    final landed = read
        ? readView()?.acceptsAnchor ?? false
        : sourceView()?.acceptsAnchor ?? false;
    if (landed) {
      _anchorToLand = null;
      if (read) {
        readView()!.showAnchor(anchor);
      } else {
        sourceView()!.showAnchor(anchor);
      }
      return;
    }
    if (++_anchorFrames < _maxLandingFrames) scheduleLanding();
  }

  /// How many frames a place waits for its pane before it is given up.
  static const int _maxLandingFrames = 240;
}
