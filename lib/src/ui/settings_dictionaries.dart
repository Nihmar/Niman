import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/dictionaries/dictionary_notes.dart';
import 'package:niman/src/ui/dictionaries/dictionary_pack_list.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';

/// The Dictionaries area of the settings (#1382): the dictionaries Look up
/// reads, one per language, downloaded to the device, and the notes on how
/// they are used. The same page on the desktop and the phone; app-wide,
/// like the packs it lists, which live in the app's data folder and not in
/// a library.
///
/// The personal dictionary stays under Spelling: that one is the words a
/// writer teaches the spell checker, this is the meanings.
final class SettingsDictionariesScreen extends ConsumerStatefulWidget {
  /// Creates the screen; [controller] is the session the area frame reads.
  const new({required this.controller, this.highlight, super.key});

  /// The session the area frame reads.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  ConsumerState<SettingsDictionariesScreen> createState() =>
      _SettingsDictionariesScreenState();
}

final class _SettingsDictionariesScreenState
    extends ConsumerState<SettingsDictionariesScreen> {
  @override
  void initState() {
    super.initState();
    // The folder may have changed since the last look (a pack deleted by
    // hand): reading it again is a listing on an isolate.
    unawaited(ref.read(dictionaryInstallationProvider).rescan());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final installation = ref.watch(dictionaryInstallationProvider);
    return SettingsAreaShell(
      title: AppStrings.settingsSectionDictionaries,
      controller: widget.controller,
      highlight: widget.highlight,
      body: ListenableBuilder(
        listenable: installation,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // What the search lands on for the area itself.
            HighlightRow(
              key: SettingsKeys.dictionaries,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  AppStrings.dictionariesIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            DictionaryPackList(installation: installation),
            const DictionaryNotes(),
          ],
        ),
      ),
    );
  }
}
