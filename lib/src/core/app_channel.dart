/// The build channel this app runs on (issue #106: testing builds).
///
/// Builds pass their channel as a Dart define: the Android beta flavor
/// (the testing build) carries `--dart-define=APP_CHANNEL=testing`,
/// every other build (release, desktop, plain debug) defines nothing
/// and reads as `release`. The Android side (the flavor's application
/// ID) is gated in Gradle, so the build commands keep the two in step
/// (scripts/niman.sh, the CI release workflow).
library;

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
