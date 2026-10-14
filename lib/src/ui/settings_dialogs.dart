/// The settings dialogs (split out of `settings_rows.dart`, #172): a
/// choice among a handful, and a value on a scale. The rows show the
/// current value; these are where it changes.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';

/// Where the next [showSettingsChoice] opens on a desktop: under the value
/// field of the row clicked (#712). The row sets it just before it asks;
/// it is taken once.
// ponytail: one slot, set and taken in the same tap; a row that asks
// without setting it opens the menu a third of the way down instead.
Rect? _choiceAnchor;

/// Says where the next settings choice opens: [at], under the row's field.
void anchorSettingsChoice(Rect? at) => _choiceAnchor = at;

Rect? _takeChoiceAnchor() {
  final at = _choiceAnchor;
  _choiceAnchor = null;
  return at;
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

/// Asks for one of [options], returning the chosen value or null.
///
/// [subtitle] is the explanation the old inline layout printed under
/// every title. It belongs here: this is the moment the user is deciding,
/// and the list behind is quieter without it.
///
/// Where a pointer aims it is a drop-down under the row's field (#712),
/// the current option checked: a field that reads as a drop-down acts as
/// one, instead of a dialog over the Settings window. The row keeps the
/// explanation under its title.
Future<T?> showSettingsChoice<T>(
  BuildContext context, {
  required String title,
  required List<SettingsOption<T>> options,
  required T current,
  String? subtitle,
  Key? dialogKey,
}) {
  final anchor = _takeChoiceAnchor();
  if (pointerDense(Theme.of(context))) {
    return showActionSheet<T>(
      context,
      sheetKey: dialogKey,
      anchor: anchor,
      items: (context) => [
        for (final option in options)
          ListTile(
            key: Key('settings-choice-${option.value}'),
            dense: true,
            leading: option.value == current
                ? const Icon(Icons.check, size: 20)
                : const SizedBox(width: 20),
            title: Text(option.label),
            selected: option.value == current,
            onTap: () => Navigator.of(context).pop(option.value),
          ),
      ],
    );
  }
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
