/// The voice and the speed of a book read aloud (#1276), in a sheet, and
/// what is said when the device has no voice for the book's language.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/epub_read_aloud.dart';
import 'package:niman/src/ui/epub_read_aloud_engine.dart';
import 'package:niman/src/ui/strings.dart';

/// Opens the voice and speed sheet of [reading], whose language's voices
/// are [voices], from [anchor] on a pointer.
Future<void> showReadAloudVoiceSheet(
  BuildContext context, {
  required EpubReadAloud reading,
  required ReadAloudVoices voices,
  Rect? anchor,
}) => showActionSheet<void>(
  context,
  sheetKey: const Key('read-aloud-voice-sheet'),
  anchor: anchor,
  title: AppStrings.readAloudVoiceTitle,
  items: (context) => [ReadAloudVoicePanel(reading: reading, voices: voices)],
);

/// The language, the voices with a sample of each, the speed, and the way
/// to the system's settings.
final class ReadAloudVoicePanel extends StatelessWidget {
  /// The panel of [reading].
  const new({required this.reading, required this.voices, super.key});

  /// The reading the picks apply to.
  final EpubReadAloud reading;

  /// The language's voices.
  final ReadAloudVoices voices;

  /// The speed slider's steps: a quarter each, from half to twice.
  static const int rateSteps = 6;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: reading,
    builder: (context, _) {
      final theme = Theme.of(context);
      final label = theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
      final rate = AppStrings.readAloudRate(reading.rate);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.readAloudLanguage, style: label),
            const SizedBox(height: 2),
            Text(
              reading.language == null
                  ? voices.languageName
                  : '${voices.languageName} · ${AppStrings.readAloudFromBook}',
            ),
            const SizedBox(height: 12),
            Text(AppStrings.readAloudVoice, style: label),
            RadioGroup<String?>(
              groupValue: reading.voice,
              onChanged: reading.setVoice,
              child: Column(
                children: [
                  RadioListTile<String?>(
                    key: const Key('read-aloud-voice-default'),
                    value: null,
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.readAloudDefault),
                  ),
                  for (final (index, voice) in voices.voices.indexed)
                    RadioListTile<String?>(
                      value: voice.name,
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.readAloudVoiceNumber(index + 1)),
                      subtitle: Text(
                        voice.network
                            ? AppStrings.readAloudNeedsNetwork
                            : AppStrings.readAloudOnDevice,
                      ),
                      secondary: IconButton(
                        tooltip: AppStrings.readAloudListen(
                          AppStrings.readAloudVoiceNumber(index + 1),
                        ),
                        icon: const Icon(Icons.volume_up_outlined),
                        onPressed: () => unawaited(
                          reading.engine.sample(
                            voice.name,
                            AppStrings.readAloudSample,
                            rate: reading.rate,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(AppStrings.readAloudSpeedTitle, style: label),
                ),
                Text(rate),
              ],
            ),
            Slider(
              key: const Key('read-aloud-rate'),
              value: reading.rate,
              min: EpubReadAloud.minRate,
              max: EpubReadAloud.maxRate,
              divisions: rateSteps,
              label: rate,
              onChanged: reading.setRate,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: Text(AppStrings.readAloudSettings),
                onPressed: () => unawaited(reading.engine.openSettings()),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Says the device has no voice for [language] (its name), and offers to
/// install one or to read with the default voice: true to read on.
Future<bool> showReadAloudNoVoice(
  BuildContext context,
  ReadAloudEngine engine,
  String language,
) async {
  final read = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('read-aloud-no-voice'),
      icon: const Icon(Icons.voice_over_off_outlined),
      title: Text(AppStrings.readAloudNoVoiceTitle(language)),
      content: Text(AppStrings.readAloudNoVoiceBody(language)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppStrings.readAloudUseDefault),
        ),
        FilledButton(
          onPressed: () {
            unawaited(engine.openSettings());
            Navigator.of(context).pop(false);
          },
          child: Text(AppStrings.readAloudInstallVoice),
        ),
      ],
    ),
  );
  return read ?? false;
}
