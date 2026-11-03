import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/sync/conflict_texts.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_failure.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_status.dart';
import 'package:niman/src/sync/sync_test_result.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

export 'package:niman/src/sync/library_sync_service.dart';
export 'package:niman/src/sync/network_monitor.dart' show SyncNetwork;
export 'package:niman/src/sync/sync_scheduler.dart' show SyncPause;
export 'package:niman/src/sync/sync_status.dart';
export 'package:niman/src/sync/sync_test_outcome.dart';
export 'package:niman/src/sync/sync_test_result.dart';

/// A library's sync, as the UI drives it (mockups S1–S11): configure,
/// test, run, resolve. Listeners hear every status change.
abstract interface class SyncService implements Listenable {
  /// The current status.
  SyncStatus get status;

  /// Local paths a run or a resolution just changed (an open note among
  /// them has to be re-read).
  Stream<Set<String>> get localChanges;

  /// Reads the stored destination into [status].
  Future<void> load();

  /// Probes the folder at [url] with [username] and [password] (null uses
  /// the stored password). Stores nothing.
  ///
  /// [trustedFingerprint] is the certificate the user just confirmed for
  /// this address (#454), when there is one to use; null tests with the
  /// device's own certificate store alone. It is not read from the stored
  /// destination here: a test may be about an address that is not saved
  /// yet, and the caller decides what it has confirmed.
  Future<SyncTestResult> testConnection({
    required String url,
    required String username,
    String? password,
    String? trustedFingerprint,
  });

  /// Stores the destination: [password] null keeps the stored one, empty
  /// removes it; [capabilities] from the test just run. A different URL
  /// or user makes the next sync a first sync.
  ///
  /// [trustedFingerprint] non-null remembers the certificate the user
  /// confirmed while setting the destination up (#454); null leaves
  /// whatever is stored (a change of URL or user has already dropped it).
  Future<void> save({
    required String url,
    required String username,
    String? password,
    WebDavCapabilities? capabilities,
    String? trustedFingerprint,
  });

  /// Forgets the certificate trusted for this destination (#454): the next
  /// connection must have it confirmed again. The destination itself, its
  /// state and its password are untouched.
  Future<void> forgetCertificate();

  /// Forgets the destination, the sync state and the password; no file is
  /// touched on either side.
  Future<void> disconnect();

  /// Runs a sync now. [confirm] is asked before a first sync and a plan
  /// that looks like a mass deletion.
  Future<SyncReport> syncNow({SyncConfirm? confirm});

  /// The texts of a conflicted [path]: both sides and, when history still
  /// has it, the version they last agreed on. Throws [SyncFailure].
  Future<ConflictTexts> conflictTexts(String path);

  /// Keeps one whole side of a conflicted [path]; throws [SyncFailure].
  /// With [shown], a side that moved since fails as a `moved` one.
  Future<void> resolveConflict(
    String path, {
    required bool keepLocal,
    ConflictTexts? shown,
  });

  /// Resolves a conflicted [path] with the [text] the user merged from
  /// the versions [shown]; throws [SyncFailure], a `moved` one when a
  /// side changed since.
  Future<void> resolveMerged(
    String path,
    String text, {
    required ConflictTexts shown,
  });

  /// Whether the "Wi-Fi only" option means anything on this device.
  bool get offersWifiOnly;

  /// Changes the automatic trigger options of the destination.
  Future<void> setTriggers({
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
  });

  /// The app came back to the foreground.
  void appResumed();

  /// The app went to the background.
  void appBackgrounded();
}
