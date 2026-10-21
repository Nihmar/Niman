import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/apple_app_events.dart';
import 'package:niman/src/core/crash_reporter.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/frame_cost.dart';
import 'package:niman/src/core/host_platform.dart';
import 'package:niman/src/core/launch_args.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/log_file.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/single_instance.dart';
import 'package:niman/src/widget/widget_toggle.dart';
import 'package:path/path.dart' as p;

/// Entrypoint of the Niman application.
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // The Mac app is not sandboxed (docs/records/apple-platforms.md), so it
  // declares no user-selected file entitlement, and file_picker refuses
  // every dialog unless told not to look for one.
  if (Platform.isMacOS) await FilePicker.skipEntitlementsChecks();
  CrashReporter.install();
  unawaited(_attachLogFile());
  unawaited(_registerWidgetToggle());
  _reportSlowFrames();
  // Desktop only by construction: Android launches with no arguments, so
  // the platform service stays in charge there.
  final launch = parseLaunchArgs(args, cwd: _readableCurrentDirectory());
  // From here on the app owns its working directory (see
  // [_pinWorkingDirectory]): the one it was started in belongs to whoever
  // launched it, and it can be rebuilt under a running app (#319).
  unawaited(_pinWorkingDirectory());
  final desktop = HostPlatform.isDesktop;
  // One Niman per session (#41): a later launch hands itself to the first
  // and ends here, before it opens anything.
  final instance = desktop ? await _claimSession(launch) : null;
  if (desktop && instance == null) exit(0);
  // A Mac or an iPhone opens a note in the running app instead of starting
  // another: those files join the later launches, and the ones kept from
  // before Dart listened — a note opened from outside started the app —
  // the first of them as the file the app started with.
  final appleFiles = Platform.isMacOS || Platform.isIOS
      ? await AppleAppEvents.instance.takePendingFiles()
      : const <String>[];
  final launches = instance?.launches.map(LaunchArgs.fromJson);
  final later = launches == null
      ? null
      : _withAppleFiles(launches, kept: appleFiles.skip(1)).asBroadcastStream();
  runApp(
    ProviderScope(
      overrides: [
        if (desktop)
          shortcutServiceProvider.overrideWith(
            (ref) => CliShortcutService(
              launch.action,
              later: later == null
                  ? const Stream.empty()
                  : later
                        .map((launch) => launch.action)
                        .where((action) => action != null)
                        .cast<ShortcutAction>(),
            ),
          ),
        // An iPhone has no later launches, only the notes the Files app
        // asks it to open.
        if (Platform.isIOS)
          launchRequestsProvider.overrideWithValue(
            LaunchRequests(
              file: appleFiles.firstOrNull,
              later: _withAppleFiles(
                const Stream<LaunchArgs>.empty(),
                kept: appleFiles.skip(1),
              ).asBroadcastStream(),
            ),
          ),
        if (desktop)
          launchRequestsProvider.overrideWithValue(
            LaunchRequests(
              file: launch.openPath ?? appleFiles.firstOrNull,
              later: later ?? const Stream.empty(),
            ),
          ),
      ],
      child: const NimanApp(),
    ),
  );
}

/// [launches], with the Apple platforms' notes to open as launches that
/// open them: the ones Finder or the Files app hands the running app, after
/// [kept], the ones held from before Dart listened. Elsewhere [launches]
/// alone.
Stream<LaunchArgs> _withAppleFiles(
  Stream<LaunchArgs> launches, {
  required Iterable<String> kept,
}) {
  if (!Platform.isMacOS && !Platform.isIOS) return launches;
  final merged = StreamController<LaunchArgs>();
  final subscriptions = <StreamSubscription<LaunchArgs>>[];
  merged
    ..onListen = () {
      for (final stream in [
        launches,
        Stream.fromIterable(kept).map((path) => LaunchArgs(openPath: path)),
        AppleAppEvents.instance.files.map((path) => LaunchArgs(openPath: path)),
      ]) {
        subscriptions.add(stream.listen(merged.add));
      }
    }
    ..onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
  return merged.stream;
}

/// The process's working directory, when it can still be read, and the
/// system's temp directory otherwise.
///
/// A shell sitting in a folder that is gone since leaves its children with
/// a working directory `Directory.current` throws on, and that used to take
/// the launch down here, before the app had started and before anything
/// could log it (#319). The temp directory is only a stand-in: nothing of
/// the app's resolves against it.
String _readableCurrentDirectory() {
  try {
    return Directory.current.path;
  } on Object {
    return Directory.systemTemp.path;
  }
}

