import 'dart:async';

import 'package:meta/meta.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/network_monitor.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_store.dart';

/// Why the automatic triggers stopped until the user acts.
enum SyncPause {
  /// The server refused the credentials, or no password is stored.
  authentication,

  /// A plan looked like a mass deletion; only the user can confirm it.
  confirmation,

  /// The remote folder is gone or not usable.
  server,
}

/// The trigger options of a destination, as the scheduler needs them.
@immutable
final class SyncTriggers {
  /// Options for a configured destination.
  const new({
    this.enabled = true,
    this.autoSync = true,
    this.intervalSeconds = 60,
    this.wifiOnly = false,
    this.everSynced = true,
  });

  /// Off stops every trigger.
  final bool enabled;

  /// The automatic triggers (after edits, open/resume, periodic, network).
  final bool autoSync;

  /// The periodic full sync; 0 turns it off.
  final int intervalSeconds;

  /// Automatic runs skip mobile data (honored on phones only).
  final bool wifiOnly;

  /// Whether a first sync already happened: until then only the user
  /// starts one, with its summary.
  final bool everSynced;
}

/// Starts the automatic syncs of one library (docs/dev/sync.md, "Queue
/// and triggers"):
///
/// - a quick sync 5 s after the last hint, 60 s at most while they keep
///   coming, and right away when the app goes to the background;
/// - a full sync when the library opens, when the app comes back, every
///   `intervalSeconds` while it is open, and after a quick sync that left
///   something for one;
/// - after the network comes back, the queue's backoff is lifted and the
///   interrupted run goes again.
///
/// Automatic runs wait out an exponential backoff after a run that could
/// not reach the server (and the server's `Retry-After`), and stop until
/// the user acts after a refused password, a missing folder or a mass
/// deletion. A manual run clears both. Only one run at a time: a trigger
/// during a run is remembered and served after it.
///
/// Every decision is logged under `sync`.
final class SyncScheduler {
  /// A scheduler; [run] carries out an automatic sync and never throws,
  /// [triggers] reads the destination's options (null without one).
  new({
    required this.run,
    required this.triggers,
    required this.hasDueHints,
    required this.retryNow,
    this.network,
    this.phone = false,
    this.onChanged,
    DateTime Function()? now,
    this.quickDelay = const Duration(seconds: 5),
    this.quickMaxDelay = const Duration(seconds: 60),
  }) : _now = now ?? DateTime.now;

  /// Runs an automatic sync.
  final Future<SyncReport> Function({required bool quick}) run;

  /// The destination's trigger options, or null without a destination.
  final Future<SyncTriggers?> Function() triggers;

  /// Whether some queued hint is due.
  final Future<bool> Function() hasDueHints;

  /// Lifts the queue's backoff.
  final Future<void> Function() retryNow;

  /// The device's network; null counts as always [SyncNetwork.unknown].
  final NetworkMonitor? network;

  /// Whether this is a phone: Wi-Fi only and "offline" are honored, and
  /// the periodic sync stops while the app is in the background.
  final bool phone;

  /// Hears every change of the state the UI shows.
  final void Function()? onChanged;

  /// The wait after the last hint.
  final Duration quickDelay;

  /// The longest a hint waits while more keep coming.
  final Duration quickMaxDelay;

  final DateTime Function() _now;

  static const _log = AppLogger(name: 'sync');

  SyncPause? _paused;
  DateTime? _backoffUntil;
  int _failures = 0;
  SyncNetwork _network = SyncNetwork.unknown;
  bool _lastAborted = false;

  Timer? _debounce;
  DateTime? _firstHintAt;
  Timer? _periodic;
  int _periodicSeconds = 0;
  Timer? _retry;
  StreamSubscription<SyncNetwork>? _networkChanges;

  bool _running = false;
  bool _wantFull = false;
  bool _wantQuick = false;
  bool _foreground = true;
  bool _started = false;
  bool _disposed = false;

  /// Why the automatic triggers stopped, or null.
  SyncPause? get paused => _paused;

  /// When automatic runs may try again after a failure, or null.
  DateTime? get backoffUntil => _backoffUntil;

  /// The network last seen.
  SyncNetwork get networkState => _network;

