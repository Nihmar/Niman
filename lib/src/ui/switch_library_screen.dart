import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/known_library_list.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// The known-library list, reached from the settings, for switching from
/// the open library to another one (T-ML-06).
///
/// The same list the home screen shows, and the same long press forgets
/// an entry — except the open library, which cannot be forgotten out from
/// under itself. Picking one saves the open notes, then closes the current
/// library and opens the chosen one, landing on its tree.
///
/// Leaving saves the open notes first and awaits them, as the library
/// window's does (#203, #351): the shell and its editors go with the
/// library, so a switch must not ride on their disposal. A note that will
/// not save keeps the library open and says why.
final class SwitchLibraryScreen extends StatefulWidget {
  /// Creates the switch screen.
  const new({
    required this.controller,
    required this.unsaved,
    required this.onSwitched,
    super.key,
  });

  /// The open session, which performs the switch.
  final LibrarySession controller;

  /// The open notes, saved before the library goes; null only where no
  /// tracker is wired (a settings body built without one, as tests do).
  final UnsavedTracker? unsaved;

  /// Called once the switch is under way, so the caller can leave this
  /// screen (and any settings screen above the shell) behind.
  final VoidCallback onSwitched;

  @override
  State<SwitchLibraryScreen> createState() => _SwitchLibraryScreenState();
}

final class _SwitchLibraryScreenState extends State<SwitchLibraryScreen> {
  List<KnownLibrary> _known = const [];
  Set<String> _unreachable = const {};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final loaded = await loadKnownLibraries(widget.controller);
    if (!mounted) return;
    setState(() {
      _known = loaded.entries;
      _unreachable = loaded.missing;
    });
  }

  /// Saves the open notes, then runs [leave]; a note that will not save
  /// keeps the library open and says why.
  ///
  /// The library window's `_leave`, on the phone (#351): the open notes are
  /// awaited before anything leaves, so no buffer is dropped, and a failed
  /// write cancels the move instead of losing the text.
  Future<void> _leave(Future<void> Function(LibrarySession) leave) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final failed = await saveBeforeLeaving(widget.unsaved);
    if (failed != null) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$failed';
        });
      }
      return;
    }
    if (!mounted) return;
    // The caller is told first: this screen sits above the shell, and the
    // shell is about to be torn down and rebuilt for the new library.
    final session = widget.controller;
    widget.onSwitched();
    try {
      await leave(session);
    } finally {
      // Normally this screen is gone by now; it is still here if the
      // caller chose to stay, and then its rows have to work again.
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Switches to [path], unless it is the library already open.
  ///
  /// The open notes are saved and awaited before the switch (#351), as the
  /// library window does: the shell and its editors go with the library.
  Future<void> _switch(String path) async {
    if (path == widget.controller.root) {
      widget.onSwitched();
      return;
    }
    await _leave((session) => session.switchTo(path));
  }

  Future<void> _forget(String path) async {
    // Forgetting the library on screen closes it, like a switch: this
    // screen has no library left to list (#286), and the open notes are
    // saved before it goes.
    if (path == widget.controller.root) {
      await _leave((session) => session.forgetLibrary(path));
      // Normally this screen is gone by now; it is still here if the
      // caller chose to stay, and then its list has to catch up.
      if (mounted) await _load();
      return;
    }
    await widget.controller.forgetLibrary(path);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    final open = widget.controller.root;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.switchLibraryTitle)),
      // No progress indicator: this screen is popped the moment a switch
      // starts, and the shell behind it shows the opening library.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              children: [
                KnownLibraryList(
                  entries: _known,
                  unreachable: _unreachable,
                  enabled: !_busy,
                  currentPath: open,
                  onOpen: (path) => unawaited(_switch(path)),
                  onForget: (path) => unawaited(_forget(path)),
                ),
              ],
            ),
          ),
          // Why the library is still open: the note that would not save.
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                error,
                key: const Key('switch-library-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
