/// The building blocks of the settings list (2026-09-08 user feedback:
/// the screen read as one undifferentiated wall).
///
/// Two shapes, and the whole reorganisation follows from them. A section
/// header groups what belongs together, and every setting is one row of
/// the same height: a switch flips in place, anything with more than two
/// choices shows its current value on the right and opens a dialog.
///
/// What that buys is a screen you can read without reading it. The old
/// layout gave a switch one line and a `SegmentedButton` three — title,
/// subtitle, then the buttons — so four of them in a row built a block
/// with no rhythm to scan. Here the names run down the left and the
/// values down the right, and the subtitle moves into the dialog, where
/// it is read at the moment it is needed rather than every time the
/// screen is opened.
library;

import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// A settings section heading.
final class SettingsSection extends StatelessWidget {
  /// Creates the heading shown above a group of settings rows.
  const new(this.title, {super.key});

  /// The group's name.
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// One option in a [showSettingsChoice] dialog.
final class SettingsOption<T> {
  /// Creates an option labelled [label] for the value [value].
  const new(this.value, this.label);

  /// The value chosen by this option.
  final T value;

  /// What the option reads as, in the list and as the row's value.
  final String label;
}

/// A settings row showing its current value, tapped to change it.
///
/// [value] is what the row reads on the right. A null [value] makes it a
/// plain navigation row (a chevron and nothing else), which is what the
/// rows that open a screen of their own want.
final class SettingsValueRow extends StatelessWidget {
  /// Creates a row for [title] currently reading [value].
  const new({
    required this.title,
    required this.onTap,
    this.value,
    this.subtitle,
    super.key,
  });

  /// The setting's name.
  final String title;

  /// The current value, shown on the right; null for a navigation row.
  final String? value;

  /// Shown under the title, for the rare row whose value is not
  /// self-explanatory (the library path, which is a path).
  final String? subtitle;

  /// Opens whatever changes the setting.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = value;
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (current != null)
            ConstrainedBox(
              // A long value (a note path) truncates rather than pushing
              // the chevron off the row or wrapping the whole tile.
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.4,
              ),
              child: Text(
                current,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Asks for one of [options], returning the chosen value or null.
///
/// [subtitle] is the explanation the old inline layout printed under
/// every title. It belongs here: this is the moment the user is deciding,
/// and the list behind is quieter without it.
Future<T?> showSettingsChoice<T>(
  BuildContext context, {
  required String title,
  required List<SettingsOption<T>> options,
  required T current,
  String? subtitle,
  Key? dialogKey,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      key: dialogKey,
      title: Text(title),
      children: [
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final option in options)
          ListTile(
            key: Key('settings-choice-${option.value}'),
            leading: Icon(
              option.value == current
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: option.value == current
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(option.label),
            onTap: () => Navigator.of(context).pop(option.value),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.actionCancel),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Asks for a value on a continuous scale, returning it or null.
///
/// The settings that are not a choice among a handful — the split width
/// and the two text sizes — given the same row treatment so they do not
/// become the only inline controls left on the screen. [divisions] snaps
/// the slider to steps; null leaves it continuous.
Future<double?> showSettingsSlider(
  BuildContext context, {
  required String title,
  required double current,
  required double min,
  required double max,
  required String Function(double value) format,
  String? subtitle,
  Key? dialogKey,
  Key sliderKey = const Key('split-ratio'),
  int? divisions,
}) {
  var value = current;
  return showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      key: dialogKey,
      title: Text(title),
      content: StatefulBuilder(
        builder: (context, setInner) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 8),
            Text(format(value), style: Theme.of(context).textTheme.titleMedium),
            Slider(
              key: sliderKey,
              min: min,
              max: max,
              value: value,
              divisions: divisions,
              onChanged: (v) => setInner(() => value = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        TextButton(
          key: const Key('settings-slider-save'),
          onPressed: () => Navigator.of(context).pop(value),
          child: Text(AppStrings.actionSave),
        ),
      ],
    ),
  );
}
