import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// [source]'s notifications, moved out of the build phase.
///
/// Some sources notify while widgets build — a note registering with the
/// unsaved tracker from its `initState`, say — and a listener elsewhere
/// in the tree may not be marked for rebuild then. This passes a
/// notification straight on outside a build, and after the frame inside
/// one.
final class DeferredListenable extends ChangeNotifier {
  /// Relays [source].
  new(this.source) {
    source.addListener(_relay);
  }

  /// What is listened to.
  final Listenable source;

  bool _scheduled = false;
  bool _disposed = false;

  void _relay() {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    source.removeListener(_relay);
    super.dispose();
  }
}
