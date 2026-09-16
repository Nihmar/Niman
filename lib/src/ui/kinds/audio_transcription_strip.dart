import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The line under a clip bubble's player while its transcription is on
/// its way: what is happening, how far along, and a way to stop it.
final class AudioTranscriptionStrip extends StatelessWidget {
  /// A strip reading [label], with [progress] in 0..1 (null for a bar that
  /// only says "working", or [showBar] false for none).
  const new({
    required this.icon,
    required this.label,
    required this.onCancel,
    this.progress,
    this.showBar = true,
    super.key,
  });

  /// What kind of wait this is (download, queue, transcription).
  final IconData icon;

  /// The state in words, with its percentage.
  final String label;

  /// How far along, or null when unknown.
  final double? progress;

  /// Whether to draw the progress bar at all.
  final bool showBar;

  /// Stops the transcription.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('audio-transcription-cancel'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onCancel,
                child: Text(AppStrings.actionCancel),
              ),
            ],
          ),
          if (showBar)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress, minHeight: 3),
            ),
        ],
      ),
    );
  }
}
