import 'package:flutter/material.dart';

/// The bottom-tab bodies, kept mounted so a switch never re-inflates them.
///
/// Each built child stays in the tree: switching tabs only flips
/// visibility and fades the incoming body in, instead of disposing one
/// [State] and inflating another mid-animation (the 14-17 ms `build`
/// frames in the 2026-09-08 device log, while the instrumented widget
/// constructors logged 0 ms). The fade covers the entry without a
/// cross-fade's second offscreen pass.
///
/// Hidden slots hide with [Offstage] (layout, paint, and tickers skipped),
/// except the ones in [retainLayout]: showing an [Offstage] child pays a
/// full relayout, which for a `TextField`-heavy tab alone costs 10-16 ms
/// of frame build (T-TS-09). Those stay laid out via [Visibility]
/// `maintainSize` instead (paint, semantics, interactivity, and tickers
/// still off), so showing them is paint-only. Retained sparingly and only
/// where the show-layout is itself expensive: retaining everywhere would
/// relayout every hidden tab on each window resize and keyboard frame.
final class TabBodyStack extends StatelessWidget {
  /// Creates the stack over [children], showing [currentIndex].
  const new({
    required this.currentIndex,
    required this.children,
    this.retainLayout = const <int>{},
    super.key,
  });

  /// The visible child's index.
  final int currentIndex;

  /// One body per tab, in tab order, each with a stable identity.
  final List<Widget> children;

  /// Slots that stay laid out while hidden (see above).
  final Set<int> retainLayout;

  /// Matches the old tab-switch fade; the shell reuses it to mark the
  /// fade end in the log (T-TS-09).
  static const fade = Duration(milliseconds: 180);

  /// The animated slot at [index]: visibility flips here, the fade and
  /// the ticker muting with it.
  Widget _slot(int index) {
    final visible = index == currentIndex;
    return TickerMode(
      enabled: visible,
      child: AnimatedOpacity(
        duration: fade,
        curve: Curves.easeOutCubic,
        opacity: visible ? 1 : 0,
        child: children[index],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          if (retainLayout.contains(i))
            Visibility(
              visible: i == currentIndex,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: _slot(i),
            )
          else
            Offstage(offstage: i != currentIndex, child: _slot(i)),
      ],
    );
  }
}
