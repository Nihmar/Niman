/// Following a link out of a note (issue #100, split out of
/// `note_view.dart`): a Markdown href or a wikilink, resolved against
/// the library and then opened, jumped to, launched, disambiguated, or
/// offered as a note that does not exist yet.
///
/// The note view keeps the state; what it passes here is
/// [NoteLinkTargets], the explicit list of what following one link
/// needs — the same bargain `shell_layout.dart` struck with the shell.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/links/slug.dart';
import 'package:niman/src/ui/missing_note_dialog.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// What following one link needs to know, and what it may call.
@immutable
final class NoteLinkTargets {
  /// Creates the targets for one tap.
  const new({
    required this.source,
    required this.notePath,
    required this.libraryRoot,
    required this.missingNoteLocation,
    required this.outline,
    required this.jumpToHeading,
    this.onOpenNote,
    this.createMissingNote,
    this.folderExists,
  });

  /// Resolves a link against the library; null while the library is not
  /// ready, and then nothing resolves.
  final LinkSource? source;

  /// The open note's absolute path: what a relative link is relative to.
  final String notePath;

  /// The library root, or null for a note opened from outside one.
  final String? libraryRoot;

  /// Where a dead link's new note would be created.
  final MissingNoteLocation missingNoteLocation;

  /// The note's headings, for an anchor to land on.
  final List<OutlineEntry> outline;

  /// Scrolls the note to a heading's line.
  final void Function(int line) jumpToHeading;

  /// Opens another note through the shell; null leaves a link that
  /// resolves with nowhere to go.
  final void Function(String path, String? anchor)? onOpenNote;

  /// Creates the note a dead link points at; null disables the offer.
  final Future<String> Function(String path)? createMissingNote;

  /// Whether a folder exists, for the dead-link offer (a test seam).
  final Future<bool> Function(String root, String rel)? folderExists;
}

/// The preview's link handler (T-M3-07): `.md` relative links navigate
/// in-app, http(s) launch the browser, `#anchor` stays local.
Future<void> openHref(
  BuildContext context,
  String href,
  NoteLinkTargets link,
) async {
  const log = AppLogger(name: 'links');
  final source = link.source;
  log.debug(
    'md link tap in ${p.basename(link.notePath)}: href="$href" '
    '(source ${source == null ? 'not loaded' : 'ready'})',
  );
  if (source == null) return;
  final resolved = await source.resolveMarkdown(href);
  log.debug('md link "$href" -> ${describeResolved(resolved)}');
  if (!context.mounted) return;
  await _applyResolved(context, resolved, link);
}

/// The preview's wikilink handler: `[[x]]` targets resolve and open;
/// empty-target forms (`[[#h]]`, `[[|a]]`) stay local.
Future<void> openWiki(
  BuildContext context,
  WikiRef ref,
  NoteLinkTargets link,
) async {
  const log = AppLogger(name: 'links');
  final source = link.source;
  final alias = ref.alias == null ? '-' : '"${ref.alias}"';
  final heading = ref.heading == null ? '-' : '"${ref.heading}"';
  final src = source == null ? 'not loaded' : 'ready';
  log.debug(
    'wikilink tap in ${p.basename(link.notePath)}: '
    'target="${ref.target}" alias=$alias heading=$heading (source $src)',
  );
  if (ref.target.isEmpty) {
    final heading = ref.heading;
    if (heading == null) {
      log.debug('wikilink: empty target and no heading — snackbar');
      return _linkSnack(context, AppStrings.unresolvedLinkTitle);
    }
    log.debug('wikilink: local anchor — jump to heading "$heading"');
    jumpToAnchor(context, heading, link);
    return;
  }
  if (source == null) return;
  // The documented form: `[[target]]`, `[[target#heading]]`,
  // `[[target|alias]]` — the first part is the target.
  var resolved = await source.resolveWiki(ref.target);
  final outcome = describeResolved(resolved);
  log.debug('wikilink target "${ref.target}" -> $outcome');
  var anchor = ref.heading;
  if (resolved is! ResolvedNote && ref.alias != null) {
    // Label-first links — `[[a label|filename]]`, the display text
    // first — parse with the target and alias swapped, so when the
    // target-first interpretation finds nothing, the aliased part is
    // tried as the target (an optional `#heading` rides on it) before
    // the link is declared dead. A link whose first part resolves
    // never reaches this fallback.
    final alias = ref.alias!;
    final hash = alias.indexOf('#');
    final aliasTarget = hash == -1 ? alias : alias.substring(0, hash);
    final aliasHeading = hash == -1 || hash == alias.length - 1
        ? null
        : alias.substring(hash + 1);
    if (aliasTarget.trim().isNotEmpty) {
      log.debug(
        'wikilink: target-first unresolved — retrying the aliased '
        'part "$aliasTarget" as the target',
      );
      final swapped = await source.resolveWiki(aliasTarget.trim());
      final swappedOutcome = describeResolved(swapped);
      log.debug('wikilink alias "$aliasTarget" -> $swappedOutcome');
      if (swapped is ResolvedNote || swapped is AmbiguousNote) {
        resolved = swapped;
        anchor = aliasHeading;
      }
    }
  }
  if (!context.mounted) return;
  if (resolved is ResolvedNote) {
    // The parser splits `[[x#H]]` off before the resolver sees it, so
    // the anchor is carried from the ref (or from a label-first
    // `#heading` on the aliased target).
    await _openNoteResult(
      context,
      resolved.note,
      anchor ?? resolved.heading,
      link,
    );
    return;
  }
  await _applyResolved(context, resolved, link);
}

