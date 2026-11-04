/// The open note's links: following them from either pane, the embeds they
/// name, a link dropped from the tree, and the jumps to a heading (issue
/// #100 moved them out of `note_view.dart`).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/embed_path.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/markdown/buffer_block_anchors.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/dropped_link.dart';
import 'package:niman/src/ui/note_links.dart';
import 'package:niman/src/ui/outline_panel.dart';
import 'package:path/path.dart' as p;

/// What the note's links do, read off the view's settings through explicit
/// getters and acted on through the editor surface's own door.
final class NoteLinkActions {
  /// The links of the note at [notePath], on [surface].
  new({
    required this.notePath,
    required this.notePathInLibrary,
    required this.libraryRoot,
    required this.linkSource,
    required this.linkType,
    required this.newItemLocation,
    required this.wikilinkSuggester,
    required this.onOpenNote,
    required this.createMissingNote,
    required this.outline,
    required this.surface,
    required this.readView,
    required this.reading,
    required this.context,
    required this.mounted,
    required this.onDropped,
  });

  /// The open note's absolute path.
  final String Function() notePath;

  /// The note's path in the library, slash-separated, or null for a note
  /// opened from outside one.
  final String? Function() notePathInLibrary;

  /// The library root, or null for a note opened from outside one.
  final String? Function() libraryRoot;

  /// The link-resolution source, or null while there is none.
  final LibraryLinks? Function() linkSource;

  /// The link format a dropped link is written in.
  final LinkType Function() linkType;

  /// Where a note created from a dead link lands.
  final NewItemLocation Function() newItemLocation;

  /// The library's wikilink names, or null with no open library.
  final WikilinkSuggester? Function() wikilinkSuggester;

  /// Opens another note through the shell, or null.
  final void Function(String path, String? anchor)? Function() onOpenNote;

  /// Creates the note a dead link points at, or null.
  final Future<String> Function(String path)? Function() createMissingNote;

  /// The note's headings.
  final List<OutlineEntry> Function() outline;

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// The read pane's state, when it is built.
  final MarkdownReadViewState? Function() readView;

  /// Whether the read pane is the one on stage.
  final bool Function() reading;

  /// The view's context, for the questions a link asks.
  final BuildContext Function() context;

  /// Whether the view is still mounted.
  final bool Function() mounted;

  /// A dropped link went in at the caret: the editor takes the keyboard, and
  /// the statistics and the preview follow.
  final VoidCallback onDropped;

  /// Where the pointer last went down on the note, for the questions a
  /// link asks there (#712).
  Offset? pointerDownAt;

  /// The note's block anchors (#844), read off its buffer when a block link
  /// is followed; the source view's `[[#^` panel reads the same (#869).
  late final BufferBlockAnchors blockAnchors = BufferBlockAnchors(
    () => surface()!.buffer,
  );

  Future<List<BlockAnchor>> _blocks() async =>
      surface() == null ? const <BlockAnchor>[] : await blockAnchors.read();

  /// What following a link from this note needs (issue #100 moved the
  /// following itself into `note_links.dart`).
  ///
  /// [modifier] marks a tap the editor surface carried with the platform's
  /// link modifier (Ctrl, Cmd on macOS): its own way to follow a link,
  /// where a dead one is created on the spot rather than offered (#477).
  /// The preview follows links on a plain tap, so it keeps the offer.
  NoteLinkTargets targets({bool modifier = false}) => NoteLinkTargets(
    source: linkSource(),
    notePath: notePath(),
    libraryRoot: libraryRoot(),
    newItemLocation: newItemLocation(),
    outline: outline(),
    jumpToHeading: jumpToHeading,
    blocks: _blocks,
    onOpenNote: onOpenNote(),
    createMissingNote: createMissingNote(),
    modifier: modifier,
    anchor: switch (pointerDownAt) {
      final at? => menuAnchorAt(at),
      null => null,
    },
  );

  /// Resolves an `![[…]]` embed through the shared rule (#24): library
  /// root first, then the note's own folder, then the link index.
  Future<String?> resolveEmbed(String target) {
    final root = libraryRoot();
    if (root == null) return Future<String?>.value();
    return resolveEmbedPath(target, notePath(), root, linkSource());
  }

