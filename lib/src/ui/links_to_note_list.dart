import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/ui/links_to_note_controller.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The notes that link to a note (#842), one row each: the note's name, the
/// folder it is in dimmed, and the line it says the link on.
///
/// The rows come from [controller] (one indexed lookup); the line of each is
/// read as the row is drawn, off the UI isolate and once for each revision of
/// the note that holds it, so a list that is scrolled through reads the notes
/// it shows and no others. A tap opens the note that holds the link.
final class LinksToNoteList extends StatelessWidget {
  /// The rows of [controller]; [onOpenNote] opens the note at a path.
  const new({
    required this.controller,
    required this.onOpenNote,
    this.shrinkWrap = false,
    super.key,
  });

  /// Who links to the note.
  final LinksToNoteController controller;

  /// Opens the note at a library-relative path.
  final ValueChanged<String> onOpenNote;

  /// Whether the list is as tall as its rows (inside the note view's
  /// section, which bounds it) rather than as tall as the room it is given.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        // No library, or a note outside one: nothing links to it.
        if (controller.source == null || controller.path == null) {
          return const SizedBox.shrink();
        }
        final referrers = controller.referrers;
        if (referrers == null) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (referrers.items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppStrings.linksToNoteEmpty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final path = controller.path!;
        final source = controller.source!;
        return ListView.builder(
          key: const Key('links-to-note'),
          shrinkWrap: shrinkWrap,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: referrers.items.length,
          itemBuilder: (context, index) {
            final referrer = referrers.items[index];
            return _ReferrerRow(
              // A row is a note at a revision of the list: it asks again
              // for another note's, and keeps its answer while scrolled.
              key: ValueKey('$path|${referrer.path}'),
              referrer: referrer,
              read: () => source.mentionIn(referrer.path, path),
              onTap: () => onOpenNote(referrer.path),
            );
          },
        );
      },
    );
  }
}

/// One referrer: its name, its folder, and — once read — the line it links
/// on.
final class _ReferrerRow extends StatefulWidget {
  const new({
    required this.referrer,
    required this.read,
    required this.onTap,
    super.key,
  });

  final Referrer referrer;

  /// Reads what the referrer says: called once, when the row is built.
  final Future<Mention> Function() read;
  final VoidCallback onTap;

  @override
  State<_ReferrerRow> createState() => _ReferrerRowState();
}

final class _ReferrerRowState extends State<_ReferrerRow> {
  Mention? _mention;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    final mention = await widget.read();
    if (!mounted) return;
    setState(() => _mention = mention);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final path = widget.referrer.path;
    final file = p.posix.basename(path);
    final name = file.toLowerCase().endsWith('.md')
        ? file.substring(0, file.length - 3)
        : file;
    final folder = p.posix.dirname(path);
    final mention = _mention;
    return InkWell(
      key: Key('links-to-note-row-$path'),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (mention != null && mention.embed)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      key: Key('links-to-note-embed-$path'),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        AppStrings.linksToNoteEmbed,
                        style: muted?.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                const Spacer(),
                if (folder != '.')
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        folder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ),
                  ),
              ],
            ),
            if (mention != null && mention.context.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  mention.context,
                  key: Key('links-to-note-context-$path'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
