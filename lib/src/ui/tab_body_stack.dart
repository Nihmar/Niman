import 'package:flutter/material.dart';

/// The bottom-tab bodies, kept mounted so a switch never re-inflates them.
///
/// Each built child stays in the tree inside an [Offstage]: switching tabs
/// only flips visibility and fades the incoming body in, instead of
/// disposing one [State] and inflating another mid-animation (the 14-17 ms
/// `build` frames in the 2026-09-08 device log, while the instrumented
/// widget constructors logged 0 ms). Hidden subtrees skip layout, paint,
/// and tickers; the fade covers the entry without a cross-fade's second
/// offscreen pass.
final class TabBodyStack extends StatelessWidget {
  /// Creates the stack over [children], showing [currentIndex].
  const new({required this.currentIndex, required this.children, super.key});

  /// The visible child's index.
  final int currentIndex;

  /// One body per tab, in tab order, each with a stable identity.
  final List<Widget> children;

  /// Matches the old tab-switch fade; the shell reuses it to mark the
  /// fade end in the log (T-TS-09).
  static const fade = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          Offstage(
            offstage: i != currentIndex,
            child: TickerMode(
              enabled: i == currentIndex,
              child: AnimatedOpacity(
                duration: fade,
                curve: Curves.easeOutCubic,
                opacity: i == currentIndex ? 1 : 0,
                child: children[i],
              ),
            ),
          ),
      ],
    );
  }
}
