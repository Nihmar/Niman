import 'package:flutter/material.dart';
import 'package:niman/src/ui/app_switch.dart';

/// A list row with an on/off switch at its end (#1125): what
/// `SwitchListTile` is, with the [AppSwitch] of the device in place of
/// Material's touch-sized one.
///
/// The whole row flips the switch, and a null [onChanged] disables both.
/// The row is the one stop of the keyboard's focus; the switch inside it
/// is for the eye and the pointer.
final class AppSwitchListTile extends StatelessWidget {
  /// A row saying [title] whose switch is [value].
  const new({
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.contentPadding,
    this.dense,
    super.key,
  });

  /// Whether the switch is on.
  final bool value;

  /// Flips it; null disables the row.
  final ValueChanged<bool>? onChanged;

  /// What the row says.
  final Widget title;

  /// A line under the title.
  final Widget? subtitle;

  /// The row's padding; null keeps the list tile's own.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the row is drawn tighter than usual.
  final bool? dense;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: ListTile(
        contentPadding: contentPadding,
        dense: dense,
        title: title,
        subtitle: subtitle,
        enabled: onChanged != null,
        onTap: onChanged == null ? null : () => onChanged(!value),
        trailing: ExcludeFocus(
          child: AppSwitch(value: value, onChanged: onChanged),
        ),
      ),
    );
  }
}
