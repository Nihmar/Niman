import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_slider_row.dart';
import 'package:niman/src/ui/strings.dart';

/// The Editor area's column rows (issue #171): whether a note is held to
/// a readable line length, and how wide that column is.
final class SettingsEditorColumn extends StatelessWidget {
  /// Creates the rows for the current [readableLineLength] and
  /// [noteColumnWidth].
  const new({
    required this.readableLineLength,
    required this.noteColumnWidth,
    required this.onReadableLineLength,
    required this.onNoteColumnWidth,
    super.key,
  });

  /// Whether a note is held to a column.
  final bool readableLineLength;

  /// How wide the column is.
  final double noteColumnWidth;

  /// Persists the readable-line-length switch.
  final ValueChanged<bool> onReadableLineLength;

  /// Persists the column width chosen, or slid to.
  final ValueChanged<double> onNoteColumnWidth;

  /// Steps of 5% of the default column between the narrowest and the
  /// widest: the bounds are whole multiples of it, so every stop reads as
  /// a round percentage.
  static final int _columnWidthSteps =
      ((maxNoteColumnWidth - minNoteColumnWidth) /
              (defaultNoteColumnWidth * 0.05))
          .round();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Every platform has it (#171): a phone is narrower than any
        // column, so there it only starts to count on a tablet or in
        // landscape — which is the reason not to hide it.
        HighlightRow(
          key: SettingsKeys.readableLineLength,
          child: SettingsSwitchRow(
            title: AppStrings.readableLineLengthTitle,
            description: AppStrings.readableLineLengthSubtitle,
            value: readableLineLength,
            onChanged: onReadableLineLength,
          ),
        ),
        HighlightRow(
          key: SettingsKeys.noteColumnWidth,
          child: pointerDense(Theme.of(context))
              ? SettingsSliderRow(
                  sliderKey: const Key('note-column-width-slider'),
                  title: AppStrings.noteColumnWidthTitle,
                  subtitle: AppStrings.noteColumnWidthSubtitle,
                  value: noteColumnWidth,
                  min: minNoteColumnWidth,
                  max: maxNoteColumnWidth,
                  divisions: _columnWidthSteps,
                  format: AppStrings.noteColumnWidthValue,
                  enabled: readableLineLength,
                  onChanged: onNoteColumnWidth,
                )
              : SettingsValueRow(
                  title: AppStrings.noteColumnWidthTitle,
                  subtitle: AppStrings.noteColumnWidthSubtitle,
                  value: AppStrings.noteColumnWidthValue(noteColumnWidth),
                  enabled: readableLineLength,
                  onTap: () => unawaited(_chooseNoteColumnWidth(context)),
                ),
        ),
      ],
    );
  }

  /// Asks how wide the note column is.
  Future<void> _chooseNoteColumnWidth(BuildContext context) async {
    final width = await showSettingsSlider(
      context,
      dialogKey: const Key('note-column-width-dialog'),
      sliderKey: const Key('note-column-width-slider'),
      title: AppStrings.noteColumnWidthTitle,
      subtitle: AppStrings.noteColumnWidthSubtitle,
      current: noteColumnWidth,
      min: minNoteColumnWidth,
      max: maxNoteColumnWidth,
      divisions: _columnWidthSteps,
      format: AppStrings.noteColumnWidthValue,
    );
    if (width != null) onNoteColumnWidth(width);
  }
}
