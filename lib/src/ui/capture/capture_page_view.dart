/// The capture sheet's Page tab (#531): the address when the sheet is
/// New's, the note's title, its folder, its tags and the choice to
/// download its pictures.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/capture/capture_tags.dart';
import 'package:niman/src/ui/strings.dart';

/// The page, and the note it becomes.
final class CapturePageView extends StatelessWidget {
  /// The tab; [address] is null when the page was shared.
  const new({
    required this.title,
    required this.folder,
    required this.tags,
    required this.attachmentsFolder,
    required this.downloadPictures,
    required this.onAddressChanged,
    required this.onAddressSubmitted,
    required this.onTitleChanged,
    required this.onPickFolder,
    required this.onTagsChanged,
    required this.onDownloadPictures,
    this.address,
    this.autofocus = false,
    this.fromClipboard = false,
    this.host,
    this.error,
    this.pictures,
    super.key,
  });

  /// The address typed, when the sheet is New's.
  final TextEditingController? address;

  /// Whether the address field takes the focus.
  final bool autofocus;

  /// Whether the address came from the clipboard.
  final bool fromClipboard;

  /// The note's title.
  final TextEditingController title;

  /// The page's host, once it is being read.
  final String? host;

  /// Why the page cannot be had, or the address is not a page's.
  final String? error;

  /// The folder the note goes in ('' is the root).
  final String folder;

  /// The note's tags.
  final List<String> tags;

  /// The library's attachments folder.
  final String attachmentsFolder;

  /// How many pictures the page has; null before it has been read.
  final int? pictures;

  /// Whether they are downloaded.
  final bool downloadPictures;

  /// The address was edited.
  final VoidCallback onAddressChanged;

  /// The address was submitted.
  final VoidCallback onAddressSubmitted;

  /// The title was edited.
  final VoidCallback onTitleChanged;

  /// Asks for another folder.
  final VoidCallback onPickFolder;

  /// A tag was added or removed.
  final VoidCallback onTagsChanged;

  /// The pictures' choice changed.
  final ValueChanged<bool> onDownloadPictures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pictures = this.pictures;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (address case final address?) ...[
          TextField(
            key: const Key('capture-sheet-address'),
            controller: address,
            autofocus: autofocus,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: AppStrings.capturePageField,
              hintText: 'https://',
              helperText: fromClipboard
                  ? AppStrings.captureFromClipboard
                  : null,
            ),
            onChanged: (_) => onAddressChanged(),
            onSubmitted: (_) => onAddressSubmitted(),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          key: const Key('capture-sheet-title'),
          controller: title,
          decoration: InputDecoration(
            labelText: AppStrings.captureTitleField,
            helperText: host,
          ),
          onChanged: (_) => onTitleChanged(),
        ),
        if (error case final error?) ...[
          const SizedBox(height: 8),
          Text(
            error,
            key: const Key('capture-sheet-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 4),
        ListTile(
          key: const Key('capture-sheet-folder'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: Text(folder.isEmpty ? '/' : folder),
          trailing: const Icon(Icons.chevron_right),
          onTap: onPickFolder,
        ),
        CaptureTags(tags: tags, onChanged: onTagsChanged),
        // Before the page has said how many pictures it holds, the choice
        // is offered all the same; a page with none keeps the row,
        // disabled, so Save does not move under the thumb.
        CheckboxListTile(
          key: const Key('capture-sheet-pictures'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: downloadPictures && pictures != 0,
          onChanged: pictures == 0
              ? null
              : (value) => onDownloadPictures(value!),
          title: Text(
            pictures == null
                ? AppStrings.captureDownloadPicturesTo(attachmentsFolder)
                : AppStrings.captureDownloadPictures(
                    pictures,
                    attachmentsFolder,
                  ),
          ),
        ),
      ],
    );
  }
}
