// T-PP-01: the platform-capability matrix.
//
// Every factory that swaps a platform implementation for an inert
// stand-in is exercisable from a plain unit test, on any host, so the
// branch that does *not* run here is still covered: an optional override
// pins the platform while the default keeps reading `Platform.*`. That is
// the contract, and this file is what fails if someone reintroduces a
// factory whose branches can only be half-tested by hand.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/tray.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/ui/window_controller.dart';

void main() {
  // The platform services reach method channels (and `window_manager`'s
  // singleton) in their constructors, exactly as they do in the app
  // right after `WidgetsFlutterBinding.ensureInitialized()`.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('launcher shortcuts', () {
    test('are Android-only', () {
      expect(
        createShortcutService(isAndroid: true),
        isA<PlatformShortcutService>(),
      );
      expect(
        createShortcutService(isAndroid: false),
        isA<NoopShortcutService>(),
      );
    });

    test('the no-op is inert', () async {
      const service = NoopShortcutService();
      expect(service.actions, emitsDone);
      expect(await service.consumeLaunchAction(), isNull);
      await service.publish(const <ShortcutAction, String>{});
      await service.dispose();
    });
  });

  group('reminders', () {
    test('are Android and desktop; the Noop is for anything else', () {
      final android = createReminderService(isAndroid: true, isDesktop: false);
      final desktop = createReminderService(isAndroid: false, isDesktop: true);
      final other = createReminderService(isAndroid: false, isDesktop: false);
      addTearDown(android.dispose);
      addTearDown(desktop.dispose);
      addTearDown(other.dispose);

      expect(android, isA<LocalReminderService>());
      expect(desktop, isA<LocalReminderService>());
      expect(other, isA<NoopReminderService>());
    });

    test('the no-op is inert and always healthy', () async {
      const service = NoopReminderService();
      expect(service.taps, emitsDone);
      expect(await service.consumeLaunchPayload(), isNull);
      expect(service.health.value, ReminderHealth.ok);
      await service.dispose();
    });
  });

  group('tray', () {
    test('is desktop-only', () {
      expect(createTrayService(isDesktop: true), isA<PlatformTrayService>());
      expect(createTrayService(isDesktop: false), isA<NoopTrayService>());
    });

    test('the no-op is inert', () async {
      const service = NoopTrayService();
      expect(service.actions, emitsDone);
      expect(service.activated, emitsDone);
      await service.init(const <ShortcutAction, String>{});
      await service.dispose();
    });
  });

  group('window controller', () {
    test('the desktops get the real one, the phone the stand-in', () {
      final desktop = createWindowController(isDesktop: true);
      final phone = createWindowController(isDesktop: false);
      addTearDown(desktop.dispose);
      addTearDown(phone.dispose);
      expect(desktop, isA<WindowManagerController>());
      expect(phone, isA<NoopWindowController>());
      // The custom title bar is a desktop window feature; Android keeps
      // the system bar (T-PP-11's AC).
      expect(phone.customTitleBar, isFalse);
    });

    test('the no-op is inert', () async {
      final controller = NoopWindowController();
      await controller.init();
      expect(controller.customTitleBar, isFalse);
      expect(controller.maximized.value, isFalse);
      await controller.setPreventClose(prevent: true);
      await controller.show();
      await controller.minimize();
      await controller.close();
      await controller.toggleMaximize();
      await controller.applyCustomTitleBar();
      await controller.dispose();
    });
  });
}