  /// Whether [triggers] would let an automatic run go on this network.
  bool networkAllows(SyncTriggers triggers) {
    if (!phone) return true;
    if (_network == SyncNetwork.offline) return false;
    return !(triggers.wifiOnly && _network == SyncNetwork.mobile);
  }

  /// Reads the network, listens to it and makes the "library opened"
  /// full sync.
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    final monitor = network;
    if (monitor != null) {
      _network = await monitor.current();
      _networkChanges = monitor.changes.listen(_onNetwork);
    }
    _log.info('scheduler: start (network ${_network.name}, phone $phone)');
    await _armPeriodic();
    _request(quick: false, why: 'library opened');
  }

  /// A hint was queued.
  void hinted() {
    if (_disposed) return;
    final now = _now();
    final first = _firstHintAt ??= now;
    final waited = now.difference(first);
    final left = quickMaxDelay - waited;
    final delay = left <= Duration.zero
        ? Duration.zero
        : (left < quickDelay ? left : quickDelay);
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      _debounce = null;
      _firstHintAt = null;
      _request(quick: true, why: 'after edits');
    });
  }

  /// The app came back to the foreground.
  void resumed() {
    if (_disposed || !_started) return;
    _foreground = true;
    _log.info('scheduler: app resumed');
    unawaited(_armPeriodic());
    _request(quick: false, why: 'app resumed');
  }

  /// The app went to the background: the queue goes now (the process may
  /// not come back), and on a phone the periodic sync stops.
  void backgrounded() {
    if (_disposed || !_started) return;
    _foreground = false;
    _log.info('scheduler: app in the background');
    if (phone) {
      _periodic?.cancel();
      _periodic = null;
      _periodicSeconds = 0;
    }
    if (_debounce != null) {
      _debounce!.cancel();
      _debounce = null;
      _firstHintAt = null;
    }
    _request(quick: true, why: 'app backgrounded');
  }

  /// The destination's options changed (or it went away).
  Future<void> settingsChanged() async {
    if (_disposed || !_started) return;
    await _armPeriodic();
    onChanged?.call();
  }

  /// The user changed the credentials or the address: the pause is over.
  void clearPause() {
    if (_paused == null) return;
    _log.info(
      'scheduler: pause (${_paused!.name}) cleared by a settings change',
    );
    _paused = null;
    onChanged?.call();
  }

  /// A manual run is about to start: it clears the pause and the backoff.
  Future<void> manualRunStarting() async {
    _paused = null;
    _failures = 0;
    _backoffUntil = null;
    _retry?.cancel();
    _retry = null;
    await retryNow();
    onChanged?.call();
  }

  /// A run finished — manual or automatic: pauses, backs off, or asks for
  /// the next run.
  void runFinished(SyncReport report) {
    if (_disposed) return;
    final why = report.aborted;
    _lastAborted = why != null;
    switch (why) {
      case SyncAbort.authentication || SyncAbort.missingPassword:
        _pause(SyncPause.authentication);
      case SyncAbort.remoteMissing || SyncAbort.unsupported:
        _pause(SyncPause.server);
      case SyncAbort.notConfirmed:
        if (report.plan?.looksLikeMassDeletion ?? false) {
          _pause(SyncPause.confirmation);
        }
      case SyncAbort.offline || SyncAbort.failed:
        _failures++;
        var wait = syncBackoff(_failures);
        final asked = report.retryAfter;
        if (asked != null && asked > wait) wait = asked;
        _backoffUntil = _now().add(wait);
        _log.info(
          'scheduler: ${why!.name}, automatic runs wait ${wait.inSeconds}s '
          '(failure $_failures)',
        );
        _armRetry(wait, quick: report.quick);
      case SyncAbort.notConfigured:
        break;
      case null:
        _failures = 0;
        _backoffUntil = null;
        if (report.deferred.isNotEmpty) {
          _wantFull = true;
          _log.info(
            'scheduler: the quick sync left ${report.deferred.length} for a '
            'full sync',
          );
        }
        if (report.hintsFailed > 0) {
          final wait = report.retryAfter ?? syncBackoff(1);
          _armRetry(wait, quick: true);
        }
    }
    onChanged?.call();
  }

  void _pause(SyncPause why) {
    _paused = why;
    _retry?.cancel();
    _retry = null;
    _log.warning('scheduler: automatic sync paused (${why.name})');
  }

  void _armRetry(Duration wait, {required bool quick}) {
    _retry?.cancel();
    _retry = Timer(wait, () {
      _retry = null;
      _request(quick: quick, why: 'retry after ${wait.inSeconds}s');
    });
  }

  Future<void> _armPeriodic() async {
    final options = await triggers();
    if (_disposed) return;
    final seconds =
        options == null ||
            !options.enabled ||
            !options.autoSync ||
            (phone && !_foreground)
        ? 0
        : options.intervalSeconds;
    if (seconds == _periodicSeconds && (_periodic != null || seconds == 0)) {
      return;
    }
    _periodic?.cancel();
    _periodic = null;
    _periodicSeconds = seconds;
    if (seconds <= 0) {
      _log.debug('scheduler: no periodic sync');
      return;
    }
    _log.info('scheduler: periodic full sync every ${seconds}s');
    _periodic = Timer.periodic(
      Duration(seconds: seconds),
      (_) => _request(quick: false, why: 'periodic'),
    );
  }

  void _onNetwork(SyncNetwork next) {
    final was = _network;
    if (next == was) return;
    _network = next;
    _log.info('scheduler: network ${was.name} -> ${next.name}');
    onChanged?.call();
    final cameBack =
        (was == SyncNetwork.offline && next != SyncNetwork.offline) ||
        (was == SyncNetwork.mobile && next == SyncNetwork.unmetered);
    if (!cameBack || _disposed) return;
    _failures = 0;
    _backoffUntil = null;
    _retry?.cancel();
    _retry = null;
    unawaited(
      retryNow().then((_) {
        _request(quick: !_lastAborted, why: 'network back (${next.name})');
      }),
    );
  }

  /// Asks for a run; it happens when the options, the pause, the backoff
  /// and the network allow it.
  void _request({required bool quick, required String why}) {
    if (_disposed) return;
    if (_running) {
      if (quick) {
        _wantQuick = true;
      } else {
        _wantFull = true;
      }
      _log.debug(
        'scheduler: ${quick ? 'quick' : 'full'} ($why) after the running one',
      );
      return;
    }
    _running = true;
    unawaited(_serve(quick: quick, why: why));
  }

  Future<void> _serve({required bool quick, required String why}) async {
    var ran = false;
    try {
      final skip = await _skipReason(quick: quick);
      if (skip != null) {
        _log.debug(
          'scheduler: ${quick ? 'quick' : 'full'} ($why) skipped: $skip',
        );
        return;
      }
      _log.info('scheduler: ${quick ? 'quick' : 'full'} sync ($why)');
      if (quick) {
        _debounce?.cancel();
        _debounce = null;
        _firstHintAt = null;
      }
      ran = true;
      final report = await run(quick: quick);
      runFinished(report);
    } on Object catch (e) {
      _log.error('scheduler: ${quick ? 'quick' : 'full'} ($why) failed: $e');
    } finally {
      _running = false;
    }
    if (_disposed) return;
    if (_wantFull) {
      _wantFull = false;
      _wantQuick = false;
      _request(quick: false, why: 'asked for during a run');
    } else if (_wantQuick) {
      _wantQuick = false;
      _request(quick: true, why: 'asked for during a run');
    } else if (ran && _debounce == null && await hasDueHints()) {
      // Hints queued while the run went: their own debounce may have
      // fired into it and been joined.
      hinted();
    }
  }

  Future<String?> _skipReason({required bool quick}) async {
    final options = await triggers();
    if (options == null) return 'no destination';
    if (!options.enabled) return 'sync disabled';
    if (!options.autoSync) return 'automatic sync off';
    if (!options.everSynced) return 'no first sync yet';
    if (_paused != null) return 'paused (${_paused!.name})';
    final until = _backoffUntil;
    if (until != null && _now().isBefore(until)) {
      return 'backing off until $until';
    }
    if (!networkAllows(options)) return 'network ${_network.name}';
    if (quick && !await hasDueHints()) return 'nothing queued is due';
    return null;
  }

  /// Stops every timer and the network subscription.
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _periodic?.cancel();
    _retry?.cancel();
    unawaited(_networkChanges?.cancel());
  }
}
