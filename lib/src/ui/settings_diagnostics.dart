import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/changelog.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/changelog.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Diagnostics and info area of the settings home (issue #104): the
/// debug switch and the log export, plus what the installation is.
final class SettingsDiagnosticsScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  State<SettingsDiagnosticsScreen> createState() =>
      _SettingsDiagnosticsScreenState();
}

final class _SettingsDiagnosticsScreenState
    extends State<SettingsDiagnosticsScreen> {
  bool? _debugLogs;
  String? _version;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final debug = await widget.controller.debugLogsEnabled;
    if (!mounted) return;
    setState(() => _debugLogs = debug);
    // Kept out of the load above: the platform channel behind
    // [appVersion] has no answer in the test environment and would hold
    // the screen's first build hostage.
    unawaited(_loadVersion());
  }

  /// Loads the app's own version for the About row (issue #80).
  Future<void> _loadVersion() async {
    String? version;
    try {
      version = await appVersion();
    } on Exception catch (_) {
      // Display-only: no answer just leaves the row out.
    }
    if (mounted && version != null) {
      setState(() => _version = version);
    }
  }

  Future<void> _toggleDebugLogs(bool value) async {
    final controller = widget.controller;
    await controller.setDebugLogsEnabled(enabled: value);
    if (mounted) {
      setState(() => _debugLogs = value);
    }
  }

  /// Opens a save dialog letting the user choose where the debug log goes,
  /// and writes the buffered lines (+ a context header, + the device
  /// logcat on Android) to the chosen file.
  Future<void> _exportLog() async {
    final controller = widget.controller;
    // Earlier runs first: the disk mirror holds what the process before
    // this one recorded (a reminder firing with the app closed, an OEM
    // kill), which the in-memory buffer can never have.
    //
    // The two overlap: reading the mirror flushes it, so everything this
    // run has logged since the file was attached is in BOTH. Keep only
    // the memory lines the mirror does not already carry -- in practice
    // the handful recorded before the attach landed. Timestamps run to
    // the millisecond, so identical lines are the same event.
    final persisted = await AppLog.file?.read() ?? '';
    final onDisk = persisted.split('\n').toSet();
    final lines = <String>[
      for (final line in AppLog.lines())
        if (!onDisk.contains(line)) line,
    ];
    // The device's own logcat for this app (Android): the native Kotlin
    // logs, the plugins and the engine lines the AppLog buffer never
    // sees (widget provider, config activity).
    final logcat = await _logcatDump();
    // The durable native widget log (Kotlin): the placement decisions
    // logcat's ring buffer has already forgotten (a config rejection,
    // an aborted dialog).
    final widgetLog = await _widgetDebugLog();
    final hasLogcat = logcat != null && logcat.trim().isNotEmpty;
    if (lines.isEmpty && persisted.isEmpty && !hasLogcat) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.exportLogEmpty)));
      }
      return;
    }
    final now = DateTime.now();
    final stamp = _fileStamp(now);
    final phase =
        'phase: ${controller.phase.name}, '
        'lastError: ${controller.lastError ?? '-'}';
    final content = <String>[
      '# Niman debug log',
      '# exported: ${now.toIso8601String()}',
      '# library: ${controller.root ?? '(none)'}',
      '# $phase',
      '',
      if (persisted.isNotEmpty) persisted.trimRight(),
      if (persisted.isNotEmpty && lines.isNotEmpty) '# --- not yet on disk ---',
      ...lines,
      if (logcat case final section? when section.trim().isNotEmpty) ...[
        '',
        '# --- logcat (this app, device) ---',
        section.trimRight(),
      ],
      if (!hasLogcat && Platform.isAndroid) ...[
        '',
        '# --- logcat unavailable (could not run `logcat -d`) ---',
      ],
      if (widgetLog case final section? when section.trim().isNotEmpty) ...[
        '',
        '# --- widget debug log (native) ---',
        section.trimRight(),
      ],
    ].join('\n');
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'niman-debug-log-$stamp.txt',
        bytes: Uint8List.fromList(utf8.encode(content)),
        mimeType: 'text/plain',
        dialogTitle: AppStrings.exportLogTitle,
      );
      if (uri == null) return; // The user canceled; nothing to report.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.exportLogDone(uri))));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.exportLogFailed(error))),
        );
      }
    }
  }

  static String _fileStamp(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}'
        '-${two(dt.day)}-${two(dt.hour)}${two(dt.minute)}${two(dt.second)}'
        '.${three(dt.millisecond)}';
  }

  /// The tail of the durable native widget decision log (Android).
  ///
  /// The Kotlin widget code appends every placement decision to a file
  /// in the app's external files dir: the logcat ring buffer keeps only
  /// tens of seconds, so the file is the record that survives until the
  /// export. Read over the widgets channel — the native side resolves
  /// the file, Dart never guesses the path. Null off Android or when
  /// the file does not exist yet.
  static Future<String?> _widgetDebugLog() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      return await const MethodChannel('niman/widgets')
          .invokeMethod<String>('widgetDebugLog');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// The device's own logcat for this app (Android), capped to its tail.
  ///
  /// Since Android 7 an app may read the logd entries of its own uid, so
  /// a child `logcat -d` answers with exactly this app's lines: the
  /// native Kotlin logs (widget provider, config activity), the plugins
  /// and the Flutter engine -- none of which reach the AppLog buffer.
  /// The dump runs off the UI isolate and is bounded
  /// by a timeout; the file keeps only the most recent 200 KB, because
  /// a report is about what happened last.
  ///
  /// Null off Android, when nothing was captured, or when the dump fails.
  static Future<String?> _logcatDump() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final stdout = await Isolate.run(() async {
        final process = await Process.start('logcat', [
          '-d',
          '-v',
          'threadtime',
        ]);
        // -d exits right after the dump; the timeout is the safety net
        // for a device where it hangs. Malformed bytes become
        // replacements: native log lines carry arbitrary text.
        return await process.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .join()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                process.kill(ProcessSignal.sigkill);
                return '';
              },
            );
      });
      final out = stdout.trimRight();
      if (out.isEmpty) {
        return null;
      }
      const maxBytes = 200 * 1024;
      if (out.length <= maxBytes) {
        return out;
      }
      final cut = out.lastIndexOf('\n', out.length - maxBytes);
      return cut <= 0
          ? out.substring(out.length - maxBytes)
          : out.substring(cut + 1);
    } on Object catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.settingsAreaDiagnostics,
      controller: widget.controller,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          HighlightRow(
            key: SettingsKeys.debugLogs,
            child: SwitchListTile(
              title: Text(AppStrings.debugLogsTitle),
              subtitle: Text(AppStrings.debugLogsSubtitle),
              value: _debugLogs ?? true,
              onChanged: _toggleDebugLogs,
            ),
          ),
          HighlightRow(
            key: SettingsKeys.exportLog,
            child: ListTile(
              leading: const Icon(Icons.save_alt),
              title: Text(AppStrings.exportLogTitle),
              subtitle: Text(AppStrings.exportLogSubtitle),
              onTap: _exportLog,
            ),
          ),
          // A fact about the installation, like the library path:
          // nothing to change, only to know (issue #80).
          if (_version != null)
            ListTile(
              key: const Key('app-version'),
              title: Text(AppStrings.versionTitle),
              trailing: Text(
                _version!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          HighlightRow(
            key: SettingsKeys.changelog,
            child: SettingsValueRow(
              title: AppStrings.changelogTitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ChangelogScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
