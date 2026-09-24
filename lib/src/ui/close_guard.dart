import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/close_to_tray.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

/// Guards the window's close requests (T-PP-11), and hides the window to
/// the tray instead of closing it where that is asked for (#209).
///
/// While a tracked note holds edits the disk does not have, the platform
/// is told to prevent the close; a close request then asks before the
/// window goes away (Save and close / Cancel). Where the platform has no
/// close surface to guard (Android's [NoopWindowController]), everything
/// here is inert.
///
/// With close-to-tray on, the prevent flag stays on whatever the notes
/// say, and a close request hides the window: nothing is saved or asked,
/// because nothing is ending. The tray's Quit asks for the real close,
/// and then the unsaved ask happens as it always did.
final class CloseGuard extends StatefulWidget {
  /// Creates the guard over [child].
  const new({
    required this.tracker,
    required this.window,
    required this.child,
    super.key,
  });

  /// The app-level unsaved registry to watch.
  final UnsavedTracker tracker;

  /// The platform window to arm and close.
  final WindowController window;

  /// The subtree the guard wraps.
  final Widget child;

  @override
  State<CloseGuard> createState() => _CloseGuardState();
}

final class _CloseGuardState extends State<CloseGuard> {
  static const AppLogger _log = AppLogger(name: 'close-guard');

  /// The prevent flag currently pushed to the platform (so the channel
  /// call happens only on a change, not on every keystroke).
  bool _preventOn = false;

  /// The platform refused to connect (a widget-test binding without the
  /// plugin, a host where it failed): the guard keeps tracking, but never
  /// touches the channel again instead of throwing on every change.
  bool _platformOff = false;

  /// The ask dialog is on screen: duplicate close requests are dropped.
  bool _asking = false;

  /// Set by the tray's Quit: this close is a real one (#209).
  bool _quitting = false;

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void initState() {
    super.initState();
    widget.tracker.addListener(_syncPrevent);
    CloseToTray.enabled.addListener(_syncPrevent);
    CloseToTray.trayShown.addListener(_syncPrevent);
    CloseToTray.quitRequests.addListener(_onQuitRequested);
    widget.window.onCloseRequested = _onCloseRequested;
    unawaited(_init());
  }

  /// Connects the platform side. A host without the plugin degrades to
  /// tracking only — the close veto is off, but the app still runs.
  Future<void> _init() async {
    try {
      await widget.window.init();
    } on Object catch (error) {
      _platformOff = true;
      _log.warning('window init failed, close veto off ($error)');
    }
    _syncPrevent();
  }

  @override
  void dispose() {
    widget.window.onCloseRequested = null;
    CloseToTray.enabled.removeListener(_syncPrevent);
    CloseToTray.trayShown.removeListener(_syncPrevent);
    CloseToTray.quitRequests.removeListener(_onQuitRequested);
    widget.tracker.removeListener(_syncPrevent);
    super.dispose();
  }

  /// Keeps the platform's prevent flag in step with the dirty state.
  ///
  /// With prevent on, the OS refuses the close and reports it through
  /// [_onCloseRequested] instead of closing the window.
  void _syncPrevent() {
    // Close-to-tray needs the flag on at all times: without it the OS
    // closes the window instead of reporting the request to hide it.
    final prevent = widget.tracker.hasUnsaved || CloseToTray.active;
    if (prevent == _preventOn) return;
    _preventOn = prevent;
    if (_platformOff) return;
    unawaited(_setPrevent(prevent));
  }

  Future<void> _setPrevent(bool prevent) async {
    try {
      await widget.window.setPreventClose(prevent: prevent);
    } on Object catch (error) {
      _log.warning('setPreventClose($prevent) failed ($error)');
    }
  }

  /// A close request the platform refused (prevent was on) — or the one
  /// it let through while the state was clean.
  void _onCloseRequested() {
    if (_asking) return;
    // Nothing is ending: the window goes to the tray and the notes stay
    // as they are, saved on their own timer as always (#209).
    if (CloseToTray.active && !_quitting) {
      _log.info('close request: hiding to the tray');
      unawaited(widget.window.hide());
      return;
    }
    if (!widget.tracker.hasUnsaved) {
      // No edits to protect: let the close land.
      unawaited(_finishClose());
      return;
    }
    _asking = true;
    unawaited(_showAsk());
  }

  /// The tray's Quit (#209): the same close the × does with close-to-tray
  /// off, including the ask about unsaved notes.
  void _onQuitRequested() {
    _quitting = true;
    _onCloseRequested();
  }

  /// Turns the prevent flag off and closes the window for real.
  Future<void> _finishClose() async {
    try {
      await widget.window.setPreventClose(prevent: false);
      await widget.window.close();
    } on Object catch (error) {
      _log.warning('window close failed ($error)');
    }
  }

  /// The "unsaved edits" ask. On Save and close, the notes are written
  /// to disk first; a write that fails keeps the window open (the edits
  /// are still only in the buffers).
  Future<void> _showAsk() async {
    final names = widget.tracker.unsavedPaths.map(p.basename).toList();
    final saveAndClose = await _askDialog(names);
    _asking = false;
    // Null (dismissed by tapping outside) keeps the window open too — and
    // a quit the user backed out of is no longer under way.
    if (saveAndClose != true) {
      _quitting = false;
      return;
    }
    try {
      await widget.tracker.saveAll();
    } on Object catch (error) {
      _log.warning('save before close failed: $error');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(AppStrings.closeSaveFailed)));
      }
      return;
    }
    await _finishClose();
  }

  Future<bool?> _askDialog(List<String> names) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.closeUnsavedTitle),
        content: Text(AppStrings.closeUnsavedBody(names)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.saveAndClose),
          ),
        ],
      ),
    );
  }
}