Future<void> _applyResolved(
  BuildContext context,
  ResolveResult resolved,
  NoteLinkTargets link,
) async {
  const log = AppLogger(name: 'links');
  switch (resolved) {
    case ExternalLink(:final url):
      log.debug('link outcome: launching url $url');
      try {
        await launchUrl(Uri.parse(url));
      } on Object {
        if (context.mounted) _linkSnack(context, AppStrings.openLinkFailed);
      }
    case LocalAnchor(:final heading):
      log.debug('link outcome: jump to local heading "$heading"');
      jumpToAnchor(context, heading, link);
    case ResolvedNote(:final note, :final heading):
      await _openNoteResult(context, note, heading, link);
    case AmbiguousNote(:final candidates):
      log.debug(
        'link outcome: ${candidates.length} ambiguous candidates — '
        'picker',
      );
      await _pickAmbiguous(context, candidates, link);
    case UnresolvedNote(:final target):
      final outcome = await _handleDeadLink(context, target, link);
      log.debug('link outcome: ${describeOutcome(outcome)}');
      if (outcome is DeadLinkCreated) {
        final open = link.onOpenNote;
        if (open == null) {
          if (context.mounted) {
            _linkSnack(context, AppStrings.unresolvedLinkTitle);
          }
          return;
        }
        open(outcome.path, null);
      } else if (outcome is DeadLinkFolderMissing) {
        if (context.mounted) {
          _linkSnack(
            context,
            AppStrings.missingNoteFolderMissing(outcome.folder),
          );
        }
      } else if (outcome is DeadLinkNotOffered && context.mounted) {
        _linkSnack(context, AppStrings.unresolvedLinkTitle);
      }
    // DeadLinkDeclined: nothing — no error, no second prompt
    // (issue #78).
  }
}

/// The dead-link offer (issue #78): propose where the missing note
/// would be created, ask, create through the library's own path.
Future<DeadLinkOutcome> _handleDeadLink(
  BuildContext context,
  String target,
  NoteLinkTargets link,
) async {
  final create = link.createMissingNote;
  final root = link.libraryRoot;
  if (create == null || root == null) return const DeadLinkNotOffered();
  final linkContext = LinkContext(
    libraryRoot: root,
    currentNote: link.notePath,
  );
  final seam = link.folderExists;
  final handler = MissingNoteHandler(
    location: link.missingNoteLocation,
    confirm: (path) async {
      // The dialog needs a live context; an unmounted note declines,
      // and a dismiss (outside tap) reads as one.
      if (!context.mounted) return false;
      final confirmed = await showMissingNoteDialog(context, path: path);
      return confirmed ?? false;
    },
    folderExists: seam == null
        ? (rel) => _folderExists(root, rel)
        : (rel) => seam(root, rel),
    createNote: create,
  );
  return await handler.handleDeadLink(target, linkContext);
}

