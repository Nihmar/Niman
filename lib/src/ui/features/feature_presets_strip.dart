import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/ui/features/feature_preset_text.dart';
import 'package:niman/src/ui/strings.dart';

/// The presets of Settings → Features (#1109), pinned over the list: one
/// chip each, and **Custom** always last.
///
/// A preset only writes the switches; the chip that is selected is the one
/// the switches match. Custom is not an action. It is selected when the
/// switches match no preset, and dimmed while they match one, so the row
/// never moves under the pointer.
final class FeaturePresetsStrip extends StatelessWidget {
  /// The strip for [features]; [onPick] gets the preset a chip was tapped
  /// for.
  const new({required this.features, required this.onPick, super.key});

  /// The library's switches as they stand.
  final Features features;

  /// Applies a preset.
  final ValueChanged<FeaturePreset> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = FeaturePreset.of(features);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              AppStrings.featuresPresetLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 12),
            for (final preset in FeaturePreset.values) ...[
              ChoiceChip(
                key: Key('feature-preset-${preset.name}'),
                label: Text(featurePresetName(preset)),
                selected: current == preset,
                onSelected: (_) => onPick(preset),
                showCheckmark: false,
              ),
              const SizedBox(width: 8),
            ],
            // Never an action: a preset is a start, and Custom is what the
            // switches are once they match none.
            Opacity(
              opacity: current == null ? 1 : 0.45,
              child: ExcludeSemantics(
                excluding: current != null,
                child: IgnorePointer(
                  child: ChoiceChip(
                    key: const Key('feature-preset-custom'),
                    avatar: const Icon(Icons.tune, size: 16),
                    label: Text(AppStrings.featurePresetCustom),
                    selected: current == null,
                    // Present so the chip draws enabled; the pointer never
                    // reaches it.
                    onSelected: (_) {},
                    showCheckmark: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
