import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/library_root.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/storage_access.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/known_library_list.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// The home screen: the libraries the app knows about, and the two ways
/// to reach one it does not (T-ML-05).
///
/// It is where the app starts when nothing resumes. On a first run the
/// list is empty and what is left is the screen this used to be —
/// branding, one line of explanation, open and create — so the welcome
/// is unchanged and the list takes the place of the explanation only
/// once there is something to list.
///
/// Both open flows go through the native directory picker (Storage Access
/// Framework on Android, xdg-desktop-portal on Linux) — no manual path
/// entry, so a library root can only ever be a real, readable folder.
/// The picker only *chooses* the folder: on Android the library is read
/// with plain file I/O, so "All files access" has to be granted before a
/// root on shared storage is usable, and the screen asks for it up front.
final class OpenLibraryScreen extends StatefulWidget {
  /// Creates the open/create screen.
  const new({required this.controller, super.key});

  /// The session that opens or creates the library for this screen.
  final LibrarySession controller;

  @override
  State<OpenLibraryScreen> createState() => _OpenLibraryScreenState();
}

final class _OpenLibraryScreenState extends State<OpenLibraryScreen> {
  /// Logger for the shared-storage permission handling on this screen.
  final _storageLog = const AppLogger(name: 'storage');

  /// True while a picker or open is in flight.
  bool _busy = false;

  /// True on Android while "All files access" is not granted; both flows
  /// stay disabled until it is.
  bool _needsAccess = false;

  /// A picker/open failure that the session does not know about.
  String? _pickerError;

  /// The known libraries, most recently opened first; empty until the
  /// first load lands, which is also a first run's final state.
  List<KnownLibrary> _known = const [];

