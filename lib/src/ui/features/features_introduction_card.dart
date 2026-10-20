import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/ui/features/feature_preset_cards.dart';
import 'package:niman/src/ui/strings.dart';

/// The card above the presets of Settings → Features (#1109).
///
/// For a library that existed before the switches did it says what the
/// screen is; for one being created it asks *What is this library for?* and
/// holds the presets as large cards. **Done** leaves the screen, which is
/// what records that the introduction was seen.
final class FeaturesIntroductionCard extends StatelessWidget {
  /// The card of [introduction], never [FeaturesIntroduction.none];
  /// [features] and [onPick] serve the cards of a library being created.
  const new({
    required this.introduction,
    required this.features,
    required this.onPick,
    required this.onDone,
    super.key,
  }) : assert(
         introduction != FeaturesIntroduction.none,
         'There is no card for no introduction',
       );

  /// Which card to draw.
  final FeaturesIntroduction introduction;

  /// The library's switches as they stand.
  final Features features;

  /// Applies a preset (a library being created).
  final ValueChanged<FeaturePreset> onPick;

  /// The **Done** button: leaves the screen.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = introduction == FeaturesIntroduction.created;
    return Card(
      key: Key('features-introduction-${introduction.name}'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: scheme.primaryContainer.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view_outlined, size: 20, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    created
                        ? AppStrings.featuresCreatedTitle
                        : AppStrings.featuresIntroTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              created
                  ? AppStrings.featuresCreatedBody
                  : AppStrings.featuresIntroBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (created) ...[
              const SizedBox(height: 12),
              FeaturePresetCards(features: features, onPick: onPick),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: const Key('features-introduction-done'),
                onPressed: onDone,
                child: Text(AppStrings.featuresIntroDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
