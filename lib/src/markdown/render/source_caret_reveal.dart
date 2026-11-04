import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The source view's caret kept in view: scrolled to when an edit or a jump
/// left it out, and brought back when the keyboard comes up over it (#728).
///
/// The view owns it and hands it the scroll notifications; the plan is made
/// on the view's height map, through the narrow callbacks it is handed.
final class SourceCaretReveal {
  /// The reveal over the view's [_scroll].
  new({
    required this._scroll,
    required this._mounted,
    required this._caretLine,
    required this._anchorLine,
    required this._rowOf,
    required this._lineBounds,
    required this._bottomInsetNow,
    required this._typing,
  });

  /// The note's scroll.
  final ScrollController Function() _scroll;

  /// Whether the view is still mounted.
  final bool Function() _mounted;

  /// The line the caret sits on, or -1.
  final int Function() _caretLine;

  /// The line the selection's anchor sits on.
  final int Function() _anchorLine;

  /// The row a line is drawn in.
  final int Function(int line) _rowOf;

  /// A line as the scroll view sees it: its top and its bottom.
  final ({double top, double bottom}) Function(int line) _lineBounds;

  /// The view's bottom inset now, in physical pixels.
  final double Function() _bottomInsetNow;

  /// Whether this editor has the focus and the platform's connection: the
  /// keyboard coming up is the one it asked for.
  final bool Function() _typing;

  /// The viewport height the last metrics change left: a smaller one, with
  /// the bottom inset grown, is the keyboard opening over the note (#728).
  double? _viewportHeight;

  /// The view's bottom inset at the last metrics change, in physical pixels:
  /// a viewport that shrank without it growing is the window made shorter
  /// or turned, not the keyboard (#765).
  double _bottomInset = 0;

  /// Whether the writer took the scroll while the keyboard was coming up:
  /// the reveal is theirs to call off, until the keyboard is asked for again
  /// or goes down (#728).
  bool _insetRevealOff = false;

  /// Moves on when the writer starts a drag: a reveal still checking itself
  /// over the frames after its jump stops there.
  int _revealEpoch = 0;

  /// The keyboard was asked for again: a keyboard coming up is revealed
  /// over, whatever the writer called off before.
  void keyboardAsked() => _insetRevealOff = false;

  /// A metrics change: when it is the keyboard this editor asked for coming
  /// up over the note, the caret is brought back into view (#728).
  ///
  /// The keyboard, and only it (#765): the viewport shrank *and* the view's
  /// bottom inset grew — a window made shorter or a phone turned shrinks the
  /// viewport alone — while this editor has the focus and the platform's
  /// connection, so a keyboard raised for another field (a rename, the find
  /// bar, a dialog) moves nothing here.
  ///
  /// Each step of the keyboard's animation lays the pane out anew and lands
  /// here, after that layout, with the viewport it left: the reveal runs at
  /// every step against the viewport as it stands, as `EditableText` does,
  /// and the last step is the keyboard at rest — no guess at how long the
  /// animation takes.
  bool onScrollMetrics(ScrollMetricsNotification notification) {
    final height = notification.metrics.viewportDimension;
    final last = _viewportHeight;
    _viewportHeight = height;
    final inset = _bottomInsetNow();
    final lastInset = _bottomInset;
    _bottomInset = inset;
    // The keyboard going down ends what the writer called off.
    if (inset < lastInset) _insetRevealOff = false;
    if (last == null || height >= last || inset <= lastInset) return false;
    if (!_typing() || _insetRevealOff) {
      return false;
    }
    ensureCaretVisible(wholeSelection: true);
    return false;
  }

