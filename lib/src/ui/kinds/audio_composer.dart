import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/audio_recording_bar.dart';
import 'package:niman/src/ui/strings.dart';

/// The bottom bar of an audio note: one rounded field to write a note,
/// with the attach button inside it, and one round button beside it.
///
/// The round button is the microphone while the field is empty and
/// becomes send as soon as there is text; while recording it is a red
/// stop and the field gives way to [AudioRecordingBar].
class AudioComposer extends StatelessWidget {
  /// Creates the composer.
  const new({
    required this.controller,
    required this.recording,
    required this.onRecord,
    required this.onSend,
    required this.onImport,
    required this.onDiscard,
    required this.stopSwell,
    this.paused = false,
    this.saving = false,
    this.onPause,
    super.key,
  });

  /// The written-note field's text.
  final TextEditingController controller;

  /// Whether the microphone is live.
  final bool recording;

  /// Starts or stops the recording; null disables it.
  final VoidCallback? onRecord;

  /// Sends the typed note.
  final VoidCallback onSend;

  /// Picks an audio file to attach; null disables it.
  final VoidCallback? onImport;

  /// Throws the live recording away; null disables it.
  final VoidCallback? onDiscard;

  /// The one-shot swell of the stop button when recording starts.
  final Animation<double> stopSwell;

  /// Whether the live recording is paused.
  final bool paused;

  /// Whether the stopped recording is still being saved: the bar stays,
  /// and the stop button spins instead of going grey.
  final bool saving;

  /// Pauses or resumes the recording; null disables it.
  final VoidCallback? onPause;

  Widget _field(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      key: const ValueKey('audio-compose-field'),
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 4, right: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            key: const Key('audio-import-button'),
            icon: const Icon(Icons.attach_file),
            color: colorScheme.onSurfaceVariant,
            tooltip: AppStrings.audioImport,
            onPressed: onImport,
          ),
          Expanded(
            child: TextField(
              key: const Key('audio-message-field'),
              controller: controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: AppStrings.audioMessageHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One round button in three roles (mic, send, stop): only its icon
  /// and color change, so the control never doubles up mid-animation.
  Widget _roundButton(BuildContext context, bool typing) {
    final colorScheme = Theme.of(context).colorScheme;
    final Icon icon;
    if (saving) {
      icon = Icon(
        Icons.stop,
        key: const ValueKey('audio-icon-saving'),
        color: colorScheme.onError.withValues(alpha: 0),
      );
    } else if (recording) {
      icon = const Icon(Icons.stop, key: ValueKey('audio-icon-stop'));
    } else if (typing) {
      icon = const Icon(Icons.send, key: ValueKey('audio-icon-send'));
    } else {
      icon = const Icon(Icons.mic_outlined, key: ValueKey('audio-icon-mic'));
    }
    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 0.4),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 0.6),
      ]).animate(stopSwell),
      child: IconButton.filled(
        key: Key(typing ? 'audio-send-button' : 'audio-record-button'),
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          backgroundColor: recording ? colorScheme.error : null,
          foregroundColor: recording ? colorScheme.onError : null,
          // Saving keeps the red: a disabled grey flash between stop and
          // the clip landing read as a stutter.
          disabledBackgroundColor: recording ? colorScheme.error : null,
          disabledForegroundColor: recording ? colorScheme.onError : null,
        ),
        tooltip: recording
            ? AppStrings.audioStop
            : typing
            ? AppStrings.audioSend
            : AppStrings.audioRecord,
        onPressed: saving ? null : (typing ? onSend : onRecord),
        icon: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: icon,
            ),
            if (saving)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onError,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final typing = !recording && value.text.trim().isNotEmpty;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: recording
                    ? AudioRecordingBar(
                        key: const ValueKey('audio-recording-bar'),
                        onDiscard: onDiscard,
                        onPause: onPause,
                        paused: paused,
                        saving: saving,
                      )
                    : _field(context),
              ),
            ),
            const SizedBox(width: 8),
            _roundButton(context, typing),
          ],
        );
      },
    );
  }
}
