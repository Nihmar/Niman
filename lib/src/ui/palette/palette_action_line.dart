import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/ui/home/home_icons.dart';

/// One Home action in the palette (#535): its icon and its name.
final class PaletteActionLine extends StatelessWidget {
  /// The line of [action], read as [name].
  const new({required this.action, required this.name, super.key});

  /// The action.
  final HomeAction action;

  /// Its name.
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: Key('palette-action-${action.id}'),
      children: [
        Icon(
          homeActionIcon(action),
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