  /// The writer took the scroll: the reveal of a keyboard coming up is
  /// theirs to call off, and nothing is moved under their finger (#728).
  bool onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _insetRevealOff = true;
      // A reveal still settling over the next frames is called off too.
      _revealEpoch++;
    }
    return false;
  }

  /// Scrolls the caret's line into view when an edit or a jump left it out.
  ///
  /// The plan is made on the height map, and the map is only as good as the
  /// last layout: a row an edit just changed — a line that wrapped onto new
  /// rows, one that became a heading, one added at the bottom — is as the
  /// frame before measured it (or estimated), and the note's extent, which
  /// the plan clamps to, is the one it had. Far from the viewport it is
  /// estimates throughout. So the plan is checked again against the layout
  /// that follows it, whether or not it moved anything: a line that fit the
  /// old measure and does not fit the new one is brought in with the rest of
  /// its box (Ctrl+End left the last line half under the pane's edge until
  /// the wheel went the rest of the way; typing into the last row left its
  /// new rows below the pane). A check that still has to move is followed by
  /// another — [settle] of them at most.
  ///
  /// [wholeSelection] keeps the whole selection in view when it fits, not
  /// only the caret: what the keyboard opening asks for (#728). A caret move
  /// does not — with the anchor just off the screen, every Shift+Down pulled
  /// the view back to it (#764).
  void ensureCaretVisible({int settle = 3, bool wholeSelection = false}) {
    if (!_scroll().hasClients) return;
    _revealPlanned(wholeSelection: wholeSelection);
    _checkRevealAfterLayout(settle, wholeSelection);
  }

  /// Plans the reveal again after the next frame, which lays out what the
  /// edit or the jump changed. That frame is asked for here, so the check
  /// never waits for one the writer's next scroll brings (and takes the view
  /// back from them).
  void _checkRevealAfterLayout(int settle, bool wholeSelection) {
    if (settle <= 0) return;
    final epoch = _revealEpoch;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (!_mounted() || epoch != _revealEpoch || !_scroll().hasClients) {
          return;
        }
        // Only a check that moved the view has a frame coming to follow it.
        if (_revealPlanned(wholeSelection: wholeSelection)) {
          _checkRevealAfterLayout(settle - 1, wholeSelection);
        }
      })
      ..scheduleFrame();
  }

  /// Plans the reveal on the height map as it stands and scrolls to it;
  /// whether the view moved.
  bool _revealPlanned({required bool wholeSelection}) {
    final line = _caretLine();
    if (line < 0) return false;
    final scroll = _scroll();
    // In the scroll view's coordinates: the map starts below the top padding,
    // and the last line takes the bottom padding with it. Without them every
    // jump down stopped the padding short, the caret's row cut by it.
    final row = _rowOf(line);
    final extent = _lineBounds(line);
    final viewport = scroll.position.viewportDimension;
    // A selection is kept whole when it is asked for and fits the viewport;
    // otherwise its active end is — a selection longer than the screen
    // cannot be shown whole, and the writer's next keystroke lands at the
    // caret (#728).
    var firstRow = row;
    var edgeTop = extent.top;
    var edgeBottom = extent.bottom;
    if (wholeSelection) {
      final anchorLine = _anchorLine();
      final anchorRow = _rowOf(anchorLine);
      final anchor = _lineBounds(anchorLine);
      final top = math.min(anchor.top, extent.top);
      final bottom = math.max(anchor.bottom, extent.bottom);
      if (bottom - top <= viewport) {
        firstRow = math.min(anchorRow, row);
        edgeTop = top;
        edgeBottom = bottom;
      }
    }
    final double target;
    if (edgeTop < scroll.offset) {
      // The first row takes the top padding with it. Only the row actually
      // kept says so: a too-long selection that starts at the note's top
      // keeps its caret, not the top of the note (#764).
      target = firstRow == 0 ? 0 : edgeTop;
    } else if (edgeBottom > scroll.offset + viewport) {
      target = (edgeBottom - viewport).clamp(
        0.0,
        scroll.position.maxScrollExtent,
      );
    } else {
      return false;
    }
    if (target == scroll.offset) return false;
    scroll.jumpTo(target);
    return true;
  }
}
