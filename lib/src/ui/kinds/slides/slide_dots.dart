import 'package:flutter/material.dart';

/// Where the slide on screen is in a short deck.
final class SlideDots extends StatelessWidget {
  /// [count] dots, the one at [index] lit.
  const new({required this.count, required this.index, super.key});

  /// How many slides.
  final int count;

  /// The slide on screen.
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
