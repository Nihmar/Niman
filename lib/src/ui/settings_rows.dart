/// The building blocks of the settings list.
///
/// Every setting is one shape (issue #172, replacing the 2026-09-08 rows):
/// its **label**, the **description** under it, and the **control** under
/// that, stacked in a column capped at [settingsRowMaxWidth]. The
/// description is read before the control is touched rather than after,
/// and on a wide window the control sits under its label instead of lost
/// at the far edge. The phone and the desktop share the shape — a setting
/// reads the same on both — and there is one row widget per kind of
/// control, not one per platform:
///
/// * [SettingsSwitchRow]: a switch, flipped in place;
/// * [SettingsValueRow]: a field showing the current value, opening the
///   dialog that changes it — or, with no value, a way to another screen;
/// * [SettingsActionRow]: something that happens now (export the log);
/// * [SettingsRowFrame]: the shape itself, and a fact with nothing to
///   change (the library's path).
///
/// The dialogs the value rows open are in `settings_dialogs.dart`.
library;

import 'package:flutter/material.dart';

export 'package:niman/src/ui/settings_dialogs.dart';

/// How wide a settings row's text and control may run: a readable line,
/// the same measure the note column keeps (#171).
const double settingsRowMaxWidth = 620;

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

/// The shape every settings row shares: [title], [description] under it,
/// [control] under that, in a column capped at [settingsRowMaxWidth].
///
/// [trailing] sits at the end of the title's line (a navigation row's
/// chevron). [onTap] makes the whole row a target; [enabled] false greys
/// it out and drops the tap.
final class SettingsRowFrame extends StatelessWidget {
  /// Creates the row for [title].
  const new({
    required this.title,
    this.description,
    this.control,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
    super.key,
  });

  /// The setting's name.
  final String title;

  /// Whether [title] reads in the error colour.
  final bool destructive;

  /// What the setting does, or — for a fact — what it is.
  final String? description;

  /// What changes the setting, under the text.
  final Widget? control;

  /// At the end of the title's line.
  final Widget? trailing;

  /// A tap anywhere on the row.
  final VoidCallback? onTap;

  /// Whether the row can be used.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = this.description;
    final trailing = this.trailing;
    final control = this.control;
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: settingsRowMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: destructive
                          ? theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.error,
                            )
                          : theme.textTheme.titleSmall,
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (control != null) ...[const SizedBox(height: 8), control],
            ],
          ),
        ),
      ),
    );
    if (onTap != null) {
      row = InkWell(onTap: enabled ? onTap : null, child: row);
    }
    if (!enabled) row = Opacity(opacity: 0.45, child: row);
    return MergeSemantics(child: row);
  }
}

/// A setting that is on or off: the switch sits under the description,
/// and a tap anywhere on the row flips it.
final class SettingsSwitchRow extends StatelessWidget {
  /// Creates the row for [title], currently [value].
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    super.key,
  });

  /// The setting's name.
  final String title;

  /// What turning it on does.
  final String? description;

  /// Whether it is on.
  final bool value;

  /// Flips it; null disables the row (the last editor left on).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return SettingsRowFrame(
      title: title,
      description: description,
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged(!value),
      control: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// A setting with a current value, tapped to change it.
///
/// [value] is shown in a field under the description, the way a drop-down
/// reads; the tap opens the dialog that changes it. A null [value] makes
/// it a way to another screen instead: a chevron on the title's line and
/// no field.
final class SettingsValueRow extends StatelessWidget {
  /// Creates a row for [title] currently reading [value].
  const new({
    required this.title,
    required this.onTap,
    this.value,
    this.subtitle,
    this.badge,
    this.enabled = true,
    super.key,
  });

  /// The setting's name.
  final String title;

  /// The current value; null for a way to another screen.
  final String? value;

  /// What the setting does, under the title.
  final String? subtitle;

  /// A warning pill inside the field: the folders rows wear one naming a
  /// folder the library does not have yet (issue #104).
  final String? badge;

  /// Whether the row can be used; false greys it out.
  final bool enabled;

  /// Opens whatever changes the setting.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return SettingsRowFrame(
      title: title,
      description: subtitle,
      enabled: enabled,
      onTap: onTap,
      trailing: value == null ? const Icon(Icons.chevron_right) : null,
      control: value == null
          ? null
          : _ValueField(
              value: value,
              badge: badge,
              onTap: enabled ? onTap : null,
            ),
    );
  }
}

/// Something that happens now — export the log, check for updates — with
/// what it last did as its description.
final class SettingsActionRow extends StatelessWidget {
  /// Creates the row for [title], run by [onTap].
  const new({
    required this.title,
    required this.onTap,
    this.description,
    this.busy = false,
    this.enabled = true,
    this.destructive = false,
    super.key,
  });

  /// What the action does.
  final String title;

  /// More about it, or its last outcome.
  final String? description;

  /// Whether it is running now: a spinner, and no second tap.
  final bool busy;

  /// Whether it can run now; false greys the row out.
  final bool enabled;

  /// Whether it undoes something that is hard to get back (disconnecting
  /// a library from its server): the title reads in the error colour.
  final bool destructive;

  /// Runs it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsRowFrame(
      title: title,
      description: description,
      enabled: enabled,
      destructive: destructive,
      onTap: busy ? null : onTap,
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
    );
  }
}

/// The current value in a bordered field, as a drop-down reads.
final class _ValueField extends StatelessWidget {
  const new({required this.value, required this.onTap, this.badge});

  final String value;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = this.badge;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          foregroundColor: theme.colorScheme.onSurface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.warning_amber_outlined,
                size: 16,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Text(
                badge,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.expand_more,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
