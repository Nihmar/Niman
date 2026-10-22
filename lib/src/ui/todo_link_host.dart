/// What the Todo tab needs to follow a task's link (#1152): the resolved
/// links of the tasks, and the way a note's own links are followed.
library;

import 'dart:async';

import 'package:flutter/painting.dart' show Rect;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/task_row_links.dart';
import 'package:niman/src/todo/todo_file_names.dart';
import 'package:niman/src/ui/link_preview/link_preview_controller.dart';
import 'package:niman/src/ui/link_preview/link_preview_sheet.dart';
import 'package:niman/src/ui/note_links.dart';

/// The links of the Todo tab: the shell owns one, beside the task list.
///
/// A task's link is followed as a wikilink in a note is: the same resolver,
/// the same picker for a name two notes share, the same offer to create a
/// note that is not there, and an anchor scrolls the note it opens to its
/// heading or block. Nothing here knows how; it hands the link to
/// `openWiki` and `openHref` with the targets the shell makes for a link
/// written in `todo.txt`.
final class TodoLinkHost {
  /// The links of the tasks in [map], followed through the [NoteLinkTargets]
  /// that [targets] makes (given where the tap was, when a pointer made it).
  ///
  /// [source] is the open library's links, and [previewEnabled] says whether
  /// the link preview setting is on: they serve a long press on a touch
  /// screen.
  new({
    required this.map,
    required this.targets,
    required LibraryLinks? Function() source,
    required bool Function() previewEnabled,
    this.suggester,
  }) : _previews = LinkPreviewController(
         source: source,
         notePath: () => todoFileName,
         enabled: previewEnabled,
       );

  /// The resolved links of the tasks.
  final TaskLinkMap map;

  /// The library's notes for a `[[` typed in a task's text: the suggester the
  /// editor's wikilink panel reads. Null offers none.
  final WikilinkSuggester? Function()? suggester;

  /// What following a link written in `todo.txt` needs, for a tap at
  /// [Rect] (null on a phone).
  final NoteLinkTargets Function(Rect? anchor) targets;

  final LinkPreviewController _previews;
  final MathCache _math = MathCache();

  /// Follows [chip] as a tap on it in a note would: the note opens (at its
  /// heading or block), a name two notes share asks which, and a note that
  /// is not there is offered. [anchor] is where the pointer went down.
  Future<void> follow(
    BuildContext context,
    TaskRowLink chip, {
    Rect? anchor,
  }) async {
    switch (chip.link.link) {
      case final WikiLink wiki:
        await openWiki(context, wiki.ref, targets(anchor));
      case final MarkdownLink markdown:
        await openHref(context, markdown.href, targets(anchor));
    }
  }

  /// A long press on [chip] on a touch screen: the note it names, in the
  /// sheet a long press on a wikilink opens, with an Open action. Nothing
  /// for a link that names no note.
  Future<void> preview(BuildContext context, TaskRowLink chip) async {
    if (!_previews.enabled) return;
    final preview = await _previews.read(chip.preview);
    if (preview == null || !context.mounted) return;
    await showLinkPreviewSheet(
      context,
      preview: preview,
      mathCache: _math,
      onOpen: () {
        if (context.mounted) unawaited(follow(context, chip));
      },
    );
  }

  /// Lets go of the preview's reading and its cache.
  void dispose() {
    _previews.dispose();
    _math.dispose();
  }
}
