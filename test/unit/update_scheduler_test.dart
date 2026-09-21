// Issue #81: the auto-update scheduler runs gated checks on schedule.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/update/app_version.dart';
import 'package:niman/src/update/release_asset.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:niman/src/update/update_scheduler.dart';

UpdateAvailable sampleUpdate() => const UpdateAvailable(
  version: AppVersion(1, 0, 0),
  asset: ReleaseAsset(
    name: 'niman-1.0.0-linux-x64.AppImage',
    downloadUrl: 'https://example.com/niman-1.0.0-linux-x64.AppImage',
  ),
);

void main() {
  group('UpdateScheduler', () {
    test('start runs the launch check and reports the update', () async {
      var checks = 0;
      final noted = <DateTime>[];
      UpdateAvailable? seen;
      final scheduler = UpdateScheduler(
        isEnabled: () async => true,
        runCheck: () async {
          checks++;
          return sampleUpdate();
        },
        noteChecked: (time) async => noted.add(time),
        onUpdate: (update) => seen = update,
        startupDelay: Duration.zero,
      )..start();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      scheduler.stop();
      expect(checks, 1);
      expect(noted, hasLength(1));
      expect(seen?.version, const AppVersion(1, 0, 0));
    });

    test('a disabled toggle skips the check entirely', () async {
      var checks = 0;
      final scheduler = UpdateScheduler(
        isEnabled: () async => false,
        runCheck: () async {
          checks++;
          return sampleUpdate();
        },
        noteChecked: (_) async => fail('must not record a skipped check'),
        onUpdate: (_) => fail('must not report while disabled'),
        startupDelay: Duration.zero,
        checkInterval: const Duration(milliseconds: 50),
      )..start();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      scheduler.stop();
      expect(checks, 0);
    });

    test('the periodic timer re-checks until stopped', () async {
      var checks = 0;
      final scheduler = UpdateScheduler(
        isEnabled: () async => true,
        runCheck: () async {
          checks++;
          return null;
        },
        noteChecked: (_) async {},
        onUpdate: (_) => fail('nothing is newer'),
        startupDelay: const Duration(hours: 6),
        checkInterval: const Duration(milliseconds: 50),
      )..start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      scheduler.stop();
      // A check already past its gate finishes after the stop — that is what
      // `checkOnce` does, and it is not a leak — so let it land before
      // counting. Reading the count immediately made this fail under load: one
      // tick of the 50 ms timer was in flight and the suite saw 6 where it
      // wanted 5 (2026-09-21, with a build running beside it).
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final ran = checks;
      expect(ran, greaterThanOrEqualTo(2));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(checks, ran, reason: 'the periodic timer really stopped');
    });

    test('a failing check is quiet and records nothing', () async {
      var reported = false;
      final scheduler = UpdateScheduler(
        isEnabled: () async => true,
        runCheck: () async => throw const FormatException('offline'),
        noteChecked: (_) async => fail('a failed check is not recorded'),
        onUpdate: (_) => reported = true,
      );
      await scheduler.checkOnce();
      expect(reported, false);
    });

    // Closing a library within the launch delay left the first check to
    // fire on the settings database that closed with it.
    test('stopped before the launch check, it never runs', () async {
      var checks = 0;
      UpdateScheduler(
          isEnabled: () async {
            checks++;
            return true;
          },
          runCheck: () async => null,
          noteChecked: (_) async {},
          onUpdate: (_) {},
          startupDelay: const Duration(milliseconds: 50),
        )
        ..start()
        ..stop();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(checks, 0);
    });

    test('a failing gate is as quiet as a failing check', () async {
      final scheduler = UpdateScheduler(
        isEnabled: () async => throw StateError('database closed'),
        runCheck: () async => fail('not reached'),
        noteChecked: (_) async => fail('not reached'),
        onUpdate: (_) => fail('not reached'),
      );
      await scheduler.checkOnce();
    });
  });
}
