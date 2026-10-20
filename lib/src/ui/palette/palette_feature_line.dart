/// The palette's quiet line about a feature that is off (#1109).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/feature_names.dart';
import 'package:niman/src/ui/strings.dart';

/// *Todo is off in this library · Features ›*: under the key hints, when a
/// query found commands only of a feature the library has off. Says why the
/// list holds none, and leads to where the switch is.
final class PaletteFeatureLine extends StatelessWidget {
  /// The line for [feature]; [onOpen] follows its link.
  const new({required this.feature, required this.onOpen, super.key});

  /// The feature that is off.
  final LibraryFeature feature;

  /// Opens Settings → Features.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      children: [
        Text(
          AppStrings.featureOffInLibraryNamed(featureName(feature)),
          key: const Key('palette-feature-off'),
          style: muted,
        ),
        Text(' · ', style: muted),
        InkWell(
          key: const Key('palette-feature-link'),
          onTap: onOpen,
          child: Text(
            '${AppStrings.featuresTitle} ›',
            style: muted?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
