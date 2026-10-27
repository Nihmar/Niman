import 'package:flutter/widgets.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/memory_reclaim.dart';
import 'package:niman/src/core/reclaimable.dart' show Reclaimable;
import 'package:niman/src/core/resume_observer.dart' show ResumeObserver;

/// Empties every [Reclaimable] cache when the system asks for memory and
/// when the app goes to the background (#1195).
///
/// On a phone the second decides whether a backgrounded app is kept or
/// killed: Android picks by what the process weighs. Only `paused` counts:
/// `inactive` and `hidden` also come with a dialog, a split-screen peer or
/// a window covered for a moment, where the user is still looking at the
/// app and the next frame would pay to rebuild what was let go.
///
/// A plain observer for the reason [ResumeObserver] is: the lifecycle
/// listener asserts on the order of states, which the shortcuts platforms
/// and tests take.
final class MemoryReclaimObserver with WidgetsBindingObserver {
  /// An observer, not yet attached; see [install].
  new();

  static const AppLogger _logger = AppLogger(name: 'memory');

  static MemoryReclaimObserver? _installed;

  /// Attaches one observer for the life of the process, if none is.
  ///
  /// Not tied to a widget: what it empties is the process's, so it
  /// outlives the app widget (which a test builds many times and the app
  /// once) and is never removed.
  static void install() {
    if (_installed != null) return;
    final observer = MemoryReclaimObserver();
    WidgetsBinding.instance.addObserver(observer);
    _installed = observer;
  }

  @override
  void didHaveMemoryPressure() => _reclaim('memory pressure');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _reclaim('paused');
  }

  void _reclaim(String why) {
    final before = memoryNow();
    final owners = MemoryReclaim.reclaimAll();
    // The heap is only collected later: the second reading says what the
    // process weighed right after, not what it will once the collector ran.
    _logger.debug(
      'reclaim on $why: $owners owner(s), before: $before, '
      'after: ${memoryNow()}',
    );
  }
}
