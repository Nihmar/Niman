import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/features/feature_presets_strip.dart';
import 'package:niman/src/ui/features/feature_row.dart';
import 'package:niman/src/ui/features/feature_sections.dart';
import 'package:niman/src/ui/features/features_editor.dart';
import 'package:niman/src/ui/features/features_host.dart';
import 'package:niman/src/ui/features/features_introduction_card.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// Settings → Library → Features (#1109): what this library uses.
///
/// The presets sit pinned over the list, the switches in cards under their
/// section, a child greyed with *Needs …* while its parent is off, and
/// **Show this introduction again** at the foot. A switch is written as it
/// is flipped; one that turned Todo or Calendar off says how many reminders
/// it cancelled, with **Undo**.
///
/// With an introduction up — the first normal open of a library — leaving
/// the screen records that it was seen: *Done*, back, `Esc` and closing the
/// window all end here, in the state's dispose, and nothing is written
/// while the screen is open, so a kill shows it again.
final class SettingsFeaturesScreen extends StatefulWidget {
  /// The screen for [controller]'s library; [host] carries what the shell
  /// around it gives (the reminder count, the introduction to open with).
  const new({
    required this.controller,
    this.host = const FeaturesHost(),
    this.highlight,
    super.key,
  });

  /// The session whose features the screen edits.
  final LibrarySession controller;

  /// What the shell around the screen gives it.
  final FeaturesHost host;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  State<SettingsFeaturesScreen> createState() => _SettingsFeaturesScreenState();
}

final class _SettingsFeaturesScreenState extends State<SettingsFeaturesScreen> {
  late final FeaturesEditor _editor = FeaturesEditor(
    session: widget.controller,
    featureReconcile: widget.host.featureReconcile,
    onCancelled: _sayCancelled,
  );

  /// The card on screen now: the introduction the screen opened with, then
  /// whatever *Show this introduction again* asked for.
  late FeaturesIntroduction _card = widget.host.introduction;

  /// Whether leaving records that the introduction was seen: only for a
  /// screen the introduction opened. A widget's *Open Features*, the
  /// palette and the Navigation link open it for its own sake and leave
  /// the flag as it was.
  late final bool _recordsLeaving =
      widget.host.introduction != FeaturesIntroduction.none;

  @override
  void dispose() {
    if (_recordsLeaving) {
      unawaited(widget.controller.markFeaturesReviewed());
    }
    super.dispose();
  }

  /// Says how many reminders a switch cancelled, and offers to take it back.
  void _sayCancelled(int cancelled, Future<void> Function() undo) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('features-reminders-snackbar'),
          content: Text(AppStrings.featuresRemindersCancelled(cancelled)),
          action: SnackBarAction(
            label: AppStrings.actionUndo,
            onPressed: () => unawaited(undo()),
          ),
        ),
      );
  }

  void _pick(FeaturePreset preset) =>
      unawaited(_editor.edit((features) => features.withPreset(preset)));

  /// **Done**: leaves the screen, which is what records the introduction.
  /// The window the settings float in, or the page they are on a phone,
  /// is the root navigator's top route.
  void _done() => Navigator.of(context, rootNavigator: true).maybePop();

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.featuresTitle,
      controller: widget.controller,
      library: true,
      highlight: widget.highlight,
      body: ValueListenableBuilder<Features>(
        valueListenable: widget.controller.features,
        builder: (context, features, _) => _body(context, features),
      ),
    );
  }

  Widget _body(BuildContext context, Features features) {
    final theme = Theme.of(context);
    final card = _card;
    final created = card == FeaturesIntroduction.created;
    Widget introduction() => FeaturesIntroductionCard(
      introduction: card,
      features: features,
      onPick: _pick,
      onDone: _done,
    );
    return Column(
      children: [
        // Pinned, so the presets stay in reach while the list scrolls. A
        // library being created has the cards in the introduction instead.
        if (card == FeaturesIntroduction.existing) introduction(),
        if (!created) FeaturePresetsStrip(features: features, onPick: _pick),
        Expanded(
          child: ListView(
            key: const Key('features-list'),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  AppStrings.featuresDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (created) introduction(),
              for (final section in featureSections()) ...[
                SettingsSection(section.title),
                _Cards(
                  children: [
                    for (final feature in section.features)
                      FeatureRow(
                        feature: feature,
                        features: features,
                        onChanged: (on) => unawaited(
                          _editor.edit((f) => f.withSwitch(feature, on: on)),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SettingsRowFrame(
                key: const Key('features-show-introduction'),
                title: AppStrings.featuresShowIntroTitle,
                description: AppStrings.featuresShowIntroBody,
                onTap: () =>
                    setState(() => _card = FeaturesIntroduction.existing),
                control: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _card = FeaturesIntroduction.existing),
                    child: Text(AppStrings.featuresShowIntroAction),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The rows of one section, in a card, a line between them.
final class _Cards extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: settingsRowMaxWidth + 32),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
