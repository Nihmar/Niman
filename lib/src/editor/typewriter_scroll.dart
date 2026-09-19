/// Typewriter mode (#70): the line being written keeps to the middle of
/// the editor, and the note moves under it instead.
///
/// It is a way of scrolling and nothing else: the text, its wrapping and
/// its styles are the same with it on or off. Both editors use it the
/// same way — each knows where its own caret is, and hands that here:
///
/// - the caret moves (typing onto a new row, an arrow, a click, a find
///   landing on its match): the note glides so the caret's row sits in
///   the middle;
/// - the wheel or the scrollbar moves the note: it goes where it is sent,
///   to read around, and the next move of the caret brings it back;
/// - the end of the note can reach the middle too: the editor leaves
///   half a screen of room below the last line ([typewriterSlack]). The
///   start has none above it, so the first lines are written where they
///   stand until the note is long enough to move.
library;

import 'package:flutter/material.dart';

/// The faint light on the row being written, in typewriter mode: both
/// editors paint it the same.
Color typewriterLineColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary.withValues(alpha: 0.07);

/// How long the glide to the middle takes: short enough never to fall
/// behind typing, long enough to read as a movement rather than a jump.
const Duration typewriterGlide = Duration(milliseconds: 100);

/// The room left below the last line so it can reach the middle of a
/// viewport [height] tall.
double typewriterSlack(double height) => height / 2;

/// Scrolls [scroll] so a caret row centred [caretY] below the top of its
/// viewport sits in the viewport's middle. Where the note cannot move
/// that far (its start), it stops at the edge.
void centerCaret(ScrollController scroll, double caretY) {
  // One view at a time: a rebuild briefly attaches it to two.
  if (scroll.positions.length != 1) return;
  final position = scroll.position;
  final target = (position.pixels + caretY - position.viewportDimension / 2)
      .clamp(position.minScrollExtent, position.maxScrollExtent);
  // Typing along a row moves nothing: only a new row is a movement.
  if ((target - position.pixels).abs() < 1) return;
  scroll.animateTo(target, duration: typewriterGlide, curve: Curves.easeOut);
}

/// Runs its callback once after the next layout, however many times the
/// caret moved before it: a burst of keys is one glide, to where the
/// caret ended.
final class TypewriterFollow {
  /// Follows the caret through a callback that reads where the caret is
  /// after layout and calls [centerCaret]; it answers false when the
  /// caret's row is not laid out yet (a jump far down the note lays it out
  /// a frame later), and is asked again on the next few frames.
  new(this._center);

  final bool Function() _center;
  bool _scheduled = false;
  bool _disposed = false;

  /// How many frames a caret whose row is not laid out yet is waited for:
  /// as many as re_editor gives its own jump to an unseen line.
  static const int _tries = 10;

  /// The caret moved, or the text under it did.
  void caretMoved() {
    if (_scheduled || _disposed) return;
    _schedule(_tries);
  }

  void _schedule(int tries) {
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed || _center() || tries <= 1) return;
      _schedule(tries - 1);
    });
    // A caret move with nothing else to redraw still needs its frame.
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Stops following.
  void dispose() => _disposed = true;
}
