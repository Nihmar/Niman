/// The build channel this app runs on (issue #106: testing builds).
///
/// Builds pass their channel as a Dart define: the Android beta flavor
/// (the testing build) carries `--dart-define=APP_CHANNEL=testing`,
/// every other build (release, desktop, plain debug) defines nothing
/// and reads as `release`. The Android side (the flavor's application
/// ID) is gated in Gradle, so the build commands keep the two in step
/// (scripts/niman.sh, the CI release workflow).
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The build channel, from the build-time `APP_CHANNEL` define.
const String appChannel = String.fromEnvironment(
  'APP_CHANNEL',
  defaultValue: 'release',
);

/// Whether this is a sideloaded testing build (issue #106).
///
/// Testing builds carry no update management: the Updates settings
/// section is hidden and the update scheduler never starts, whatever
/// the stored auto-update toggle says — the two installs share no
/// release channel, so there is nothing for them to check.
const bool isTestingBuild = appChannel == 'testing';

/// The folder this build keeps its own files in: the settings database, the
/// indexes, the log, the single-instance claim.
///
/// The platform's application-support folder — except for a desktop testing
/// build, which keeps a sibling of its own (`…/niman-testing`). On Android
/// the testing build is another application ID and has its own folder by
/// construction; on the desktop both builds are one `niman.exe` under one
/// product name, and they shared one database. A testing build migrated it
/// to a schema the installed release did not know, the release took the
/// version back down, and the testing build's next migration failed on the
/// columns it had already dropped (2026-09-22). Two builds, two folders.
Future<Directory> appSupportDirectory() async {
  final support = await getApplicationSupportDirectory();
  if (!isTestingBuild || Platform.isAndroid || Platform.isIOS) return support;
  final own = Directory(
    p.join(support.parent.path, '${p.basename(support.path)}-testing'),
  );
  if (!own.existsSync()) await own.create(recursive: true);
  return own;
}
