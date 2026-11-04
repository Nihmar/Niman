import 'package:flutter/widgets.dart';

/// How many jumps [revealSearchRow] makes at most: the estimate converges
/// in one or two, and a bound keeps a list that keeps changing under it
/// from holding the reveal open.
const int _revealJumps = 8;

/// Brings a row of the results list into view (#768): the row keyed
/// [rowKey], at the list index and among the list rows [target] answers
/// with each frame — null once the row is no longer the one wanted.
///
/// A row outside the list's built range has no context to reveal, so the
/// list first jumps to where the index is estimated to sit — the list's
/// own estimate of its length, shared out by row — and the row, built
/// there or near it, is then scrolled to over [duration]. Each jump lays
/// out real rows around the target, which sharpens the estimate, so the
/// target is built within a few.
Future<void> revealSearchRow({
  required GlobalKey rowKey,
  required ScrollController scroll,
  required ({int index, int rows})? Function() target,
  required Duration duration,
}) async {
  for (var jump = 0; jump < _revealJumps; jump++) {
    await WidgetsBinding.instance.endOfFrame;
    final at = target();
    if (at == null) return;
    if (rowKey.currentContext case final row?) {
      if (!row.mounted) return;
      await Scrollable.ensureVisible(row, alignment: 0.5, duration: duration);
      return;
    }
    if (!scroll.hasClients) return;
    final position = scroll.position;
    final length = position.maxScrollExtent + position.viewportDimension;
    final offset = length * at.index / at.rows - position.viewportDimension / 2;
    position.jumpTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }
}