/// Hands the process a working directory it owns: Niman's own support
/// folder (see [pinWorkingDirectory]).
///
/// Best effort and unawaited: a folder that cannot be made the working
/// directory is a degraded mode, not a launch failure, and the app's own
/// paths are absolute either way.
Future<void> _pinWorkingDirectory() async {
  try {
    pinWorkingDirectory(await appSupportDirectory());
  } on Object catch (error) {
    const AppLogger(name: 'files')
        .warning('working directory not pinned ($error)');
  }
}

/// Claims the session for this process, or hands [launch] to the Niman
/// already holding it and answers null.
///
/// A failure to claim at all (an unwritable support folder) must not stop
/// Niman from starting: it runs unguarded, as it did before #41, and says
/// so in the log. The instance answered then is a stand-in that is never
/// handed anything.
Future<SingleInstance?> _claimSession(LaunchArgs launch) async {
  try {
    final dir = await appSupportDirectory();
    return await SingleInstance.claim(dir, launch.toJson());
  } on Object catch (error) {
    const AppLogger(name: 'instance').warning('running unguarded ($error)');
    return SingleInstance.unguarded();
  }
}

/// Registers the widget checkbox toggle (round 2, R2): without this the
/// background taps have no Dart callback to reach.
///
/// Android-only and best-effort — like the log file, a missing handler
/// is a degraded mode, not a launch failure.
Future<void> _registerWidgetToggle() async {
  if (!Platform.isAndroid) return;
  try {
    await registerWidgetToggle();
  } on MissingPluginException {
    // No host handler (tests).
  } on PlatformException catch (error) {
    const AppLogger(name: 'widgets').warning('toggle not registered ($error)');
  }
}

/// Points the log buffer at a file in the app's private support directory.
///
/// Without it the log lives only in memory and dies with the process,
/// which is exactly when it is worth reading: a reminder that fired (or
/// did not) with the app closed, an OEM battery kill, a reboot. Async and
/// unawaited so it never delays the first frame; the lines logged before
/// it lands are still in the buffer and reach the file on the first flush.
Future<void> _attachLogFile() async {
  try {
    final dir = await appSupportDirectory();
    final path = p.join(dir.path, 'niman-log.txt');
    AppLog.file = LogFile(path: path);
    const AppLogger(name: 'log').info('log file attached: $path');
  } on Object catch (error) {
    // Memory-only logging is a degraded mode, not a failure worth
    // taking the app down for.
    const AppLogger(name: 'log').warning('log file unavailable ($error)');
  }
}

/// Logs every frame whose total UI work misses the 60 Hz budget, so jank
/// (while editing novel-length notes, scrolling, …) is visible in the
/// exported debug log together with the build/raster/vsync breakdown.
///
/// Only the slow ones. A round of tab-switch profiling briefly logged
/// every rendered frame, which answered "how many frames did that
/// animation take" but cost more than it was worth: at 60 lines a second
/// while anything moves, it fills the 5000-line buffer in under two
/// minutes and rotates the 512 KB disk mirror about as fast. That mirror
/// exists to survive the process — a reminder that fired with the app
/// closed, an OEM kill — and an export taken after a few minutes of
/// ordinary use no longer held any of it. Formatting a line per frame on
/// the UI isolate also charges the very frames it measures.
///
/// Timing every frame is the right tool for a profiling round, not for a
/// build someone uses: it is behind `NIMAN_FRAMES`
/// (`--dart-define=NIMAN_FRAMES=true`), the switch the views' own frame
/// lines wear, so a release build attaches no timings callback at all
/// (#362).
void _reportSlowFrames() {
  if (!nimanFrames) return;
  const logger = AppLogger(name: 'frames');
  const budget = Duration(milliseconds: 16);
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      final total = timing.totalSpan;
      if (total < budget) continue;
      logger.warning(
        'slow frame: total ${_ms(total)} '
        '(build ${_ms(timing.buildDuration)}, '
        'raster ${_ms(timing.rasterDuration)}, '
        'vsync ${_ms(timing.vsyncOverhead)})',
      );
    }
  });
}

String _ms(Duration d) => '${(d.inMicroseconds / 1000).toStringAsFixed(1)} ms';
