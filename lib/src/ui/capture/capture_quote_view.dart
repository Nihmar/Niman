/// The capture sheet's Quote tab (#531): text selected in the browser,
/// with the page it came from, appended to a note or made a new one.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/capture/shared_page.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The quote, and where it goes.
final class CaptureQuoteView extends StatelessWidget {
  /// The tab over [quote]: appended to [appendTo] when [append], else a
  /// new note in [folder].
  const new({
    required this.quote,
    required this.append,
    required this.appendTo,
    required this.folder,
    required this.onAppend,
    required this.onNewNote,
    required this.onPickNote,
    required this.onPickFolder,
    super.key,
  });

  /// What was shared.
  final SharedQuote quote;

  /// Whether the quote is appended rather than made a note.
  final bool append;

  /// The note it is appended to, library-relative; null before one is
  /// picked.
  final String? appendTo;

  /// The folder a new note goes in.
  final String folder;

  /// Chooses to append.
  final VoidCallback onAppend;

  /// Chooses a new note.
  final VoidCallback onNewNote;

  /// Asks for the note to append to.
  final VoidCallback onPickNote;

  /// Asks for the new note's folder.
  final VoidCallback onPickFolder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final note = appendTo;
    final noteFolder = note == null ? '' : p.posix.dirname(note);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('capture-quote-text'),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote.quote,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  '— ${quote.title ?? quote.pageUrl.host}',
                  if (quote.title != null) quote.pageUrl.host,
                ].join(' · '),
                style: muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _Choice(
          key: const Key('capture-quote-append'),
          on: append,
          title: AppStrings.captureAppendToNote,
          subtitle: note == null
              ? null
              : [
                  p.posix.basenameWithoutExtension(note),
                  if (noteFolder != '.') noteFolder,
                ].join(' · '),
          onTap: note == null ? onPickNote : onAppend,
          onPick: onPickNote,
        ),
        _Choice(
          key: const Key('capture-quote-new'),
          on: !append,
          title: AppStrings.captureNewNoteIn(folder.isEmpty ? '/' : folder),
          onTap: onNewNote,
          onPick: onPickFolder,
        ),
      ],
    );
  }
}

/// One of the two places the quote goes: a tap chooses it, the chevron
/// changes the note or the folder.
final class _Choice extends StatelessWidget {
  const new({
    required this.on,
    required this.title,
    required this.onTap,
    required this.onPick,
    this.subtitle,
    super.key,
  });

  final bool on;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    selected: on,
    // Filled when chosen, outline when not: the icon says the state.
    leading: Icon(on ? Icons.radio_button_checked : Icons.radio_button_off),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: IconButton(
      icon: const Icon(Icons.chevron_right),
      onPressed: onPick,
    ),
    onTap: onTap,
  );
}
