import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/audio_progress_bar.dart';
import 'package:niman/src/ui/strings.dart';

/// What the composer shows while the microphone is live: a red dot, the
/// elapsed time, a pause/resume button and a button that discards the
/// recording. After stop it reads "Saving…" until the clip is in the note.
///
/// A hold on the microphone shows itself here (#737): while the finger is
/// down the bar says **Slide up to lock**, and once the slide went far
/// enough it shows the lock.
class AudioRecordingBar extends StatefulWidget {
  /// Creates the bar; the clock starts when it is first built.
  const new({
    required this.onDiscard,
    this.onPause,
    this.paused = false,
    this.saving = false,
    this.holding = false,
    this.locked = false,
    super.key,
  });

  /// Whether a press became the messenger's hold and the finger is still
  /// down (#737).
  final bool holding;

  /// Whether that hold is locked: the release leaves the recording going.
  final bool locked;

  /// Throws the recording away; null disables the button.
  final VoidCallback? onDiscard;

  /// Pauses or resumes the recording; null disables the button.
  final VoidCallback? onPause;

  /// Whether the recording is paused: the clock holds and the dot dims.
  final bool paused;

  /// Whether the stopped recording is being saved.
  final bool saving;

  @override
  State<AudioRecordingBar> createState() => _AudioRecordingBarState();
}

class _AudioRecordingBarState extends State<AudioRecordingBar>
    with SingleTickerProviderStateMixin {
  // Counted in ticks rather than read off a stopwatch, so the clock
  // follows the test binding's fake time too; ticks while paused or
  // saving are not counted.
  int _seconds = 0;
  late final Timer _tick;

  // The dot breathes while paused, so a held clock reads as a pause and
  // not as a frozen app.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || widget.paused || widget.saving) return;
      setState(() => _seconds++);
    });
    _syncBreath();
  }

  @override
  void didUpdateWidget(AudioRecordingBar old) {
    super.didUpdateWidget(old);
    if (old.paused != widget.paused || old.saving != widget.saving) {
      _syncBreath();
    }
  }

  void _syncBreath() {
    if (widget.paused && !widget.saving) {
      _breath.repeat(reverse: true);
    } else {
      _breath
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _tick.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final elapsed = formatClipTime(Duration(seconds: _seconds));
    final label = widget.saving
        ? AppStrings.audioSavingRecording
        : widget.paused
        ? '${AppStrings.audioRecordingPaused} $elapsed'
        : '${AppStrings.audioRecording} $elapsed';
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.error.withValues(alpha: widget.paused ? 0.08 : 0.16),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: widget.saving
                ? CircularProgressIndicator(
                    key: const ValueKey('audio-recording-saving'),
                    strokeWidth: 2,
                    color: colorScheme.error,
                  )
                : Center(
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: 0.25,
                        end: 1,
                      ).animate(_breath),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  key: const ValueKey('audio-recording-clock'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                // The messenger's hint, where the eye already is (#737).
                if (widget.holding && !widget.locked)
                  Row(
                    key: const ValueKey('audio-lock-hint'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        AppStrings.audioSlideUpToLock,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                else if (widget.locked)
                  Padding(
                    key: const ValueKey('audio-locked'),
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.lock, size: 18, color: colorScheme.error),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('audio-record-pause'),
            icon: Icon(widget.paused ? Icons.mic_outlined : Icons.pause),
            tooltip: widget.paused
                ? AppStrings.audioResumeRecording
                : AppStrings.audioPauseRecording,
            onPressed: widget.saving ? null : widget.onPause,
          ),
          IconButton(
            key: const Key('audio-record-discard'),
            icon: const Icon(Icons.delete_outline),
            tooltip: AppStrings.audioDiscardRecording,
            onPressed: widget.saving ? null : widget.onDiscard,
          ),
        ],
      ),
    );
  }
}
