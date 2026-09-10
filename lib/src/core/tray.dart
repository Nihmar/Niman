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

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/shortcuts.dart';
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
        TrayIconClickedEvent;

/// What the shell needs from the desktop tray.
///
/// Implemented by [PlatformTrayService] (Linux/Windows) and
/// [NoopTrayService] (elsewhere), plus a fake in widget tests.
abstract interface class TrayService {
  /// Creates the tray icon offering [labels], in order. A host without a
  /// tray (no SNI watcher, no plugin) degrades to nothing.
  ///
  /// Called again with different labels — the language changed under the
  /// menu — it relabels what is already there.
  Future<void> init(Map<ShortcutAction, String> labels);

  /// Menu taps, carrying the same ids the launcher publishes — the shell
  /// runs them through the same `_runShortcut` as the shortcuts do.
  Stream<ShortcutAction> get actions;

  /// Clicks on the icon itself (bring the window back to the front).
  Stream<void> get activated;

  /// Releases the tray icon.
  Future<void> dispose();
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
  /// hook: the placeholder feather is downscaled to `tray.png`).
  new({this.iconAsset = 'assets/branding/tray.png'});

  static const AppLogger _log = AppLogger(name: 'tray');

  /// The Flutter asset name behind the tray icon.
  final String iconAsset;
  final StreamController<ShortcutAction> _actions =
      StreamController<ShortcutAction>.broadcast();
  final StreamController<void> _activated = StreamController<void>.broadcast();

  /// The native handles are kept for the tray's whole life: their finalizers
  /// must not release anything the native side still references.
  TrayIcon? _tray;
  Menu? _menu;
  Image? _icon;
  final List<MenuItem> _items = [];

  @override
  Stream<ShortcutAction> get actions => _actions.stream;

  @override
  Stream<void> get activated => _activated.stream;

  /// The labels the menu currently carries, so a repeat call with the same
  /// ones costs nothing.
  Map<ShortcutAction, String> _labels = const {};

  @override
  Future<void> init(Map<ShortcutAction, String> labels) async {
    final existing = _tray;
    if (existing != null) {
      if (!mapEquals(_labels, labels)) _relabel(existing, labels);
      return;
    }
    try {
      final tray = TrayIcon.create();
      if (tray == null) {
        _log.warning('tray unavailable (native side declined)');
        return;
      }
      tray
        ..setTooltip('Copist')
        ..setContextMenuTrigger(ContextMenuTrigger.rightClicked);
      final icon = ImageAsset.fromAsset(iconAsset);
      if (icon != null) {
        _icon = icon;
        tray.icon = icon;
      }
      final built = _buildMenu(labels);
      if (built == null) {
        tray.dispose();
        _log.warning('tray menu unavailable (native side declined)');
        return;
      }
      tray
        ..setContextMenu(built.menu)
        ..addListener((event) {
          if (event is TrayIconClickedEvent) _activated.add(null);
        });
      _tray = tray;
      _menu = built.menu;
      _items.addAll(built.items);
      _labels = Map<ShortcutAction, String>.of(labels);
      _log.info('tray ready (${labels.length} actions)');
    } on Object catch (error) {
      // A session without SNI (or a build without the native library) is a
      // missing convenience, not a reason to fail the launch.
      _log.warning('tray init failed ($error)');
    }
  }

  /// Hangs a fresh menu on the icon and lets the old one go.
  ///
  /// A menu item's label is fixed when it is created, so a language change
  /// means new items. The new menu is hung first and the old one released
  /// after, never the other way round: the native side must never be
  /// pointed at something already freed.
  void _relabel(TrayIcon tray, Map<ShortcutAction, String> labels) {
    try {
      final built = _buildMenu(labels);
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
      old?.dispose();
      for (final item in oldItems) {
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
  ) {
    final menu = Menu.create();
    if (menu == null) return null;
    final items = <MenuItem>[];
    for (final entry in labels.entries) {
      final item = MenuItem.createWithLabelAndType(
        entry.value,
        MenuItemType.normal,
      );
      if (item == null) continue;
      item.addListener((event) {
        if (event is! MenuItemClickedEvent || event.itemId != item.id) return;
        _log.debug('tray action: ${entry.key.id}');
        _actions.add(entry.key);
      });
      menu.addItem(item);
      items.add(item);
    }
    return (menu: menu, items: items);
  }

  @override
  Future<void> dispose() async {
    _tray?.dispose();
    _menu?.dispose();
    for (final item in _items) {
      item.dispose();
    }
    _icon?.dispose();
    _tray = null;
    _menu = null;
    _icon = null;
    _items.clear();
    await _actions.close();
    await _activated.close();
  }
}

/// The off-desktop service: no tray, nothing ever arrives.
final class NoopTrayService implements TrayService {
  /// Creates the no-op service.
  const new();

  @override
  Future<void> init(Map<ShortcutAction, String> labels) async {}

  @override
  Stream<ShortcutAction> get actions => const Stream<ShortcutAction>.empty();

  @override
  Stream<void> get activated => const Stream<void>.empty();

  @override
  Future<void> dispose() async {}
}
