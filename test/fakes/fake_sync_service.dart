import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/conflict_texts.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_service.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

/// A scriptable [SyncService] for widget tests: every call is recorded,
/// and the answers come from the fields below.
final class FakeSyncService extends ChangeNotifier implements SyncService {
  SyncStatus _status = const SyncStatus();

  @override
  SyncStatus get status => _status;

  /// Replaces the status and notifies.
  set status(SyncStatus value) {
    _status = value;
    notifyListeners();
  }

  final StreamController<Set<String>> _changes =
      StreamController<Set<String>>.broadcast();

  @override
  Stream<Set<String>> get localChanges => _changes.stream;

  /// Emits [paths] on [localChanges].
  void emitChanges(Set<String> paths) => _changes.add(paths);

  /// What [testConnection] answers.
  SyncTestResult testResult = SyncTestResult(
    outcome: SyncTestOutcome.ok,
    capabilities: WebDavCapabilities(probedAt: DateTime(2026, 9, 15)),
    elapsedMs: 412,
  );

  /// The plan [syncNow] passes to `confirm`, when set.
  SyncPlan? planToConfirm;

  /// Whether [syncNow] asks with `firstSync` true.
  bool firstSync = true;

  /// What [syncNow] returns (after `confirm`, when a plan is set).
  SyncReport Function() report = SyncReport.new;

  /// What the last `confirm` answered.
  bool? confirmed;

  /// The texts [conflictTexts] answers.
  ConflictTexts texts = conflictTextsOf(local: 'mine', remote: 'theirs');

  /// What the next resolutions throw, one each, before any succeeds.
  final List<SyncFailure> resolveFailures = [];

  /// The versions the last resolution said it was decided on.
  ConflictTexts? resolvedShown;

  /// The text of the last [resolveMerged].
  String? mergedText;

  /// Calls, in order: `test <url>`, `save <url>`, `sync`, `disconnect`,
  /// `resolve <path> local|remote`, `texts <path>`.
  final List<String> calls = [];

  /// The password of the last [save] (null = kept).
  String? savedPassword;

  @override
  Future<void> load() async {}

  @override
  Future<SyncTestResult> testConnection({
    required String url,
    required String username,
    String? password,
  }) async {
    calls.add('test $url');
    return testResult;
  }

  @override
  Future<void> save({
    required String url,
    required String username,
    String? password,
    WebDavCapabilities? capabilities,
  }) async {
    calls.add('save $url');
    savedPassword = password;
    status = SyncStatus(
      destination: destination(url: url, username: username),
      capabilities: capabilities,
    );
  }

  @override
  Future<void> disconnect() async {
    calls.add('disconnect');
    status = const SyncStatus();
  }

  @override
  Future<SyncReport> syncNow({SyncConfirm? confirm}) async {
    calls.add('sync');
    final plan = planToConfirm;
    if (plan != null && confirm != null) {
      confirmed = await confirm(plan, firstSync: firstSync);
    }
    final result = report();
    status = SyncStatus(
      destination: _status.destination,
      capabilities: _status.capabilities,
      lastReport: result,
    );
    return result;
  }

  @override
  Future<ConflictTexts> conflictTexts(String path) async {
    calls.add('texts $path');
    return texts;
  }

  @override
  Future<void> resolveMerged(
    String path,
    String text, {
    required ConflictTexts shown,
  }) async {
    calls.add('merge $path');
    resolvedShown = shown;
    if (resolveFailures.isNotEmpty) throw resolveFailures.removeAt(0);
    mergedText = text;
    _status.lastReport?.conflicts.removeWhere((c) => c.path == path);
    notifyListeners();
  }

  @override
  Future<void> resolveConflict(
    String path, {
    required bool keepLocal,
    ConflictTexts? shown,
  }) async {
    calls.add('resolve $path ${keepLocal ? 'local' : 'remote'}');
    resolvedShown = shown;
    if (resolveFailures.isNotEmpty) throw resolveFailures.removeAt(0);
    _status.lastReport?.conflicts.removeWhere((c) => c.path == path);
    notifyListeners();
  }

  /// What [offersWifiOnly] answers.
  bool phone = true;

  @override
  bool get offersWifiOnly => phone;

  @override
  Future<void> setTriggers({
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
  }) async {
    final parts = [
      if (autoSync != null) 'auto $autoSync',
      if (intervalSeconds != null) 'every $intervalSeconds',
      if (wifiOnly != null) 'wifi $wifiOnly',
    ];
    calls.add('triggers ${parts.join(' ')}');
    final row = _status.destination;
    if (row == null) return;
    status = _status.copyWith(
      destination: row.copyWith(
        autoSync: autoSync,
        intervalSeconds: intervalSeconds,
        wifiOnly: wifiOnly,
      ),
    );
  }

  @override
  void appResumed() => calls.add('resumed');

  @override
  void appBackgrounded() => calls.add('backgrounded');

  /// A destination row for tests.
  static SyncDestination destination({
    String url = 'http://10.8.0.1:8080/webdav/Niman/',
    String username = 'ale',
    int? lastSyncAtMs,
    String? lastError,
    bool autoSync = true,
    int intervalSeconds = 60,
    bool wifiOnly = false,
  }) => SyncDestination(
    libraryPath: '/lib',
    url: url,
    username: username,
    enabled: true,
    autoSync: autoSync,
    intervalSeconds: intervalSeconds,
    wifiOnly: wifiOnly,
    capabilities: '{}',
    lastSyncAtMs: lastSyncAtMs,
    lastError: lastError,
  );
}

/// Conflict texts for a test, with placeholder hashes: the fake never
/// checks them.
ConflictTexts conflictTextsOf({
  required String local,
  required String remote,
  String? base,
}) => ConflictTexts(
  local: local,
  remote: remote,
  base: base,
  localSha256: 'local-sha',
  remoteSha256: 'remote-sha',
);
