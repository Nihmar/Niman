/// Capturing a web page from the shell (#531). On the desktop the command,
/// a link pasted outside the editor or dropped on the window open the
/// capture dialog over the open library, and the note it makes is opened.
/// On a phone New ▸ Capture web page, and a page shared from the browser,
/// open the capture sheet instead, and Save leaves the page to the
/// background capture — a share's sending the user back to the browser.
///
/// Like the create flow, it needs nothing of the shell's state: where to
/// capture is a question it asks, and what to open afterwards is a fact it
/// reports.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/capture/capture_quote.dart';
import 'package:niman/src/capture/shared_page.dart';
import 'package:niman/src/core/android_task.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/capture/capture_routes.dart';
import 'package:niman/src/ui/capture/capture_services.dart';
import 'package:niman/src/ui/capture/capture_sheet.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/note_picker.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

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
    required this.services,
    required this.createParent,
    required this.attachmentsFolder,
    required this.linkType,
    required this.onCaptured,
    this.openNote,
    this.clock = DateTime.now,
    bool? useSheet,
  }) : useSheet = useSheet ?? Platform.isAndroid;

  /// The open library's session.
  final LibrarySession controller;

  /// How pages are read and saved, and the captures that run off
  /// screen.
  final CaptureServices services;

  /// The folder a capture goes in unless another is picked: the tree's.
  final String Function() createParent;

  /// The library's attachments folder.
  final String Function() attachmentsFolder;

  /// How the library writes links.
  final LinkType Function() linkType;

  /// Opens the note a capture made, by its library-relative path.
  final void Function(String path) onCaptured;

  /// The note on screen, library-relative: where a shared quote is
  /// appended unless another note is picked.
  final String? Function()? openNote;

  /// The time now, for a new note's frontmatter.
  final DateTime Function() clock;

  /// Whether a capture asks with the phone's sheet, saving in the
  /// background, rather than with the desktop's dialog.
  final bool useSheet;

  /// Asks where to capture [url]; with none, the address the clipboard
  /// holds, when it holds one.
  Future<void> capture(BuildContext context, {Uri? url}) async {
    var page = url;
    var fromClipboard = false;
    if (page == null) {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      page = webAddressIn(clip?.text);
      fromClipboard = page != null;
    }
    if (!context.mounted) return;
    final target = _target(context);
    if (target == null) return;
    if (useSheet) {
      final chosen = await showCaptureSheet(
        context,
        target: target,
        url: page,
        fromClipboard: fromClipboard,
      );
      await _run(chosen, target);
      return;
    }
    final path = await showCaptureDialog(
      context,
      url: page,
      fromClipboard: fromClipboard,
      target: target,
    );
    if (path != null) onCaptured(path);
  }

  /// Asks where to save what the browser shared; Save sends the user back
  /// to the browser while the page is captured.
  Future<void> captureShared(BuildContext context, WebShare share) async {
    final target = _target(context);
    if (target == null) return;
    final chosen = await showCaptureSheet(
      context,
      target: target,
      share: share,
      appendTo: openNote?.call(),
      pickNote: (current) => showNotePicker(
        context,
        controller: controller,
        title: AppStrings.captureAppendToNote,
        currentPath: current,
      ),
    );
    if (chosen == null) return;
    await _run(chosen, target);
    await moveTaskToBack();
  }

  Future<void> _run(CaptureSheetResult? chosen, CaptureTarget target) async {
    switch (chosen) {
      case null:
        return;
      case CapturePageChosen(:final reading, :final chosen):
        unawaited(
          services.background.add(reading, target: target, chosen: chosen),
        );
      case CaptureQuoteChosen():
        await _keepQuote(chosen);
    }
  }

  /// Appends [chosen]'s quote to its note, or makes it a new one, and
  /// says so outside the app: the user is back in the browser by then.
  Future<void> _keepQuote(CaptureQuoteChosen chosen) async {
    final ops = controller.ops;
    if (ops == null) return;
    final quote = chosen.quote;
    final page = quote.pageUrl;
    final notifier = services.background.notifier;
    try {
      final appendTo = chosen.appendTo;
      final note = appendTo != null
          ? await ops.appendToNote(
              appendTo,
              quoteMarkdown(quote.quote, page, title: quote.title),
            )
          : await ops.createNote(
              parentPath: chosen.folder,
              name: quote.title ?? page.host,
              content: quoteNote(
                quote.quote,
                page,
                captured: clock(),
                title: quote.title,
                tags: chosen.tags,
              ),
            );
      await notifier.result(
        title: AppStrings.captureQuoteAdded(
          p.posix.basenameWithoutExtension(note.path),
        ),
        body: AppStrings.captureQuoteFrom(quote.title ?? page.host),
        open: captureOpenRoute(note.path),
      );
    } on Object catch (error) {
      await notifier.result(
        title: AppStrings.captureFailedTitle(page.host),
        body: '$error',
      );
    }
  }

  /// Where a capture goes: the open library, or null when none is open.
  CaptureTarget? _target(BuildContext context) {
    final ops = controller.ops;
    final root = controller.root;
    if (ops == null || root == null) return null;
    return CaptureTarget(
      libraryRoot: root,
      attachmentsFolder: attachmentsFolder(),
      linkType: linkType(),
      folder: createParent(),
      browser: services.browser,
      read: services.read,
      save: services.save,
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
    );
  }
}

/// A paste no text field or editor took: a web address on the clipboard
/// opens the capture dialog on it; anything else is left alone.
final class CapturePasteAction extends Action<PasteTextIntent> {
  /// The action, calling [onAddress] with the address pasted.
  new(this.onAddress);

  /// Captures the page at an address.
  final void Function(Uri url) onAddress;

  @override
  Future<void> invoke(PasteTextIntent intent) async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final url = webAddressIn(clip?.text);
    if (url != null) onAddress(url);
  }
}
