import 'dart:async';

import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/known_library_list.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The known-library list, reached from the settings, for switching from
/// the open library to another one (T-ML-06).
///
/// The same list the home screen shows, and the same long press forgets
/// an entry — except the open library, which cannot be forgotten out from
/// under itself. Picking one closes the current library and opens the
/// chosen one, landing on its tree.
final class SwitchLibraryScreen extends StatefulWidget {
  /// Creates the switch screen.
  const new({required this.controller, required this.onSwitched, super.key});

  /// The open session, which performs the switch.
  final LibrarySession controller;

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

  /// Switches to [path], unless it is the library already open.
  ///
  /// The caller is told first: this screen sits above the shell, and the
  /// shell is about to be torn down and rebuilt for the new library.
  Future<void> _switch(String path) async {
    if (path == widget.controller.root) {
      widget.onSwitched();
      return;
    }
    setState(() => _busy = true);
    widget.onSwitched();
    try {
      await widget.controller.switchTo(path);
    } finally {
      // Normally this screen is gone by now; it is still here if the
      // caller chose to stay, and then its rows have to work again.
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forget(String path) async {
    await widget.controller.forgetLibrary(path);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.controller.root;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.switchLibraryTitle)),
      // No progress indicator: this screen is popped the moment a switch
      // starts, and the shell behind it shows the opening library.
      body: ListView(
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
    );
  }
}
