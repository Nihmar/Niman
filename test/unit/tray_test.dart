// T-PP-06b: the tray service's platform split and its off-desktop shape.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nativeapi/nativeapi.dart' show ContextMenuTrigger;
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/tray.dart';

void main() {
  test('the no-op tray takes labels and never emits', () async {
    const tray = NoopTrayService();
    await tray.init(
      labels: const <ShortcutAction, String>{},
      openLabel: 'Open Niman',
      quitLabel: 'Quit',
    );
    expect(await tray.actions.isEmpty, isTrue);
    expect(await tray.activated.isEmpty, isTrue);
    expect(await tray.commands.isEmpty, isTrue);
    await tray.dispose();
  });

  // 0.0.8 test round: nothing at all appeared on KDE. A StatusNotifier
  // item has no right click of its own, and nativeapi publishes the
  // menu's path only for the click trigger — with the other one it tells
  // the desktop the item has no menu.
  test('Linux opens the menu on the click; Windows on the right one', () {
    expect(trayContextMenuTrigger(isLinux: true), ContextMenuTrigger.clicked);
    // Windows opens its own popup on the right click (WindowsTrayMenu).
    expect(
      trayContextMenuTrigger(isLinux: false, isWindows: true),
      ContextMenuTrigger.none,
    );
    expect(
      trayContextMenuTrigger(isLinux: false, isWindows: false),
      ContextMenuTrigger.rightClicked,
    );
  });

  test('the desktops get the real service; elsewhere the no-op', () {
    final service = createTrayService();
    if (Platform.isLinux || Platform.isWindows) {
      expect(service, isA<PlatformTrayService>());
    } else {
      expect(service, isA<NoopTrayService>());
    }
  });
}
