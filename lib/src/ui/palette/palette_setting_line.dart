import 'package:flutter/material.dart';
import 'package:niman/src/ui/palette/palette_setting.dart';

/// One settings row in the palette: its title, and where it lives.
final class PaletteSettingLine extends StatelessWidget {
  /// The line of [setting].
  const new({required this.setting, super.key});

  /// The row.
  final PaletteSetting setting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.tune, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            setting.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            setting.area,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
