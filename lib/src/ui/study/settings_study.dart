import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The choices of **New cards per day**: none, a few, the default, more.
const List<int> newCardsPerDayChoices = [0, 5, 10, 20, 30, 50, 100];

/// Settings → Library → Study (#533): how many new cards a deck shows a
/// day, and **Reset all reviews**. Library settings: they travel with the
/// library, as the reviews do.
final class SettingsStudyScreen extends StatefulWidget {
  /// The area for [controller]'s library; [highlight] is the row the
  /// settings search landed on.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row to flash, or null.
  final Key? highlight;

  @override
  State<SettingsStudyScreen> createState() => _SettingsStudyScreenState();
}

final class _SettingsStudyScreenState extends State<SettingsStudyScreen> {
  int _newPerDay = defaultNewCardsPerDay;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final perDay = await widget.controller.newCardsPerDay;
    if (mounted) setState(() => _newPerDay = perDay);
  }

  Future<void> _chooseNewPerDay() async {
    final count = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('new-cards-per-day-dialog'),
      title: AppStrings.settingsNewCardsPerDay,
      subtitle: AppStrings.settingsNewCardsPerDayHint,
      current: _newPerDay,
      options: [
        // A number typed into the file keeps its place among the choices.
        for (final choice in {
          ...newCardsPerDayChoices,
          _newPerDay,
        }.toList()..sort())
          SettingsOption(choice, '$choice'),
      ],
    );
    if (count == null) return;
    await widget.controller.setNewCardsPerDay(count);
    // The counts of Study and of the decks follow the setting.
    widget.controller.notify();
    if (mounted) setState(() => _newPerDay = count);
  }

  Future<void> _resetAll() async {
    final root = widget.controller.root;
    if (root == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.resetAllReviewsTitle),
        content: Text(AppStrings.resetAllReviewsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('reset-all-reviews-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.flashcardsResetConfirm),
          ),
        ],
      ),
    );
    if (sure ?? false) await ReviewStore(root).resetAll();
  }

  @override
  Widget build(BuildContext context) => SettingsAreaShell(
    title: AppStrings.tabStudy,
    controller: widget.controller,
    library: true,
    highlight: widget.highlight,
    body: ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        HighlightRow(
          key: SettingsKeys.newCardsPerDay,
          child: SettingsValueRow(
            title: AppStrings.settingsNewCardsPerDay,
            subtitle: AppStrings.settingsNewCardsPerDayHint,
            value: '$_newPerDay',
            onTap: _chooseNewPerDay,
          ),
        ),
        HighlightRow(
          key: SettingsKeys.resetAllReviews,
          child: SettingsValueRow(
            title: AppStrings.settingsResetAllReviews,
            onTap: _resetAll,
          ),
        ),
      ],
    ),
  );
}
