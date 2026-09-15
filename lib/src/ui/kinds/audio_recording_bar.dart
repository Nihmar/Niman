import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/audio_progress_bar.dart';
import 'package:niman/src/ui/strings.dart';

/// What the composer shows while the microphone is live: a red dot, the
/// elapsed time, a pause/resume button and a button that discards the
/// recording. After stop it reads "Saving…" until the clip is in the note.
class AudioRecordingBar extends StatefulWidget {
  /// Creates the bar; the clock starts when it is first built.
  const new({
    required this.onDiscard,
    this.onPause,
    this.paused = false,
    this.saving = false,
    super.key,
  });

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
            child: Text(
              label,
              key: const ValueKey('audio-recording-clock'),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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
