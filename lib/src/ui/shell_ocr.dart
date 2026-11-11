/// What the shell offers of text recognition (#1109; out of `shell.dart`
/// for #1266): whether the entries show, the file views' actions, and the
/// recognize a menu asks for.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/palette/command_features.dart';
import 'package:niman/src/ui/shell_ocr_flow.dart';

/// The shell's text recognition, null-safe where the app has none.
final class ShellOcr {
  /// Recognition through [flow], null without an engine.
  new({
    required this.flow,
    required this.queue,
    required this.controller,
    required this.features,
    required this.openNote,
    required this.context,
  });

  /// The flow that asks and queues, null without OCR.
  final ShellOcrFlow? flow;

  /// The queue the pages wait in, null without OCR.
  final OcrQueue? queue;

  /// The open library.
  final LibrarySession controller;

  /// The library's features.
  final Features Function() features;

  /// Opens a recognized text.
  final void Function(String path) openNote;

  /// The shell's context.
  final BuildContext Function() context;

  /// Whether the Recognize text entries are offered: there is OCR, and the
  /// library has it on (#1109).
  bool get offers =>
      flow != null && commandFeatureOn(AppCommand.recognizeText, features());

  /// The file views' Recognize text, or null without OCR or a library.
  OcrFileActions? get actions {
    final queue = this.queue;
    final root = controller.root;
    final ops = controller.ops;
    final flow = this.flow;
    if (flow == null || !offers || queue == null || root == null) return null;
    if (ops == null) return null;
    return OcrFileActions(
      queue: queue,
      root: root,
      ops: ops,
      recognize: recognize,
      openNote: openNote,
      recognizeAgain: flow.recognizeAgain,
    );
  }

  /// Asks how to recognize [path] (library-relative) and queues it.
  void recognize(String path, {int? page, int? pageCount}) {
    final flow = this.flow;
    if (flow == null) return;
    unawaited(
      flow.recognize(context(), path, page: page, pageCount: pageCount),
    );
  }
}
