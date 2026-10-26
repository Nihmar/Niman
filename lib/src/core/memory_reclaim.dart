/// The one place that knows every cache the app can empty on demand.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/reclaimable.dart';

/// A process-wide registry of the [Reclaimable] caches, emptied together.
///
/// Flutter empties its own image cache when the system asks for memory;
/// the caches the app keeps are its own to give back (#1195). Each of them
/// tracks itself once, where it is made, and a signal — memory pressure, or
/// the app going to the background, see `MemoryReclaimObserver` — reaches
/// them all through [reclaimAll].
///
/// The registry holds its owners **weakly**. A cache made per note, per
/// pane or per widget state comes and goes with its owner and often has no
/// `dispose` to unregister from; a strong reference here would keep every
/// one of them, and whatever it holds, alive for the process.
final class MemoryReclaim {
  const new _();

  /// The registry is never pruned below this many entries: a short list is
  /// not worth a pass.
  static const int _minimumPrune = 32;

  static final List<WeakReference<Reclaimable>> _owners =
      <WeakReference<Reclaimable>>[];

  // The length at which the next [track] sweeps the dead references out:
  // doubling it after each sweep makes the sweep amortized O(1) a call,
  // and keeps a long session that makes a cache per note from growing the
  // list without bound between two signals.
  static int _pruneAt = _minimumPrune;

  /// Registers [owner] to be emptied by [reclaimAll], for as long as it
  /// lives. It needs no unregistering.
  static void track(Reclaimable owner) {
    if (_owners.length >= _pruneAt) {
      _prune();
      _pruneAt = math.max(_minimumPrune, _owners.length * 2);
    }
    _owners.add(WeakReference<Reclaimable>(owner));
  }

  /// Asks every live owner to [Reclaimable.reclaim], and returns how many
  /// it asked. Owners already collected are dropped from the registry.
  ///
  /// An owner that throws does not stop the others: giving memory back is
  /// best effort, and one broken cache must not keep the rest.
  static int reclaimAll() {
    _prune();
    _pruneAt = math.max(_minimumPrune, _owners.length * 2);
    var asked = 0;
    // A copy: an owner that makes (and so tracks) another cache while it
    // lets go must not change the list under the loop.
    for (final reference in List<WeakReference<Reclaimable>>.of(_owners)) {
      final owner = reference.target;
      if (owner == null) continue;
      asked++;
      try {
        owner.reclaim();
      } on Object catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'memory reclaim',
            context: ErrorDescription('while an owner gave its memory back'),
          ),
        );
      }
    }
    return asked;
  }

  static void _prune() => _owners.removeWhere((ref) => ref.target == null);

  /// How many owners are alive and tracked, after dropping the dead ones.
  @visibleForTesting
  static int get tracked {
    _prune();
    return _owners.length;
  }
}
