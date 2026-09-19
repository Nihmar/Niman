/// Picking a library folder, and naming a new one: what the opening
/// screen and the library window (#203) both offer.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/library_root.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/storage_access.dart';
import 'package:niman/src/ui/strings.dart';

const AppLogger _log = AppLogger(name: 'storage');

/// How a folder pick ended.
sealed class LibraryPick {
  const new();
}

/// A folder, read by path.
final class LibraryPicked extends LibraryPick {
  /// Picked [path].
  const new(this.path);

  /// The folder's path.
  final String path;
}

/// The user cancelled.
final class LibraryPickCancelled extends LibraryPick {
  /// A cancelled pick.
  const new();
}

/// Android withholds the shared-storage permission; nothing was shown.
final class LibraryPickNeedsAccess extends LibraryPick {
  /// A pick the permission stopped.
  const new();
}

/// The pick failed, for the reason in [message].
final class LibraryPickFailed extends LibraryPick {
  /// A failed pick.
  const new(this.message);

  /// What to tell the user.
  final String message;
}

/// Opens the system folder picker titled [title].
///
/// Checks the permission first, since it can be revoked while a screen
/// is up. On Android the picker answers with a SAF tree URI rather than
/// a path; the library is read by path, so this maps it to the real one
/// and checks that it can be reached.
Future<LibraryPick> pickLibraryFolder(String title) async {
  if (!await StorageAccess.hasAllFilesAccess()) {
    _log.warning('pick blocked: no all-files access');
    return const LibraryPickNeedsAccess();
  }
  try {
    final raw = await FilePicker.getDirectoryPath(dialogTitle: title);
    if (raw == null || raw.trim().isEmpty) return const LibraryPickCancelled();
    final path = resolveLibraryRoot(raw);
    if (path == null) {
      return LibraryPickFailed(AppStrings.openLibraryUnsupported);
    }
    if (Platform.isAndroid) {
      // The folder must be reachable through the FUSE layer; fail here,
      // where the cause is still obvious.
      try {
        Directory(path).statSync();
      } on FileSystemException catch (e) {
        return LibraryPickFailed(AppStrings.folderAccessDenied(e));
      }
    }
    return LibraryPicked(path);
  } on Object catch (error) {
    // For example "unknown_path" from SAF for protected trees.
    return LibraryPickFailed(AppStrings.folderPickFailed(error));
  }
}

/// Asks for the new library folder's name; null when cancelled.
Future<String?> showNewLibraryDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _NewLibraryDialog(),
  );
}

/// Dialog that asks for the name of the new library folder.
final class _NewLibraryDialog extends StatefulWidget {
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
