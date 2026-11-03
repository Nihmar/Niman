/// Files attached to a note (#1249, #1250): pasted from a file manager's
/// copy or dropped on the note, each copied into the library's attachments
/// folder and linked at the caret.
///
/// A file outside the library is copied in, under its content's SHA-256 as
/// *Insert image* stores a picture (`attachment_store.dart`), so the same
/// file is never there twice; the link reads as the name it came with. A
/// file already in the library is linked where it is. The link is the
/// library's format, as a file dropped from the tree writes one
/// ([droppedLink]): a picture or an audio file embedded, anything else
/// linked.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart' show pathInLibrary;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/dropped_link.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// Copies a file into the library's attachments folder: its
/// library-relative path.
typedef ImportAttachment = Future<String> Function(
  String libraryRoot,
  String sourcePath,
);

/// A note's attachments, reached through callbacks.
final class NoteAttach {
  /// Attachments of the note the callbacks reach.
  const new({
    required this.libraryRoot,
    required this.notePath,
    required this.linkType,
    required this.wikiTarget,
    required this.importFile,
    required this.insert,
    required this.messenger,
  });

  /// The library's folder; null for a note opened from outside one, which
  /// has no attachments folder.
  final String? Function() libraryRoot;

  /// The note's absolute path.
  final String Function() notePath;

  /// The library's link format.
  final LinkType Function() linkType;

  /// The shortest wikilink target that names a library file alone.
  final Future<String> Function(String path) wikiTarget;

  /// Copies a file in.
  final ImportAttachment importFile;

  /// Puts text at the caret, one undo step; false when the note takes none.
  final bool Function(String text) insert;

  /// Where a failure is said.
  final ScaffoldMessengerState? Function() messenger;

  static const _log = AppLogger(name: 'attach');

  /// Attaches the files at [paths] and links them at the caret, one line
  /// each. True when there were files to attach — even when one could not
  /// be, which is said — so a paste does not go on to paste text; false
  /// when the note can take none (no library) or [paths] holds no file.
  Future<bool> attach(List<String> paths) async {
    final root = libraryRoot();
    if (root == null || paths.isEmpty) return false;
    final note = pathInLibrary(root, notePath());
    if (note == null) return false;
    final links = <String>[];
    var tried = false;
    for (final path in paths) {
      // A folder is not a file to attach; a path gone since the copy is
      // not one either.
      if (!await FileSystemEntity.isFile(path)) continue;
      tried = true;
      final name = p.basename(path);
      try {
        final held = pathInLibrary(root, path);
        final stored = held ?? await importFile(root, path);
        links.add(
          await droppedLink(
            path: stored,
            note: note,
            linkType: linkType(),
            wikiTarget: wikiTarget,
            label: held == null ? name : null,
          ),
        );
        _log.info(held == null ? 'copied in: $stored' : 'linked: $stored');
      } on Object catch (error) {
        _log.warning('not attached: $name ($error)');
        messenger()
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: const Key('attach-failed'),
              content: Text(AppStrings.attachFailed(name)),
            ),
          );
      }
    }
    if (links.isNotEmpty) insert(links.join('\n'));
    return tried;
  }
}