/// A folder's disk existence, off the UI isolate (one stat is a FUSE
/// round trip on Android).
Future<bool> _folderExists(String root, String rel) =>
    Isolate.run(() => Directory(p.join(root, rel)).existsSync());

/// A dead-link outcome for the log: `Created: Notes/Foo.md`.
String describeOutcome(DeadLinkOutcome outcome) => switch (outcome) {
  DeadLinkCreated(:final path) => 'created $path',
  DeadLinkDeclined() => 'creation declined — nothing shown',
  DeadLinkNotOffered() => 'no offer — snackbar',
  DeadLinkFolderMissing(:final folder) => 'folder "$folder" missing — error',
};

/// Opens [note] via the shell (or jumps locally when it is already the
/// open note).
Future<void> _openNoteResult(
  BuildContext context,
  Note note,
  String? anchor,
  NoteLinkTargets link,
) async {
  const log = AppLogger(name: 'links');
  final root = link.libraryRoot;
  final currentRel = root == null
      ? null
      : p.relative(link.notePath, from: root);
  if (currentRel != null && note.path == currentRel) {
    // Same note: stay and jump (or nothing when there is no anchor).
    log.debug(
      'link outcome: target is the current note — '
      '${anchor == null ? 'no-op' : 'local jump to "$anchor"'}',
    );
    if (anchor != null) jumpToAnchor(context, anchor, link);
    return;
  }
  final open = link.onOpenNote;
  if (open == null) {
    log.debug(
      'link outcome: resolved ${note.path} but no onOpenNote — '
      'snackbar',
    );
    if (context.mounted) _linkSnack(context, AppStrings.unresolvedLinkTitle);
    return;
  }
  log.debug(
    'link outcome: open ${note.path} '
    'anchor=${anchor == null ? '-' : '"$anchor"'}',
  );
  open(note.path, anchor);
}

/// The minimal ambiguous-link picker (M3 list + select; polish M6).
Future<void> _pickAmbiguous(
  BuildContext context,
  List<Note> candidates,
  NoteLinkTargets link,
) async {
  if (!context.mounted) return;
  final chosen = await showDialog<Note>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(AppStrings.ambiguousLinkTitle),
      children: [
        for (final note in candidates)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, note),
            child: Text(note.path),
          ),
      ],
    ),
  );
  if (chosen == null || !context.mounted) return;
  await _openNoteResult(context, chosen, null, link);
}

/// Jumps to the heading whose slug matches [heading] (the shared slug,
/// so `[[x#My Heading]]` and `## My Heading` agree).
///
/// Also the note's own opening jump, when it was opened at an anchor.
void jumpToAnchor(BuildContext context, String heading, NoteLinkTargets link) {
  final slug = headingSlug(heading);
  OutlineEntry? entry;
  for (final e in link.outline) {
    if (headingSlug(e.text) == slug) {
      entry = e;
      break;
    }
  }
  if (entry == null) {
    // Trace the outline so a dead anchor is diagnosable from the log:
    // is the heading missing, or does its text differ from the link's?
    final entries = link.outline;
    final shown = entries.length <= 40
        ? entries
        : [...entries.take(20), ...entries.skip(entries.length - 20)];
    const AppLogger(name: 'links').debug(
      'heading "$heading" (slug "$slug") not found among '
      '${entries.length} outline entr(ies): '
      '${shown.map((e) => '${e.line}:"${e.text}"').join(', ')}',
    );
    _linkSnack(context, AppStrings.headingNotFoundTitle);
    return;
  }
  link.jumpToHeading(entry.line);
}

void _linkSnack(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// The one-line link outcome for the logs.
String describeResolved(ResolveResult resolved) {
  return switch (resolved) {
    ExternalLink(:final url) => 'ExternalLink($url)',
    LocalAnchor(:final heading) => 'LocalAnchor(#$heading)',
    ResolvedNote(:final note) => 'ResolvedNote(${note.path})',
    AmbiguousNote(:final candidates) =>
      'AmbiguousNote(${candidates.length} candidates)',
    UnresolvedNote(:final target) => 'UnresolvedNote("$target")',
  };
}
