import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The open library's [Workspace], changed in one place and kept (issue
/// #23).
///
/// Every change goes through [update], which publishes it and schedules a
/// save: a burst of them — a folder renamed with ten notes open under it,
/// tabs flicked through — is written once, a moment after the last. The
/// shell disposes the controller with the library; [flush] writes what
/// is pending before that.
final class WorkspaceController extends ChangeNotifier {
  /// A controller writing through [save], [debounce] after a change.
  new({
    required this.save,
    Workspace initial = Workspace.empty,
    this.debounce = const Duration(milliseconds: 500),
  }) : _value = initial;

  /// Keeps a workspace; the session's store in the app.
  final Future<void> Function(Workspace workspace) save;

  /// How long a change waits for the next one before it is written.
  final Duration debounce;

  Workspace _value;
  Timer? _pending;

  static const _log = AppLogger(name: 'workspace');

  /// What is open now.
  Workspace get value => _value;

  /// Whether anything has changed it since it was made.
  bool get touched => _touched;
  bool _touched = false;

  /// Takes [saved] — what was read back — as the workspace, unless the
  /// user got there first: a note opened while the store was still being
  /// read is what they asked for, and it is not overwritten by what they
  /// had before.
  void adopt(Workspace saved) {
    if (_touched || saved == _value) return;
    _value = saved;
    notifyListeners();
  }

  /// Applies [change]; a change that changes nothing is not one.
  void update(Workspace Function(Workspace workspace) change) {
    final next = change(_value);
    if (next == _value) return;
    _touched = true;
    _value = next;
    notifyListeners();
    _pending?.cancel();
    _pending = Timer(debounce, () => unawaited(flush()));
  }

  /// Writes a pending change now.
  Future<void> flush() async {
    if (_pending == null) return;
    _pending?.cancel();
    _pending = null;
    try {
      await save(_value);
    } on Object catch (error) {
      // The workspace is a convenience: a failed write loses where the
      // notes were left, never a note.
      _log.warning('workspace not saved: $error');
    }
  }

  @override
  void dispose() {
    unawaited(flush());
    super.dispose();
  }
}
