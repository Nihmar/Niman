import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_slider_row.dart';
import 'package:niman/src/ui/strings.dart';

/// The Editor area's text rows: how large the note text is, the face the
/// source editor is set in (#259), and the spaces added per indent level.
final class SettingsEditorText extends StatelessWidget {
  /// Creates the rows for the current [noteTextScale], [sourceFont] and
  /// [indentWidth].
  const new({
    required this.noteTextScale,
    required this.sourceFont,
    required this.indentWidth,
    required this.onNoteTextScale,
    required this.onSourceFont,
    required this.onIndentWidth,
    super.key,
  });

  /// How large the note text is, in both panes.
  final double noteTextScale;

  /// The face the source editor is set in.
  final SourceFont sourceFont;

  /// The spaces added per indent level.
  final int indentWidth;

  /// Persists the text size chosen, or slid to.
  final ValueChanged<double> onNoteTextScale;

  /// Persists the source face chosen.
  final ValueChanged<SourceFont> onSourceFont;

  /// Persists the indent width chosen.
  final ValueChanged<int> onIndentWidth;

  /// Steps of 5% between [minTextScale] and [maxTextScale]: fine enough
  /// to land on a size that fits, coarse enough to be hit on a phone.
  static final int _textScaleSteps = ((maxTextScale - minTextScale) * 20)
      .round();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightRow(
          key: SettingsKeys.noteTextScale,
          // A desktop's slider sits in the row (#712).
          child: pointerDense(Theme.of(context))
              ? SettingsSliderRow(
                  sliderKey: const Key('note-text-scale-slider'),
                  title: AppStrings.noteTextScaleTitle,
                  subtitle: AppStrings.noteTextScaleSubtitle,
                  value: noteTextScale,
                  min: minTextScale,
                  max: maxTextScale,
                  divisions: _textScaleSteps,
                  format: AppStrings.textScaleValue,
                  onChanged: onNoteTextScale,
                )
              : SettingsValueRow(
                  title: AppStrings.noteTextScaleTitle,
                  subtitle: AppStrings.noteTextScaleSubtitle,
                  value: AppStrings.textScaleValue(noteTextScale),
                  onTap: () => unawaited(_chooseNoteTextScale(context)),
                ),
        ),
        // Beside the note text size: both decide how the note reads in the
        // editor, and this one only the source pane (#259).
        HighlightRow(
          key: SettingsKeys.sourceFont,
          child: SettingsValueRow(
            title: AppStrings.sourceFontTitle,
            subtitle: AppStrings.sourceFontSubtitle,
            value: switch (sourceFont) {
              SourceFont.monospace => AppStrings.sourceFontMonospace,
              SourceFont.sansSerif => AppStrings.sourceFontSansSerif,
              SourceFont.serif => AppStrings.sourceFontSerif,
            },
            onTap: () => unawaited(_chooseSourceFont(context)),
          ),
        ),
        HighlightRow(
          key: SettingsKeys.indentWidth,
          child: SettingsValueRow(
            title: AppStrings.indentWidthTitle,
            subtitle: AppStrings.indentWidthSubtitle,
            value: AppStrings.indentWidthValue(indentWidth),
            onTap: () => unawaited(_chooseIndentWidth(context)),
          ),
        ),
      ],
    );
  }

  /// Asks how large the note text should be, in both panes.
  Future<void> _chooseNoteTextScale(BuildContext context) async {
    final scale = await showSettingsSlider(
      context,
      dialogKey: const Key('note-text-scale-dialog'),
      sliderKey: const Key('note-text-scale-slider'),
      title: AppStrings.noteTextScaleTitle,
      subtitle: AppStrings.noteTextScaleSubtitle,
      current: noteTextScale,
      min: minTextScale,
      max: maxTextScale,
      divisions: _textScaleSteps,
      format: AppStrings.textScaleValue,
    );
    if (scale != null) onNoteTextScale(scale);
  }

  /// Asks which face the source editor is set in (issue #259). The read
  /// view and `live` keep the note's own whatever this says.
  Future<void> _chooseSourceFont(BuildContext context) async {
    final font = await showSettingsChoice<SourceFont>(
      context,
      dialogKey: const Key('source-font-dialog'),
      title: AppStrings.sourceFontTitle,
      subtitle: AppStrings.sourceFontSubtitle,
      current: sourceFont,
      options: [
        SettingsOption(SourceFont.monospace, AppStrings.sourceFontMonospace),
        SettingsOption(SourceFont.sansSerif, AppStrings.sourceFontSansSerif),
        SettingsOption(SourceFont.serif, AppStrings.sourceFontSerif),
      ],
    );
    if (font != null) onSourceFont(font);
  }

  /// Asks for the spaces added per indent level.
  Future<void> _chooseIndentWidth(BuildContext context) async {
    final width = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('indent-width-dialog'),
      title: AppStrings.indentWidthTitle,
      subtitle: AppStrings.indentWidthSubtitle,
      current: indentWidth,
      options: [
        for (final spaces in const [2, 4, 6, 8])
          SettingsOption(spaces, AppStrings.indentWidthValue(spaces)),
      ],
    );
    if (width != null) onIndentWidth(width);
  }
}
