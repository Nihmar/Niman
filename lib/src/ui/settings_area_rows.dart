/// How a settings area is listed: a row that opens it (the phone), or an
/// item that selects it (the desktop's left column, issue #172).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/settings_areas.dart';

/// One area of the settings home (issue #104): the area's name with an
/// icon and a chevron, pushing the area's own screen. The icon is an
/// outline one — an area is a place, not a state.
final class SettingsAreaRow extends StatelessWidget {
  /// Creates the row for [title]'s area.
  const new({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.disabledNote,
    super.key,
  });

  /// The row for [area], opened by [onTap]; a disabled area reads as
  /// one, with its note where the chevron would be.
  static Widget of(SettingsArea area, {required VoidCallback onTap}) =>
      SettingsAreaRow(
        key: area.rowKey,
        icon: area.icon(),
        title: area.title,
        subtitle: area.subtitle?.call(),
        disabledNote: area.enabled ? null : area.disabledNote ?? '',
        onTap: onTap,
      );

  /// The area's icon, an outline one.
  final IconData icon;

  /// The area's name.
  final String title;

  /// What the row is about right now — the sync status, a version —
  /// shown under the title the way the mockup draws it.
  final String? subtitle;

  /// Why the area cannot be opened here; non-null disables the row.
  final String? disabledNote;

  /// Opens the area's screen.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final note = disabledNote;
    return ListTile(
      leading: Icon(
        icon,
        color: note == null ? theme.colorScheme.primary : muted,
      ),
      title: Text(
        title,
        style: note == null
            ? null
            : theme.textTheme.titleMedium?.copyWith(color: muted),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: note == null
          ? const Icon(Icons.chevron_right)
          : Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
      onTap: note == null ? onTap : null,
    );
  }
}

/// One area in the desktop's left column (issue #172): its icon and
/// name, marked when it is the one on the right. No chevron — it goes
/// nowhere, it selects.
final class SettingsNavItem extends StatelessWidget {
  /// Creates the item for [area].
  new({required this.area, required this.selected, required this.onTap})
    : super(key: area.rowKey);

  /// The area it selects.
  final SettingsArea area;

  /// Whether it is the one shown.
  final bool selected;

  /// Selects it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = area.enabled;
    final color = !enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : selected
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Semantics(
            selected: selected,
            button: true,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(area.icon(), size: 18, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      area.title,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  ),
                  if (!enabled && area.disabledNote != null)
                    Text(
                      area.disabledNote!,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
