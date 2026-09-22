// The desktop tray's quick actions (T-PP-06b): the same four flows the
// Android launcher publishes (T-SC-01/02) and the shell runs, on a third
// surface — a StatusNotifier item on the desktops.
//
// `nativeapi` is the T-PP-16 verdict's tray pick (`window_manager` has no
// tray, `bitsdojo_window` never had one) and is used for nothing else:
// its `WindowManager` is hidden at the import and `getCurrent()` is never
// called, because `window_manager` owns the window.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nativeapi/nativeapi.dart'
    show
        ContextMenuTrigger,
        Image,
        ImageAsset,
        Menu,
        MenuItem,
        MenuItemClickedEvent,
        MenuItemType,
        TrayIcon,
        TrayIconClickedEvent,
        TrayIconRightClickedEvent;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/windows_tray_menu.dart';

/// The tray menu's own entries (#209), beside the quick actions.
enum TrayCommand {
  /// Bring the window back — the only way to, on a desktop whose
  /// indicator has no click event of its own.
  open,

  /// Leave for good: the window closes with its usual ask about unsaved
  /// notes, and the process ends.
  quit,
}

/// What the shell needs from the desktop tray.
///
/// Implemented by [PlatformTrayService] (Linux/Windows) and
/// [NoopTrayService] (elsewhere), plus a fake in widget tests.
abstract interface class TrayService {
  /// Creates the tray icon: [openLabel] at the top, then [labels]' quick
  /// actions in order, then [quitLabel] (#209). A host without a tray (no
  /// SNI watcher, no plugin) degrades to nothing.
  ///
  /// Called again with different labels — the language changed under the
  /// menu — it relabels what is already there.
  Future<void> init({
    required Map<ShortcutAction, String> labels,
    required String openLabel,
    required String quitLabel,
  });

  /// Menu taps, carrying the same ids the launcher publishes — the shell
  /// runs them through the same `_runShortcut` as the shortcuts do.
  Stream<ShortcutAction> get actions;

  /// Clicks on the icon itself (bring the window back to the front).
  Stream<void> get activated;

  /// The menu's own entries: Open Niman, Quit (#209).
  Stream<TrayCommand> get commands;

  /// Whether the icon is on screen: false before [init], and on a host
  /// that declined it.
  bool get shown;

  /// Releases the tray icon.
  Future<void> dispose();
}

/// Which gesture has nativeapi open the tray menu.
///
/// Linux: the click *is* the menu. A StatusNotifier item has no right
/// click of its own, and nativeapi tells the desktop where the menu
/// lives only while the trigger is `clicked`: with `rightClicked` it
/// answers the SNI `Menu` property with "/", and KDE, told the item has
/// no menu, showed nothing at all (0.0.8 test round).
///
/// Windows: none — the right click is answered by [openWindowsTrayMenu],
/// because nativeapi's own popup, opened on Flutter's thread, flashed and
/// closed. The left click still brings the window back, the convention
/// there.
///
/// Elsewhere (macOS): the right click.
///
/// [isLinux] and [isWindows] override the host platform for the test.
ContextMenuTrigger trayContextMenuTrigger({bool? isLinux, bool? isWindows}) {
  if (isLinux ?? Platform.isLinux) return ContextMenuTrigger.clicked;
  if (isWindows ?? Platform.isWindows) return ContextMenuTrigger.none;
  return ContextMenuTrigger.rightClicked;
}

/// Creates the platform service: a real tray on the desktops, a no-op
/// elsewhere (Android has no tray; its quick actions are the launcher's).
///
/// [isDesktop] overrides the host platform so a plain test can cover the
/// branch that does not run here (T-PP-01).
TrayService createTrayService({bool? isDesktop}) {
  if (isDesktop ?? (Platform.isLinux || Platform.isWindows)) {
    return PlatformTrayService();
  }
  return const NoopTrayService();
}

