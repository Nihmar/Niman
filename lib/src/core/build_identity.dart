/// What an exported debug log says of the build and the device it ran on
/// (#1135).
///
/// The device logs the performance work is read from said which library they
/// came from and nothing else: not the version, not the commit, not the
/// device, not the screen's refresh rate. A frame of 14 ms is over budget at
/// 120 Hz and under it at 60, and a number from an unknown build cannot be
/// compared with the next one.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show Display, PlatformDispatcher;

import 'package:flutter/foundation.dart' show kProfileMode, kReleaseMode;
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/frame_cost.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The commit the build was made from, from the build-time `APP_COMMIT`
/// define (scripts/niman.sh, scripts/niman.bat, the release workflow), or
/// `unknown` for a build that did not pass one.
const String appCommit = String.fromEnvironment(
  'APP_COMMIT',
  defaultValue: 'unknown',
);

/// The header lines that name the build and the device: the app's version,
/// channel, mode and commit; the system and, on Android, the device; each
/// display's size, density and refresh rate; and whether the frame
/// instrumentation was built in.
Future<List<String>> buildIdentity() async {
  const mode = kReleaseMode
      ? 'release'
      : kProfileMode
      ? 'profile'
      : 'debug';
  var version = '?';
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } on Object {
    // A build with no package info is still worth identifying by the rest.
  }
  final device = Platform.isAndroid ? await _androidDevice() : null;
  final system =
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}, '
      '${Platform.numberOfProcessors} cores';
  String screen(Display display) =>
      '${display.size.width.round()}×${display.size.height.round()} px '
      'at ${display.devicePixelRatio}x, '
      '${display.refreshRate.toStringAsFixed(0)} Hz';
  return [
    '# app: $version, $appChannel channel, $mode build, commit $appCommit',
    '# system: $system',
    if (device != null) '# device: $device',
    for (final display in PlatformDispatcher.instance.displays)
      '# display ${display.id}: ${screen(display)}',
    '# frames: NIMAN_FRAMES ${nimanFrames ? 'on' : 'off'}',
  ];
}

/// The Android device as its properties name it — maker, model, Android
/// release and SDK — or null when they cannot be read.
Future<String?> _androidDevice() async {
  try {
    return await Isolate.run(() async {
      Future<String> prop(String key) async {
        final result = await Process.run('getprop', [key]);
        return '${result.stdout}'.trim();
      }

      final maker = await prop('ro.product.manufacturer');
      final model = await prop('ro.product.model');
      final release = await prop('ro.build.version.release');
      final sdk = await prop('ro.build.version.sdk');
      return '$maker $model, Android $release (SDK $sdk)';
    });
  } on Object {
    return null;
  }
}