  /// Of those, the ones whose folder is not there right now.
  Set<String> _unreachable = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_refreshAccess());
    unawaited(_loadKnown());
  }

  /// Reads the known-library list and checks which folders are there.
  Future<void> _loadKnown() async {
    final loaded = await loadKnownLibraries(widget.controller);
    if (!mounted) return;
    setState(() {
      _known = loaded.entries;
      _unreachable = loaded.missing;
    });
  }

  /// Forgets [libraryPath] and refreshes the list.
  Future<void> _forget(String libraryPath) async {
    await widget.controller.forgetLibrary(libraryPath);
    await _loadKnown();
  }

  /// Re-reads the shared-storage permission state into [_needsAccess].
  Future<void> _refreshAccess() async {
    final granted = await StorageAccess.hasAllFilesAccess();
    if (!mounted || _needsAccess == !granted) return;
    setState(() => _needsAccess = !granted);
  }

  /// Sends the user to the system "All files access" screen.
  Future<void> _grantAccess() async {
    _pickerError = null;
    _setBusy(true);
    final granted = await StorageAccess.ensureAllFilesAccess();
    if (!mounted) return;
    _storageLog.info('all-files access after prompt: $granted');
    _setBusy(false);
    setState(() {
      _needsAccess = !granted;
      if (!granted) {
        _pickerError = AppStrings.storageAccessNeeded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opening = widget.controller.phase == LibraryPhase.opening;
    final error = widget.controller.lastError ?? _pickerError;
    final active = opening || _busy;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/feather.png',
                  key: const Key('branding'),
                  width: 72,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.appTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                // The one line of explanation gives way to the list: on a
                // phone the two together push the libraries below the
                // fold, and someone with a list of them does not need it.
                if (_known.isEmpty)
                  Text(
                    AppStrings.openLibraryIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 24),
                if (!_needsAccess && _known.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: KnownLibraryList(
                      entries: _known,
                      unreachable: _unreachable,
                      enabled: !active,
                      onOpen: (path) => unawaited(_openKnown(path)),
                      onForget: (path) => unawaited(_forget(path)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_needsAccess)
                  _AccessPrompt(onGrant: active ? null : _grantAccess)
                else
                  _actions(active: active, narrow: narrow),
                if (active) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
                  // The first index of a large library is a long silent
                  // wait; naming what it is reading turns it into
                  // something to watch, and says the app is not stuck.
                  if (widget.controller.indexProgress case final progress?)
                    _IndexingLine(progress: progress),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Open and create, side by side where there is room.
  ///
  /// They carry the screen on a first run, so they are filled buttons
  /// there. Once a list is above them the list is what the screen is
  /// about, and two filled buttons under it would compete with it for
  /// the eye, so they step back to plain ones.
  Widget _actions({required bool active, required bool narrow}) {
    final prominent = _known.isEmpty;
    final open = prominent
        ? FilledButton(
            key: const Key('open-existing-library'),
            onPressed: active ? null : _openExisting,
            child: Text(AppStrings.openLibraryExisting),
          )
        : TextButton(
            key: const Key('open-existing-library'),
            onPressed: active ? null : _openExisting,
            child: Text(AppStrings.openLibraryExisting),
          );
    final create = prominent
        ? FilledButton.tonal(
            key: const Key('create-library'),
            onPressed: active ? null : _createNew,
            child: Text(AppStrings.openLibraryCreate),
          )
        : TextButton(
            key: const Key('create-library'),
            onPressed: active ? null : _createNew,
            child: Text(AppStrings.openLibraryCreate),
          );
    // Stacked on a phone only while they are the whole screen; as a pair
    // of plain buttons they fit on one line at any width.
    if (narrow && prominent) {
      return Column(children: [open, const SizedBox(height: 8), create]);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [open, const SizedBox(width: 8), create],
    );
  }

  /// Opens a library the user picked off the known list.
  Future<void> _openKnown(String path) async {
    _pickerError = null;
    await widget.controller.open(path, create: false);
    // The controller's event stream drives the rebuild (phase/lastError).
  }

  Future<void> _openExisting() async {
    _pickerError = null;
    final path = await _pickDirectory(AppStrings.openLibraryChooseFolder);
    if (path == null) return;
    await widget.controller.open(path, create: false);
    // The controller's event stream drives the rebuild (phase/lastError).
  }

  Future<void> _createNew() async {
    _pickerError = null;
    final parent = await _pickDirectory(AppStrings.openLibraryChooseParent);
    if (parent == null) return;
    final name = await _promptName();
    if (name == null || name.isEmpty) return;
    await widget.controller.open(p.join(parent, name), create: true);
    // The controller's event stream drives the rebuild (phase/lastError).
  }

  /// Opens the native directory picker; `null` when the user cancels.
  Future<String?> _pickDirectory(String title) async {
    // Re-checked here too: the permission can be revoked from Settings
    // while this screen is up.
    if (!await StorageAccess.hasAllFilesAccess()) {
      _storageLog.warning('pick blocked: no all-files access');
      if (mounted) {
        setState(() => _needsAccess = true);
      }
      return null;
    }
    _setBusy(true);
    try {
      final raw = await FilePicker.getDirectoryPath(dialogTitle: title);
      _setBusy(false);
      if (raw == null || raw.trim().isEmpty) {
        return null; // The user cancelled.
      }
      // The Android picker answers with a SAF tree URI rather than a
      // path; the library is read by path, so map it to the real one.
      final path = resolveLibraryRoot(raw);
      if (path == null) {
        _pickerError = AppStrings.openLibraryUnsupported;
        return null;
      }
      if (Platform.isAndroid) {
        // The folder must be reachable through the FUSE layer; fail here,
        // where the cause is still obvious.
        try {
          Directory(path).statSync();
        } on FileSystemException catch (e) {
          _pickerError = AppStrings.folderAccessDenied(e);
          return null;
        }
      }
      return path;
    } on Object catch (error) {
      // For example "unknown_path" from SAF for protected trees.
      _setBusy(false);
      _pickerError = AppStrings.folderPickFailed(error);
      return null;
    }
  }

  Future<String?> _promptName() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _NewLibraryDialog(),
    );
  }

  void _setBusy(bool busy) {
    if (_busy == busy) return;
    setState(() => _busy = busy);
  }
}

/// The note the first index is reading, under the progress bar.
///
/// One line, fixed height and no wrapping: the names change many times a
/// second, and a line that grew or shrank with each one would make the
/// whole screen jump.
final class _IndexingLine extends StatelessWidget {
  const new({required this.progress});

  /// The scan's latest report.
  final IndexProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            AppStrings.indexingCount(progress.done, progress.of),
            style: style,
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: Text(
              progress.file,
              key: const Key('indexing-file'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.center,
              style: style?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the open/create buttons while Android withholds the
/// shared-storage permission.
final class _AccessPrompt extends StatelessWidget {
  const new({required this.onGrant});

  /// Opens the system settings screen; null while a request is in flight.
  final Future<void> Function()? onGrant;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings.storageAccessExplained,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('grant-storage-access'),
          onPressed: onGrant,
          child: Text(AppStrings.storageAccessAction),
        ),
      ],
    );
  }
}

/// Dialog that asks for the name of the new library folder.
final class _NewLibraryDialog extends StatefulWidget {
  /// Creates the dialog.
  const new();

  @override
  State<_NewLibraryDialog> createState() => _NewLibraryDialogState();
}

final class _NewLibraryDialogState extends State<_NewLibraryDialog> {
  late final TextEditingController _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so "Create" tracks the (trimmed) name.
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _text.text.trim();
    return AlertDialog(
      title: Text(AppStrings.openLibraryCreateTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        decoration: InputDecoration(
          labelText: AppStrings.openLibraryFolderName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: name.isEmpty ? null : _submit,
          child: Text(AppStrings.actionCreate),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(_text.text.trim());
  }
}
