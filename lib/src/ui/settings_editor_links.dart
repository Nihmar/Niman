import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Editor area's link rows: the format the link button inserts, what
/// a rename or a move does to the links pointing at what moved (#848),
/// and where new notes and folders go (#850).
final class SettingsEditorLinks extends StatelessWidget {
  /// Creates the rows for the current [linkType], [linkUpdate] and
  /// [newItemLocation].
  const new({
    required this.linkType,
    required this.linkUpdate,
    required this.newItemLocation,
    required this.onLinkType,
    required this.onLinkUpdate,
    required this.onNewItemLocation,
    super.key,
  });

  /// The link format the editor's link button inserts.
  final LinkType linkType;

  /// What a rename or a move does to the links pointing at what moved.
  final LinkUpdate linkUpdate;

  /// Where new notes and folders go.
  final NewItemLocation newItemLocation;

  /// Persists the link format chosen.
  final ValueChanged<LinkType> onLinkType;

  /// Persists the link update chosen.
  final ValueChanged<LinkUpdate> onLinkUpdate;

  /// Persists the new items' place chosen.
  final ValueChanged<NewItemLocation> onNewItemLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightRow(
          key: SettingsKeys.linkType,
          child: SettingsValueRow(
            title: AppStrings.linkTypeTitle,
            subtitle: AppStrings.linkTypeSubtitle,
            value: switch (linkType) {
              LinkType.wikilink => AppStrings.linkTypeWikilink,
              LinkType.markdown => AppStrings.linkTypeMarkdown,
            },
            onTap: () => unawaited(_chooseLinkType(context)),
          ),
        ),
        // Next to the link format: they decide what a link does — what
        // it inserts, what happens to it when its target moves (#848),
        // where a new note lands (#850).
        HighlightRow(
          key: SettingsKeys.linkUpdate,
          child: SettingsValueRow(
            title: AppStrings.linkUpdateTitle,
            subtitle: AppStrings.linkUpdateSubtitle,
            value: switch (linkUpdate) {
              LinkUpdate.automatic => AppStrings.linkUpdateAutomatic,
              LinkUpdate.ask => AppStrings.linkUpdateAsk,
              LinkUpdate.never => AppStrings.linkUpdateNever,
            },
            onTap: () => unawaited(_chooseLinkUpdate(context)),
          ),
        ),
        // The one rule for where every new note and folder lands (#850),
        // the note a dead link creates (issue #78) among them.
        HighlightRow(
          key: SettingsKeys.newItemLocation,
          child: SettingsValueRow(
            title: AppStrings.newItemLocationTitle,
            value: switch (newItemLocation) {
              NewItemLocation.libraryRoot => AppStrings.newItemLocationRoot,
              NewItemLocation.openNoteFolder =>
                AppStrings.newItemLocationOpenNote,
            },
            onTap: () => unawaited(_chooseNewItemLocation(context)),
          ),
        ),
      ],
    );
  }

  /// Asks for the link format the editor's link button inserts.
  Future<void> _chooseLinkType(BuildContext context) async {
    final type = await showSettingsChoice<LinkType>(
      context,
      dialogKey: const Key('link-type-dialog'),
      title: AppStrings.linkTypeTitle,
      subtitle: AppStrings.linkTypeSubtitle,
      current: linkType,
      options: [
        SettingsOption(LinkType.wikilink, AppStrings.linkTypeWikilink),
        SettingsOption(LinkType.markdown, AppStrings.linkTypeMarkdown),
      ],
    );
    if (type != null) onLinkType(type);
  }

  /// Asks what a rename or a move does to the links pointing at what
  /// moved (#848).
  Future<void> _chooseLinkUpdate(BuildContext context) async {
    final mode = await showSettingsChoice<LinkUpdate>(
      context,
      dialogKey: const Key('link-update-dialog'),
      title: AppStrings.linkUpdateTitle,
      subtitle: AppStrings.linkUpdateSubtitle,
      current: linkUpdate,
      options: [
        SettingsOption(LinkUpdate.automatic, AppStrings.linkUpdateAutomatic),
        SettingsOption(LinkUpdate.ask, AppStrings.linkUpdateAsk),
        SettingsOption(LinkUpdate.never, AppStrings.linkUpdateNever),
      ],
    );
    if (mode != null) onLinkUpdate(mode);
  }

  /// Asks where new notes and folders go (#850).
  Future<void> _chooseNewItemLocation(BuildContext context) async {
    final location = await showSettingsChoice<NewItemLocation>(
      context,
      dialogKey: const Key('new-item-location-dialog'),
      title: AppStrings.newItemLocationTitle,
      current: newItemLocation,
      options: [
        SettingsOption(
          NewItemLocation.libraryRoot,
          AppStrings.newItemLocationRoot,
        ),
        SettingsOption(
          NewItemLocation.openNoteFolder,
          AppStrings.newItemLocationOpenNote,
        ),
      ],
    );
    if (location != null) onNewItemLocation(location);
  }
}
