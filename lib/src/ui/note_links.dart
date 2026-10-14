/// Following a link out of a note (issue #100, split out of
/// `note_view.dart`): a Markdown href or a wikilink, resolved against
/// the library and then opened, jumped to, launched, disambiguated, or
/// offered as a note that does not exist yet.
///
/// The note view keeps the state; what it passes here is
/// [NoteLinkTargets], the explicit list of what following one link
/// needs — the same bargain `shell_layout.dart` struck with the shell.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/anchor.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/dead_link_flow.dart';
import 'package:niman/src/ui/link_snack.dart';
import 'package:niman/src/ui/note_link_targets.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

export 'package:niman/src/ui/note_link_targets.dart';

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
  // A link with no target (`[x]()`) goes nowhere, in the preview as on a
  // slide (#674): resolved, it offered to create a note named nothing.
  if (source == null || href.trim().isEmpty) return;
  final resolved = await source.resolveMarkdown(
    href,
    from: link.notePathInLibrary,
  );
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
  final heading = ref.fragment == null ? '-' : '"${ref.fragment}"';
  final src = source == null ? 'not loaded' : 'ready';
  log.debug(
    'wikilink tap in ${p.basename(link.notePath)}: '
    'target="${ref.target}" alias=$alias heading=$heading (source $src)',
  );
  if (ref.target.isEmpty) {
    final heading = ref.fragment;
    if (heading == null) {
      log.debug('wikilink: empty target and no heading — snackbar');
      return linkSnack(context, AppStrings.unresolvedLinkTitle);
    }
    log.debug('wikilink: local anchor — jump to "$heading"');
    await jumpToAnchor(context, heading, link);
    return;
  }
  if (source == null) return;
  // The documented form: `[[target]]`, `[[target#heading]]`,
  // `[[target|alias]]` — the first part is the target.
  final from = link.notePathInLibrary;
  var resolved = await source.resolveWiki(ref.target, from: from);
  final outcome = describeResolved(resolved);
  log.debug('wikilink target "${ref.target}" -> $outcome');
  var anchor = ref.fragment;
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
      final swapped = await source.resolveWiki(aliasTarget.trim(), from: from);
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
        if (context.mounted) linkSnack(context, AppStrings.openLinkFailed);
      }
    case LocalAnchor(:final heading):
      log.debug('link outcome: jump to local anchor "$heading"');
      await jumpToAnchor(context, heading, link);
    case ResolvedNote(:final note, :final heading):
      await _openNoteResult(context, note, heading, link);
    case AmbiguousNote(:final candidates):
      log.debug(
        'link outcome: ${candidates.length} ambiguous candidates — '
        'picker',
      );
      await _pickAmbiguous(context, candidates, link);
    case UnresolvedNote(:final target):
      await offerDeadLink(context, target, link);
    // DeadLinkDeclined: nothing — no error, no second prompt
    // (issue #78).
  }
}

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
    if (anchor != null) await jumpToAnchor(context, anchor, link);
    return;
  }
  final open = link.onOpenNote;
  if (open == null) {
    log.debug(
      'link outcome: resolved ${note.path} but no onOpenNote — '
      'snackbar',
    );
    if (context.mounted) linkSnack(context, AppStrings.unresolvedLinkTitle);
    return;
  }
  log.debug(
    'link outcome: open ${note.path} '
    'anchor=${anchor == null ? '-' : '"$anchor"'}',
  );
  open(note.path, anchor);
}

/// Asks which of [candidates] the link means: the app's list of choices
/// ([showActionSheet]) — a menu where the pointer went down on a desktop
/// (#712), the sheet on a phone.
Future<void> _pickAmbiguous(
  BuildContext context,
  List<Note> candidates,
  NoteLinkTargets link,
) async {
  if (!context.mounted) return;
  final chosen = await showActionSheet<Note>(
    context,
    title: AppStrings.ambiguousLinkTitle,
    anchor: link.anchor,
    items: (context) => [
      for (final note in candidates)
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(note.path),
          onTap: () => Navigator.pop(context, note),
        ),
    ],
  );
  if (chosen == null || !context.mounted) return;
  await _openNoteResult(context, chosen, null, link);
}

/// Brings the note to what [fragment] names: a heading, a path of headings
/// (`A#B`, #845), or a block by its id (`^37066d`, #844).
///
/// Headings are matched by the shared slug (so `[[x#My Heading]]` and
/// `## My Heading` agree) and read by level order; a block is matched by its
/// id, literally. Also the note's own opening jump, when it was opened at an
/// anchor.
Future<void> jumpToAnchor(
  BuildContext context,
  String fragment,
  NoteLinkTargets link,
) async {
  const log = AppLogger(name: 'links');
  final anchor = parseAnchor(fragment);
  switch (anchor) {
    case null:
      return;
    case BlockIdAnchor(:final id):
      final blocks = await link.blocks?.call() ?? const <BlockAnchor>[];
      final line = blockLineOf(blocks, id);
      if (line == null) {
        log.debug(
          'block "^$id" not found among ${blocks.length} block anchor(s): '
          '${blocks.take(40).map((b) => '${b.line}:^${b.id}').join(', ')}',
        );
        if (context.mounted) {
          linkSnack(context, AppStrings.blockNotFoundTitle);
        }
        return;
      }
      link.jumpToHeading(line);
    case final HeadingAnchor heading:
      final path = heading.path;
      final line = headingLineOf(link.outline, heading);
      if (line == null) {
        // Trace the outline so a dead anchor is diagnosable from the log:
        // is the heading missing, or does its text differ from the link's?
        final entries = link.outline;
        final shown = entries.length <= 40
            ? entries
            : [...entries.take(20), ...entries.skip(entries.length - 20)];
        log.debug(
          'heading "${path.join('#')}" not found among ${entries.length} '
          'outline entr(ies): '
          '${shown.map((e) => '${e.line}:"${e.text}"').join(', ')}',
        );
        if (context.mounted) {
          linkSnack(context, AppStrings.headingNotFoundTitle);
        }
        return;
      }
      link.jumpToHeading(line);
  }
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
