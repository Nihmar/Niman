import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/ui/features/feature_preset_text.dart';

/// The presets as large radio cards (#1109), in place of the chip row for a
/// library being created: *What is this library for?*
///
/// Picking one writes the switches at once, and the card that is selected
/// is the one the switches match — so one the user then flips by hand
/// leaves every card unselected rather than lying.
final class FeaturePresetCards extends StatelessWidget {
  /// The cards for [features]; [onPick] gets the preset one was tapped for.
  const new({required this.features, required this.onPick, super.key});

  /// The library's switches as they stand.
  final Features features;

  /// Applies a preset.
  final ValueChanged<FeaturePreset> onPick;

  @override
  Widget build(BuildContext context) {
    final current = FeaturePreset.of(features);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        // Two by two where there is room for two; one column on a phone
        // narrow enough that a hint would wrap to a third line.
        final columns = constraints.maxWidth >= 300 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final preset in FeaturePreset.values)
              SizedBox(
                width: width,
                child: _PresetCard(
                  key: Key('feature-preset-card-${preset.name}'),
                  preset: preset,
                  selected: current == preset,
                  onTap: () => onPick(preset),
                ),
              ),
          ],
        );
      },
    );
  }
}

final class _PresetCard extends StatelessWidget {
  const new({
    required this.preset,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final FeaturePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        featurePresetName(preset),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        featurePresetHint(preset),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
