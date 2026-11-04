import 'package:flutter/material.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/palette/pinned_commands.dart';
import 'package:niman/src/ui/strings.dart';

/// One command in the palette: its name, its key and its pin.
final class PaletteCommandLine extends StatelessWidget {
  /// The line of [command].
  const new({required this.command, this.pin, this.keys = true, super.key});

  /// The command.
  final PaletteCommand command;

  /// Whether to show the command's key: there has to be a keyboard to
  /// press it on (#230).
  final bool keys;

  /// Pins or unpins this row's command (#208); null leaves the pin out.
  final void Function(AppCommand command)? pin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final binding = command.binding;
    return Row(
      children: [
        Expanded(
          child: Text(
            command.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (binding != null && keys)
          Text(
            describeActivator(binding),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        if (pin case final pin?) ...[
          const SizedBox(width: 6),
          _PinButton(command: command.command, onPressed: pin),
        ],
      ],
    );
  }
}

/// The pin on a command's row: filled while it is pinned.
final class _PinButton extends StatelessWidget {
  const new({required this.command, required this.onPressed});

  final AppCommand command;
  final void Function(AppCommand command) onPressed;

  @override
  Widget build(BuildContext context) {
    final pinned = PinnedCommands.isPinned(command);
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      key: Key('palette-pin-${command.name}'),
      tooltip: pinned ? AppStrings.paletteUnpin : AppStrings.palettePin,
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      color: pinned ? scheme.primary : scheme.onSurfaceVariant,
      icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
      onPressed: () => onPressed(command),
    );
  }
}
