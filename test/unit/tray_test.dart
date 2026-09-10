// T-PP-06b: the tray service's platform split and its off-desktop shape.
import 'dart:io';

import 'package:copist/src/core/shortcuts.dart';
import 'package:copist/src/core/tray.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the no-op tray takes labels and never emits', () async {
    const tray = NoopTrayService();
    await tray.init(const <ShortcutAction, String>{});
    expect(await tray.actions.isEmpty, isTrue);
    expect(await tray.activated.isEmpty, isTrue);
    await tray.dispose();
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
