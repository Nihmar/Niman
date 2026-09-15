import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/audio_progress_bar.dart';
import 'package:niman/src/ui/strings.dart';

/// What the composer shows while the microphone is live: a red dot, the
/// elapsed time and a button that discards the recording.
class AudioRecordingBar extends StatefulWidget {
  /// Creates the bar; the clock starts when it is first built.
  const new({required this.onDiscard, super.key});

  /// Throws the recording away; null disables the button.
  final VoidCallback? onDiscard;

  @override
  State<AudioRecordingBar> createState() => _AudioRecordingBarState();
}

class _AudioRecordingBarState extends State<AudioRecordingBar> {
  // Counted in ticks rather than read off a stopwatch, so the clock
  // follows the test binding's fake time too.
  int _seconds = 0;
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final elapsed = formatClipTime(Duration(seconds: _seconds));
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.error.withValues(alpha: 0.16),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${AppStrings.audioRecording} $elapsed',
              key: const ValueKey('audio-recording-clock'),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            key: const Key('audio-record-discard'),
            icon: const Icon(Icons.delete_outline),
            tooltip: AppStrings.audioDiscardRecording,
            onPressed: widget.onDiscard,
          ),
        ],
      ),
    );
  }
}
