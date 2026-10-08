/// The capture dialog once the page is read (#531): its title, the folder
/// and the tags the note goes with, a preview of it, whether its pictures
/// are downloaded, its frontmatter, and what was left out of the page.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/ui/capture/capture_tags.dart';
import 'package:niman/src/ui/strings.dart';

/// What the user chooses before saving.
final class CaptureChoices {
  /// The choices for [reading]: its own title, [folder], the [tags]
  /// given, and its pictures downloaded.
  new({required WebReading reading, required this.folder, required this.tags})
    : title = TextEditingController(text: reading.page.title);

  /// The note's title.
  final TextEditingController title;

  /// The folder the note goes in, library-relative ('' is the root).
  String folder;

  /// The note's tags.
  final List<String> tags;

  /// Whether the article's pictures are downloaded.
  bool downloadPictures = true;

  /// Releases the title's controller.
  void dispose() => title.dispose();
}

/// The form.
final class CaptureReadyForm extends StatelessWidget {
  /// The form over [choices] for [reading], captured on [captured].
  const new({
    required this.reading,
    required this.choices,
    required this.captured,
    required this.attachmentsFolder,
    required this.onPickFolder,
    required this.onChanged,
    super.key,
  });

  /// The page read.
  final WebReading reading;

  /// What the user has chosen so far.
  final CaptureChoices choices;

  /// When the note is captured, for its frontmatter.
  final DateTime captured;

  /// Where the pictures go.
  final String attachmentsFolder;

  /// Asks for another folder.
  final VoidCallback onPickFolder;

  /// Called after a choice changed, to draw it.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final heading = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final page = reading.page;
    final removed = page.removed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          !page.readable
              ? AppStrings.captureNoArticle
              : reading.ranBrowser
              ? AppStrings.captureReadInBrowser
              : page.url.host,
          style: muted,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('capture-title'),
          controller: choices.title,
          decoration: InputDecoration(labelText: AppStrings.captureTitleField),
        ),
        const SizedBox(height: 8),
        ListTile(
          key: const Key('capture-folder'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: Text(AppStrings.captureFolderField),
          subtitle: Text(choices.folder.isEmpty ? '/' : choices.folder),
          trailing: const Icon(Icons.chevron_right),
          onTap: onPickFolder,
        ),
        CaptureTags(tags: choices.tags, onChanged: onChanged),
        const SizedBox(height: 12),
        Text(AppStrings.capturePreview, style: heading),
        const SizedBox(height: 4),
        _Preview(reading: reading, title: choices.title),
        if (reading.pictures.isNotEmpty)
          CheckboxListTile(
            key: const Key('capture-pictures'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: choices.downloadPictures,
            onChanged: (value) {
              choices.downloadPictures = value ?? true;
              onChanged();
            },
            title: Text(
              AppStrings.captureDownloadPictures(
                reading.pictures.length,
                attachmentsFolder,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(AppStrings.cheatFrontmatter, style: heading),
        const SizedBox(height: 4),
        SelectableText(
          captureFrontmatter(page, captured, choices.tags).trim(),
          key: const Key('capture-frontmatter'),
          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
        if (page.readable) ...[
          const SizedBox(height: 12),
          Text(AppStrings.captureRemoved, style: heading),
          const SizedBox(height: 4),
          for (final line in [
            if (removed.scripts + removed.styles > 0)
              AppStrings.captureRemovedCode(removed.scripts, removed.styles),
            if (removed.menu) AppStrings.captureRemovedMenu,
            if (removed.banner) AppStrings.captureRemovedBanner,
            if (removed.wordsAround > 0)
              AppStrings.captureRemovedAround(removed.wordsAround),
          ])
            Text('· $line', style: muted),
        ],
      ],
    );
  }
}

/// What the note will be, at a glance: its title, author and date, how
/// long, and its first words.
final class _Preview extends StatelessWidget {
  const new({required this.reading, required this.title});

  final WebReading reading;
  final TextEditingController title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = reading.page;
    final byline = [?page.byline, ?page.publishedTime].join(' · ');
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (page.readable)
              Text(
                AppStrings.captureWordsMinutes(
                  page.words,
                  (page.words / 200).ceil(),
                ),
                style: theme.textTheme.labelSmall,
              ),
            ListenableBuilder(
              listenable: title,
              builder: (context, _) =>
                  Text(title.text, style: theme.textTheme.titleMedium),
            ),
            if (byline.isNotEmpty)
              Text(byline, style: theme.textTheme.bodySmall),
            if (page.description case final description?)
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
