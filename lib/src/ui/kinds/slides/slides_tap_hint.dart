import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// Where to tap, over the slide when a phone starts presenting.
final class SlidesTapHint extends StatelessWidget {
  /// The hint.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 13);
    Widget zone(IconData icon, String label) => Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(label, style: style, textAlign: TextAlign.center),
        ],
      ),
    );
    return IgnorePointer(
      child: ColoredBox(
        key: const Key('slides-tap-hint'),
        color: Colors.black.withValues(alpha: 0.6),
        child: Row(
          children: [
            zone(Icons.chevron_left, AppStrings.slidesPrevious),
            zone(Icons.arrow_downward, AppStrings.slidesSwipeToExit),
            zone(Icons.chevron_right, AppStrings.slidesNext),
          ],
        ),
      ),
    );
  }
}
