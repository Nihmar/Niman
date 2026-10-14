/// The app's menu on a desktop (#712): every command, grouped the way the
/// palette names them — Note, Editor, View, Library, Journal, Go to and
/// Help — each with its key, in one compact button of the title bar.
///
/// It lists what the palette lists and runs it the same way: the shell's
/// handlers for the commands that can run now. One that cannot is shown
/// disabled, so a menu keeps its shape whatever is on screen.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/strings.dart';

/// The commands named on their own, which the Help menu holds.
const List<AppCommand> _help = [
  AppCommand.openPalette,
  AppCommand.welcomeTour,
  AppCommand.welcomeDeck,
];

/// The title bar's menu button.
final class AppMenuButton extends StatefulWidget {
  /// Creates the button; [handlers] are the commands that can run now.
  const new({required this.handlers, super.key});

  /// What each command does, for the ones that can run here and now.
  final Map<AppCommand, VoidCallback> Function() handlers;

  @override
  State<AppMenuButton> createState() => _AppMenuButtonState();
}

final class _AppMenuButtonState extends State<AppMenuButton> {
  @override
  Widget build(BuildContext context) {
    final handlers = widget.handlers();
    final keys = AppKeyMap.current.value;
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    Widget item(AppCommand command) {
      final binding = keys.bindingOf(command);
      final label = appCommandLabel(command);
      return MenuItemButton(
        key: Key('app-menu-${command.name}'),
        onPressed: handlers[command],
        // The keys as the app names them, small and quiet at the row's
        // end: Flutter's own label for `shortcut` is set in the label's
        // style and no theme reaches it.
        trailingIcon: binding is SingleActivator
            ? Text(describeActivator(binding), style: hint)
            : null,
        child: Text(paletteAsks(command) ? '$label…' : label),
      );
    }

    return MenuAnchor(
      // Read again as it opens: what can run changes with what is open.
      onOpen: () => setState(() {}),
      menuChildren: [
        for (final group in PaletteGroup.values)
          SubmenuButton(
            key: Key('app-menu-group-${group.name}'),
            menuChildren: [
              if (group == PaletteGroup.goTo) item(AppCommand.goToNote),
              for (final command in AppCommand.values)
                if (paletteGroup(command) == group) item(command),
            ],
            child: Text(paletteGroupName(group)),
          ),
        SubmenuButton(
          key: const Key('app-menu-group-help'),
          menuChildren: [for (final command in _help) item(command)],
          child: Text(AppStrings.appMenuHelp),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        key: const Key('app-menu'),
        tooltip: AppStrings.appMenuTooltip,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.menu),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