/// The single tray service for the app session.
final trayServiceProvider = Provider<TrayService>((ref) {
  final service = createTrayService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// The `nativeapi` StatusNotifier tray.
final class PlatformTrayService implements TrayService {
  /// Creates the service; [iconAsset] is a test seam (and the M7 branding
  /// hook: the Niman mark is downscaled to `tray.png`).
  new({this.iconAsset = 'assets/branding/tray.png'});

  static const AppLogger _log = AppLogger(name: 'tray');

  /// The Flutter asset name behind the tray icon.
  final String iconAsset;
  final StreamController<ShortcutAction> _actions =
      StreamController<ShortcutAction>.broadcast();
  final StreamController<void> _activated = StreamController<void>.broadcast();
  final StreamController<TrayCommand> _commands =
      StreamController<TrayCommand>.broadcast();

  /// The native handles are kept for the tray's whole life: their finalizers
  /// must not release anything the native side still references.
  TrayIcon? _tray;
  Menu? _menu;
  Image? _icon;
  final List<MenuItem> _items = [];

  /// What each item does, by the item's native id: nativeapi's click event
  /// carries it, and so does the choice [openWindowsTrayMenu] returns.
  final Map<int, void Function()> _runs = {};

  /// Whether the Windows popup is up: a second right click while it is
  /// waits for it rather than opening another.
  bool _windowsMenuOpen = false;

  @override
  Stream<ShortcutAction> get actions => _actions.stream;

  @override
  Stream<void> get activated => _activated.stream;

  @override
  Stream<TrayCommand> get commands => _commands.stream;

  /// The labels the menu currently carries, so a repeat call with the same
  /// ones costs nothing.
  Map<ShortcutAction, String> _labels = const {};

  /// The menu's own two labels, for the same reason.
  ({String open, String quit})? _ends;

  @override
  Future<void> init({
    required Map<ShortcutAction, String> labels,
    required String openLabel,
    required String quitLabel,
  }) async {
    final ends = (open: openLabel, quit: quitLabel);
    final existing = _tray;
    if (existing != null) {
      if (!mapEquals(_labels, labels) || _ends != ends) {
        _relabel(existing, labels, ends);
      }
      return;
    }
    try {
      final tray = TrayIcon.create();
      if (tray == null) {
        _log.warning('tray unavailable (native side declined)');
        return;
      }
      tray
        ..setTooltip('Niman')
        ..setContextMenuTrigger(trayContextMenuTrigger());
      final icon = ImageAsset.fromAsset(iconAsset);
      if (icon != null) {
        _icon = icon;
        tray.icon = icon;
      }
      final built = _buildMenu(labels, ends);
      if (built == null) {
        tray.dispose();
        _log.warning('tray menu unavailable (native side declined)');
        return;
      }
      tray
        ..setContextMenu(built.menu)
        ..addListener((event) {
          if (event is TrayIconClickedEvent) _activated.add(null);
          if (event is TrayIconRightClickedEvent) {
            _log.info(
              'tray: right click (trigger ${tray.getContextMenuTrigger()}, '
              'menu ${tray.getContextMenu() != null})',
            );
            if (Platform.isWindows) unawaited(_openWindowsMenu());
          }
        });
      // Windows adds the icon to the notification area only here
      // (`NIM_ADD` lives in `SetVisible`); without it the tray existed,
      // said it was ready, and never appeared. Linux and macOS show it
      // anyway, and take the call as a no-op.
      if (!tray.setVisible(true)) {
        _log.warning('tray icon could not be shown');
        tray.dispose();
        built.menu.dispose();
        for (final item in built.items) {
          item.dispose();
        }
        return;
      }
      _tray = tray;
      _menu = built.menu;
      _items.addAll(built.items);
      _labels = Map<ShortcutAction, String>.of(labels);
      _ends = ends;
      _log.info('tray ready (${labels.length} actions)');
    } on Object catch (error) {
      // A session without SNI (or a build without the native library) is a
      // missing convenience, not a reason to fail the launch.
      _log.warning('tray init failed ($error)');
    }
  }

  /// Opens the menu from an owner that can take the foreground, and runs what
  /// was chosen (Windows; see [openWindowsTrayMenu]).
  Future<void> _openWindowsMenu() async {
    final menu = _menu;
    if (menu == null || _windowsMenuOpen) return;
    _windowsMenuOpen = true;
    try {
      final choice = await openWindowsTrayMenu(menu.nativeObject.address);
      _log.info('tray: menu closed (chose ${choice.chosen}; ${choice.report})');
      if (choice.chosen != 0) _runs[choice.chosen]?.call();
    } on Object catch (error) {
      _log.warning('tray: the menu could not be opened ($error)');
    } finally {
      _windowsMenuOpen = false;
    }
  }

  /// Hangs a fresh menu on the icon and lets the old one go.
  ///
  /// A menu item's label is fixed when it is created, so a language change
  /// means new items. The new menu is hung first and the old one released
  /// after, never the other way round: the native side must never be
  /// pointed at something already freed.
  void _relabel(
    TrayIcon tray,
    Map<ShortcutAction, String> labels,
    ({String open, String quit}) ends,
  ) {
    try {
      final built = _buildMenu(labels, ends);
      if (built == null) {
        _log.warning('tray relabel declined by the native side');
        return;
      }
      final old = _menu;
      final oldItems = List<MenuItem>.of(_items);
      tray.setContextMenu(built.menu);
      _menu = built.menu;
      _items
        ..clear()
        ..addAll(built.items);
      _labels = Map<ShortcutAction, String>.of(labels);
      _ends = ends;
      old?.dispose();
      for (final item in oldItems) {
        _runs.remove(item.id);
        item.dispose();
      }
      _log.info('tray relabelled (${labels.length} actions)');
    } on Object catch (error) {
      _log.warning('tray relabel failed ($error)');
    }
  }

  /// Builds a menu carrying [labels] and the items in it, or null when the
  /// native side declines.
  ({Menu menu, List<MenuItem> items})? _buildMenu(
    Map<ShortcutAction, String> labels,
    ({String open, String quit}) ends,
  ) {
    final menu = Menu.create();
    if (menu == null) return null;
    final items = <MenuItem>[];

    /// One entry, with what a click on it means.
    void add(String label, void Function() run) {
      final item = MenuItem.createWithLabelAndType(label, MenuItemType.normal);
      if (item == null) return;
      _runs[item.id] = run;
      item.addListener((event) {
        if (event is! MenuItemClickedEvent || event.itemId != item.id) return;
        run();
      });
      menu.addItem(item);
      items.add(item);
    }

    // Open first (#209): on Linux the indicator has no click of its own,
    // so this is the way back to the window.
    add(ends.open, () {
      _log.debug('tray: open');
      _commands.add(TrayCommand.open);
    });
    menu.addSeparator();
    for (final entry in labels.entries) {
      add(entry.value, () {
        _log.debug('tray action: ${entry.key.id}');
        _actions.add(entry.key);
      });
    }
    menu.addSeparator();
    add(ends.quit, () {
      _log.debug('tray: quit');
      _commands.add(TrayCommand.quit);
    });
    return (menu: menu, items: items);
  }

  @override
  bool get shown => _tray != null;

  @override
  Future<void> dispose() async {
    _tray?.dispose();
    _menu?.dispose();
    for (final item in _items) {
      item.dispose();
    }
    _icon?.dispose();
    _runs.clear();
    _tray = null;
    _menu = null;
    _icon = null;
    _items.clear();
    await _actions.close();
    await _activated.close();
    await _commands.close();
  }
}

/// The off-desktop service: no tray, nothing ever arrives.
final class NoopTrayService implements TrayService {
  /// Creates the no-op service.
  const new();

  @override
  Future<void> init({
    required Map<ShortcutAction, String> labels,
    required String openLabel,
    required String quitLabel,
  }) async {}

  @override
  Stream<ShortcutAction> get actions => const Stream<ShortcutAction>.empty();

  @override
  Stream<void> get activated => const Stream<void>.empty();

  @override
  Stream<TrayCommand> get commands => const Stream<TrayCommand>.empty();

  @override
  bool get shown => false;

  @override
  Future<void> dispose() async {}
}
