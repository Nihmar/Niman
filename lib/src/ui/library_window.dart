/// The library switcher on a wide window (#203): a floating window from
/// the rail's foot, over the note, like Settings (#202).
///
/// It is the one place for everything that leaves the open library: the
/// known libraries to switch to, a folder to open from disk, a new one
/// to create, and Close library, back to the opening screen. Settings
/// drops its own switch and close rows on a wide window for it; the
/// phone, with no rail, keeps them there.
///
/// Leaving saves the open notes first, as the window's close guard does:
/// the shell and its editors go with the library. The window closes
/// before the library goes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/floating_window.dart';
import 'package:niman/src/ui/known_library_list.dart';
import 'package:niman/src/ui/library_picker.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

/// The library window's route; the caller pushes it, and removes it if
/// the library closes under it.
Route<void> libraryWindowRoute(
  BuildContext context, {
  required LibrarySession controller,
  required UnsavedTracker unsaved,
}) {
  return floatingWindowRoute(
    context,
    title: AppStrings.switchLibraryTitle,
    panelKey: const Key('library-window'),
    size: LibraryWindow.size,
    builder: (context) =>
        LibraryWindow(controller: controller, unsaved: unsaved),
  );
}

/// The window's page: the known libraries, and the ways out.
final class LibraryWindow extends StatefulWidget {
  /// The page over [controller]'s open library.
  const new({required this.controller, required this.unsaved, super.key});

  /// The open session, which switches, opens and closes.
  final LibrarySession controller;

  /// The open notes, saved before the library goes.
  final UnsavedTracker unsaved;

  /// A list of a handful of rows and one line of actions.
  static const Size size = Size(600, 560);

  @override
  State<LibraryWindow> createState() => _LibraryWindowState();
}

final class _LibraryWindowState extends State<LibraryWindow> {
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
  Future<void> _leave(Future<void> Function(LibrarySession) leave) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.unsaved.saveAll();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$error';
        });
      }
      return;
    }
    if (!mounted) return;
    // The window goes first: a switch can keep the same shell under a
    // new library, which would leave it up over the new one.
    final session = widget.controller;
    Navigator.of(context, rootNavigator: true).pop();
    await leave(session);
  }

  void _switch(String path) {
    if (path == widget.controller.root) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    unawaited(_leave((session) => session.switchTo(path)));
  }

  Future<void> _openFromDisk() async {
    final path = await _pick(AppStrings.openLibraryChooseFolder);
    if (path == null) return;
    _switch(path);
  }

  Future<void> _create() async {
    final parent = await _pick(AppStrings.openLibraryChooseParent);
    if (parent == null || !mounted) return;
    final name = await showNewLibraryDialog(context);
    if (name == null || name.isEmpty) return;
    await _leave((session) async {
      await session.close();
      await session.open(p.join(parent, name), create: true);
    });
  }

  Future<String?> _pick(String title) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final pick = await pickLibraryFolder(title);
    if (!mounted) return null;
    setState(() {
      _busy = false;
      _error = switch (pick) {
        LibraryPickNeedsAccess() => AppStrings.storageAccessNeeded,
        LibraryPickFailed(:final message) => message,
        LibraryPicked() || LibraryPickCancelled() => null,
      };
    });
    return pick is LibraryPicked ? pick.path : null;
  }

  Future<void> _forget(String path) async {
    // The library on screen leaves through the same path as a switch:
    // open notes are saved first, the window closes, and only then does
    // the entry go (#286).
    if (path == widget.controller.root) {
      await _leave((session) => session.forgetLibrary(path));
      return;
    }
    await widget.controller.forgetLibrary(path);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    return Column(
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
                currentPath: widget.controller.root,
                onOpen: _switch,
                onForget: (path) => unawaited(_forget(path)),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              error,
              key: const Key('library-window-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                key: const Key('library-window-close-library'),
                onPressed: _busy
                    ? null
                    : () => unawaited(_leave((session) => session.close())),
                icon: const Icon(Icons.link_off_outlined),
                label: Text(AppStrings.closeLibraryTitle),
              ),
              TextButton.icon(
                key: const Key('library-window-open'),
                onPressed: _busy ? null : () => unawaited(_openFromDisk()),
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(AppStrings.openLibraryExisting),
              ),
              FilledButton.tonalIcon(
                key: const Key('library-window-create'),
                onPressed: _busy ? null : () => unawaited(_create()),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(AppStrings.openLibraryCreate),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
