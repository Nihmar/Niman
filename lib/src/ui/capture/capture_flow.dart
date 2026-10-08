/// Capturing a web page from the shell (#531): the command, a link pasted
/// outside the editor or dropped on the window open the capture dialog
/// over the open library, and the note it makes is opened.
///
/// Like the create flow, it needs nothing of the shell's state: where to
/// capture is a question it asks, and what to open afterwards is a fact it
/// reports.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/strings.dart';

/// [text] as the address of a web page, or null when it is not one: one
/// http or https address, and nothing else.
Uri? webAddressIn(String? text) {
  final trimmed = text?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.contains(RegExp(r'\s'))) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return null;
  }
  return uri.host.isEmpty ? null : uri;
}

/// Captures pages into the open library.
final class CaptureFlow {
  /// A flow over [controller]'s library.
  new({
    required this.controller,
    required this.createParent,
    required this.attachmentsFolder,
    required this.linkType,
    required this.onCaptured,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// The folder a capture goes in unless another is picked: the tree's.
  final String Function() createParent;

  /// The library's attachments folder.
  final String Function() attachmentsFolder;

  /// How the library writes links.
  final LinkType Function() linkType;

  /// Opens the note a capture made, by its library-relative path.
  final void Function(String path) onCaptured;

  /// Opens the dialog over [url]; with none, over the address the
  /// clipboard holds, when it holds one.
  Future<void> capture(BuildContext context, {Uri? url}) async {
    final ops = controller.ops;
    final root = controller.root;
    if (ops == null || root == null) return;
    var page = url;
    var fromClipboard = false;
    if (page == null) {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      page = webAddressIn(clip?.text);
      fromClipboard = page != null;
    }
    if (!context.mounted) return;
    final path = await showCaptureDialog(
      context,
      url: page,
      fromClipboard: fromClipboard,
      target: CaptureTarget(
        libraryRoot: root,
        attachmentsFolder: attachmentsFolder(),
        linkType: linkType(),
        folder: createParent(),
        browser: findPageBrowser,
        pickFolder: (current) async {
          final folders = await controller.folders();
          if (!context.mounted) return null;
          return await showFolderPicker(
            context,
            title: AppStrings.captureFolderField,
            folders: folders,
            ops: ops,
            current: current,
            allowRoot: true,
          );
        },
        create: (folder, name, text) async {
          final row = await ops.createNote(
            parentPath: folder,
            name: name,
            content: text,
          );
          return row.path;
        },
      ),
    );
    if (path != null) onCaptured(path);
  }
}