  /// Opens the file the embed [ref] names, found by the shared embed rule
  /// ([resolveEmbed]); false when the disk has no such file, and the caller
  /// goes on to the index and the dead-link flow.
  Future<bool> _openEmbedOnDisk(WikiRef ref) async {
    final root = libraryRoot();
    final open = onOpenNote();
    if (root == null || open == null || ref.target.isEmpty) return false;
    final found = await resolveEmbed(ref.target);
    if (found == null || !mounted()) return false;
    final rel = pathInLibrary(root, found);
    if (rel == null) return false;
    // The note itself is the one target that stays here: the index flow
    // jumps locally for it.
    if (rel == notePathInLibrary()) return false;
    open(rel, ref.fragment);
    return true;
  }

  /// Opens a link token's target: [raw] is the token as written — `[[…]]` for
  /// a wikilink, `![[…]]` for an embed, `[…](…)` for a Markdown link; [href]
  /// is the target its parse resolved, when the tap carried one — a reference
  /// link has no `](href)` in [raw] to read it from.
  ///
  /// The editor surface only follows a link on a Ctrl/Cmd+click, so the
  /// targets carry the modifier: a dead link is created on the spot (#477).
  Future<void> openLinkToken(TokenKind kind, String raw, String? href) async {
    if (kind == TokenKind.wikilink) {
      // An embed's run carries its own `!` (#994): the wikilink inside it
      // starts one character later.
      final embed = raw.startsWith('!');
      final wiki = embed ? raw.substring(1) : raw;
      final ref = parseWikiRef(wiki.substring(2, wiki.length - 2));
      // The read view draws an embed from the disk first (#24); the click
      // follows the file by that same rule, so a target the index has not
      // caught up with yet is opened, not offered for creation (#1010).
      if (embed && await _openEmbedOnDisk(ref)) return;
      if (!mounted()) return;
      await openWiki(context(), ref, targets(modifier: true));
    } else {
      final close = raw.indexOf(']');
      final inline = close < 0 ? '' : raw.substring(close + 2, raw.length - 1);
      await openHref(context(), href ?? inline, targets(modifier: true));
    }
  }

  /// Writes a link to the library file at [path], dropped from the tree,
  /// at the caret the drop left (#704): one edit, one undo step.
  Future<void> insertDroppedLink(String path) async {
    final root = libraryRoot();
    if (root == null) return;
    final suggester = wikilinkSuggester();
    final text = await droppedLink(
      path: path,
      note: relPath(notePath(), root),
      linkType: linkType(),
      wikiTarget: (path) async =>
          await suggester?.targetOf(path) ?? p.basenameWithoutExtension(path),
    );
    if (!mounted()) return;
    surface()?.replaceSelection(text);
    onDropped();
  }

  /// Opens the outline sheet and jumps to whatever was picked; a pointer's
  /// menu grows from [anchor], the outline button.
  Future<void> openOutline(Rect? anchor) async {
    final line = await showOutlineSheet(
      context(),
      entries: outline(),
      anchor: anchor,
    );
    if (line == null || !mounted()) return;
    jumpToHeading(line);
  }

  /// The outline jump: caret to the heading line, then bring it into view.
  ///
  /// When the preview is visible (phone switch mode) the editor caret is
  /// off-screen — the preview is brought to the heading's block as well,
  /// so the jump is visible in every layout.
  void jumpToHeading(int line) {
    const AppLogger(name: 'links').debug('jump to source line $line');
    surface()?.jumpToLine(line);
    _syncPreviewToLine(line);
  }

  /// Scrolls the read pane so the block starting at source [line] is in
  /// view (no-op when the read pane is hidden or not built yet).
  void _syncPreviewToLine(int line) {
    if (!reading() || !mounted()) return;
    const log = AppLogger(name: 'links');
    // The read mode's own answer: the line resolves to a block and the
    // block to its offset in the height map, measured where a frame has
    // drawn and estimated where none has (#256).
    final state = readView();
    if (state == null) {
      log.debug('anchor jump: the read view is not built yet — skipped');
      return;
    }
    log.debug('anchor jump: read mode, source line $line');
    state.jumpToLine(line);
  }
}
