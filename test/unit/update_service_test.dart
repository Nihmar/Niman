// Issue #81: the Android installer bridge hands the APK to the system.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/update/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installApk', () {
    test('passes the apk path to the system installer', () async {
      String? installed;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('niman/update');
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'installApk');
        installed = (call.arguments as Map)['path'] as String?;
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      expect(await installApk(File('niman-1.0.0-android.apk')), true);
      expect(installed, 'niman-1.0.0-android.apk');
    });

    test(
      'an unreachable bridge keeps the download without launching',
      () async {
        expect(await installApk(File('niman-1.0.0-android.apk')), false);
      },
    );
  });
}
