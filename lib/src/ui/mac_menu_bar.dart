/// The Mac's menu bar (docs/records/apple-platforms.md): the commands the
/// title bar's menu holds on the other desktops (#712) — the palette's
/// groups, each with its key — in the system's bar, between the app menu
/// and the Window and Help menus a Mac app is expected to have.
///
/// The menu is built from the command registry, so a command has one
/// definition wherever it shows. A command that cannot run now is
/// disabled, and one whose feature the library has off is not listed
/// (#1109), as in the title bar's menu.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/ui/app_menu.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/strings.dart';

/// Whether the system's menu bar holds the app's commands: a Mac. The title
/// bar then carries no menu of its own.
bool get systemMenuBar => defaultTargetPlatform == TargetPlatform.macOS;

/// The text keys a menu must not take: a menu's key reaches it before the
/// note does, so these stay the editor's whatever a command is bound to.
final List<SingleActivator> _textKeys = [
  for (final key in [
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.keyV,
    LogicalKeyboardKey.keyZ,
  ])
    SingleActivator(key, meta: true),
  const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true),
  findInNoteKey(mac: true),
  replaceInNoteKey(mac: true),
];

/// The app's commands in the Mac's menu bar, over [child]; [child] alone
/// anywhere else.
final class MacMenuBar extends StatefulWidget {
  /// Creates the bar; [handlers] are the commands that can run now and
  /// [features] the library's.
  const new({
    required this.handlers,
    required this.features,
    required this.child,
    super.key,
  });

  /// What each command does, for the ones that can run here and now.
  final Map<AppCommand, VoidCallback> Function() handlers;

  /// The library's features.
  final Features Function() features;

  /// What the bar is over.
  final Widget child;

  @override
  State<MacMenuBar> createState() => _MacMenuBarState();
}

final class _MacMenuBarState extends State<MacMenuBar> {
  /// What the menus were built from: the bar is sent to the system whole
  /// whenever its menus change, so they are built again only when this
  /// does — not on every frame the shell builds.
  String? _shape;

  List<PlatformMenuItem> _menus = const [];

  @override
  Widget build(BuildContext context) {
    if (!systemMenuBar) return widget.child;
    final handlers = widget.handlers();
    final features = widget.features();
    final keys = AppKeyMap.current.value;
    final groups = [
      for (final group in PaletteGroup.values)
        if (appMenuCommands(group, features) case final commands
            when commands.isNotEmpty)
          (group: group, commands: commands),
    ];
    final listed = [
      AppCommand.tabSettings,
      for (final group in groups) ...group.commands,
      ...appMenuHelp,
    ];
    final shape = [
      for (final command in listed)
        [
          command.name,
          handlers.containsKey(command),
          _keysName(command, keys),
        ].join(':'),
    ].join(',');
    if (shape != _shape) {
      _shape = shape;
      _menus = _build(groups, handlers, keys);
    }
    return PlatformMenuBar(menus: _menus, child: widget.child);
  }

  /// [_menuKeys] as text, for the menus' shape.
  String _keysName(AppCommand command, KeyMap keys) =>
      switch (_menuKeys(command, keys)) {
        final binding? => describeActivator(binding, apple: false),
        null => '-',
      };

  /// The key [command]'s item shows and answers, or null: none where it
  /// would take a key the note needs first.
  SingleActivator? _menuKeys(AppCommand command, KeyMap keys) {
    final binding = keys.bindingOf(command);
    if (binding == null) return null;
    if (keys.editorItemOn(binding) != null) return null;
    if (_textKeys.any((text) => KeyMap.sameKeys(text, binding))) return null;
    return binding;
  }

  List<PlatformMenuItem> _build(
    List<({PaletteGroup group, List<AppCommand> commands})> groups,
    Map<AppCommand, VoidCallback> handlers,
    KeyMap keys,
  ) {
    PlatformMenuItem item(AppCommand command, {String? label}) =>
        PlatformMenuItem(
          label: label ?? appMenuLabel(command),
          shortcut: _menuKeys(command, keys),
          // Looked up as it is chosen: what runs is what can run then.
          onSelected: handlers.containsKey(command)
              ? () => widget.handlers()[command]?.call()
              : null,
        );
    PlatformMenuItemGroup provided(List<PlatformProvidedMenuItemType> types) =>
        PlatformMenuItemGroup(
          members: [
            for (final type in types)
              if (PlatformProvidedMenuItem.hasMenu(type))
                PlatformProvidedMenuItem(type: type),
          ],
        );
    return [
      // The app menu: its title is the app's name, whatever this says.
      PlatformMenu(
        label: 'Niman',
        menus: [
          provided(const [PlatformProvidedMenuItemType.about]),
          PlatformMenuItemGroup(
            members: [
              item(AppCommand.tabSettings, label: '${AppStrings.tabSettings}…'),
            ],
          ),
          provided(const [PlatformProvidedMenuItemType.servicesSubmenu]),
          provided(const [
            PlatformProvidedMenuItemType.hide,
            PlatformProvidedMenuItemType.hideOtherApplications,
            PlatformProvidedMenuItemType.showAllApplications,
          ]),
          provided(const [PlatformProvidedMenuItemType.quit]),
        ],
      ),
      for (final (:group, :commands) in groups)
        PlatformMenu(
          label: paletteGroupName(group),
          menus: [
            for (final command in commands)
              if (command != AppCommand.tabSettings) item(command),
          ],
        ),
      // No full-screen item: its ⌃⌘F is Zen's (app_shortcuts.dart), and the
      // green light still takes the window full screen.
      PlatformMenu(
        label: AppStrings.macMenuWindow,
        menus: [
          provided(const [
            PlatformProvidedMenuItemType.minimizeWindow,
            PlatformProvidedMenuItemType.zoomWindow,
          ]),
          provided(const [PlatformProvidedMenuItemType.arrangeWindowsInFront]),
        ],
      ),
      PlatformMenu(
        label: AppStrings.appMenuHelp,
        menus: [for (final command in appMenuHelp) item(command)],
      ),
    ];
  }
}
