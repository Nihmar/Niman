import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/app_switch.dart';
import 'package:niman/src/ui/feature_names.dart';
import 'package:niman/src/ui/features/feature_row_text.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';

/// One switch of Settings → Features (#1109): its outline icon, its name,
/// what *off* means, and the switch.
///
/// A child whose parent is off is greyed and cannot be flipped: its line
/// reads *Needs …* and its switch keeps the value it had, so
/// turning the parent back on brings it back as it was. A child sits
/// indented under its parent.
final class FeatureRow extends StatelessWidget {
  /// The row of [feature], read from [features]; [onChanged] gets the
  /// switch's new value.
  const new({
    required this.feature,
    required this.features,
    required this.onChanged,
    super.key,
  });

  /// The feature this row switches.
  final LibraryFeature feature;

  /// The library's switches as they stand.
  final Features features;

  /// Called with the new value of the row's own switch.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parent = feature.parent;
    final needsParent = parent != null && !features.isOn(parent);
    final own = features.own(feature);
    final dim = theme.colorScheme.onSurface.withValues(alpha: 0.38);
    final line = needsParent
        ? AppStrings.featureNeeds(featureName(parent))
        : featureOffLine(feature);
    return HighlightRow(
      key: SettingsKeys.featureRow(feature),
      child: MergeSemantics(
        child: InkWell(
          onTap: needsParent ? null : () => onChanged(!own),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              parent == null ? 16 : 40,
              10,
              12,
              10,
            ),
            child: Row(
              children: [
                Icon(
                  featureIcon(feature),
                  size: 20,
                  color: needsParent ? dim : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            featureName(feature),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: needsParent ? dim : null,
                            ),
                          ),
                          if (feature == LibraryFeature.widgets)
                            const _AndroidTag(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: needsParent
                              ? dim
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppSwitch(
                  value: own,
                  onChanged: needsParent ? null : onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The *Android* tag on the widgets row: the setting travels with the
/// library on every platform and acts where widgets exist.
final class _AndroidTag extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          // A platform's name: the same in every language.
          'Android',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
