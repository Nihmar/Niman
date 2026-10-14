/// What following one link needs to know, and what it may call (split out
/// of `note_links.dart`): the explicit list a tap on a Markdown href or a
/// wikilink passes down — the same bargain `shell_layout.dart` struck with
/// the shell.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart' show Rect;
import 'package:niman/src/core/files.dart' show pathInLibrary;
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/resolver.dart';

/// What following one link needs to know, and what it may call.
@immutable
final class NoteLinkTargets {
  /// Creates the targets for one tap.
  const new({
    required this.source,
    required this.notePath,
    required this.libraryRoot,
    required this.newItemLocation,
    required this.outline,
    required this.jumpToHeading,
    this.blocks,
    this.onOpenNote,
    this.createMissingNote,
    this.modifier = false,
    this.anchor,
  });

  /// Resolves a link against the library; null while the library is not
  /// ready, and then nothing resolves.
  final LinkSource? source;

  /// The open note's absolute path: what a relative link is relative to.
  final String notePath;

  /// The library root, or null for a note opened from outside one.
  final String? libraryRoot;

  /// Where a dead link's new note would be created.
  final NewItemLocation newItemLocation;

  /// The note's headings, for an anchor to land on.
  final List<OutlineEntry> outline;

  /// Scrolls the note to a heading's line.
  final void Function(int line) jumpToHeading;

  /// The note's block anchors, the blocks that end with a ` ^id` (#844), read
  /// when a block link is followed; null for a surface that keeps none, where
  /// a block link finds nothing.
  final Future<List<BlockAnchor>> Function()? blocks;

  /// Opens another note through the shell; null leaves a link that
  /// resolves with nowhere to go.
  final void Function(String path, String? anchor)? onOpenNote;

  /// Creates the note a dead link points at, and the folders on the way to
  /// it (#847); null disables the offer.
  final Future<String> Function(String path)? createMissingNote;

  /// The tap carried the platform's link modifier (Ctrl, Cmd on macOS) —
  /// the editor surface's own way to follow a link. A *dead* link is then
  /// created on the spot and opened, the modifier standing as its own
  /// confirmation, rather than offered (#477); a resolved link is
  /// followed as always, and every other tap keeps the offer.
  final bool modifier;

  /// Where the pointer last went down on the note, on screen: a question
  /// the link asks a pointer — which note, whether to create it — opens
  /// there (#712). Null asks a phone's way.
  final Rect? anchor;

  /// The open note's path in the library, slash-separated — what a `..` in
  /// a link walks from (#491); null for a note opened from outside one.
  String? get notePathInLibrary => pathInLibrary(libraryRoot, notePath);
}
