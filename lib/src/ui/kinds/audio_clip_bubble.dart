import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/audio_progress_bar.dart';
import 'package:niman/src/ui/strings.dart';

/// What the menu of a clip bubble can do.
enum _ClipAction { title, description, rename, delete }

/// A voice clip on the left of the chat: its title, a round play/pause
/// button with the progress track and times, and its description.
///
/// The per-clip actions (title, description, rename, delete) live in the
/// ⋮ menu, which a long press or a right click also opens, so the bubble
/// itself carries only what is read and played. Keys end with [suffix]:
/// `audio-play-0`, `audio-menu-0`, `audio-delete-0`, …
class AudioClipBubble extends StatefulWidget {
  /// Creates the bubble.
  const new({
    required this.suffix,
    required this.title,
    required this.fallbackTitle,
    required this.description,
    required this.fileName,
    required this.active,
    required this.playing,
    required this.position,
    required this.length,
    required this.onPlay,
    required this.onSeek,
    required this.onEditTitle,
    required this.onEditDescription,
    required this.onDelete,
    this.onRename,
    super.key,
  });

  /// The key suffix naming this clip among the note's clips.
  final String suffix;

  /// The clip title (may be empty).
  final String title;

  /// What stands in for an empty [title] (`Recording 2`).
  final String fallbackTitle;

  /// The clip description (may be empty).
  final String description;

  /// The audio file name, shown atop the menu.
  final String fileName;

  /// Whether the clip is loaded in the player (playing or paused).
  final bool active;

  /// Whether the clip is playing right now.
  final bool playing;

  /// The playback position (meaningful while [active]).
  final Duration position;

  /// The clip length, when known.
  final Duration? length;

  /// Plays, pauses or resumes the clip.
  final VoidCallback onPlay;

  /// Seeks the loaded clip to a fraction of its length.
  final ValueChanged<double> onSeek;

  /// Opens the title editor.
  final VoidCallback onEditTitle;

  /// Opens the description editor.
  final VoidCallback onEditDescription;

  /// Deletes the clip from the note.
  final VoidCallback onDelete;

  /// Renames the audio file; null hides the action.
  final VoidCallback? onRename;

  @override
  State<AudioClipBubble> createState() => _AudioClipBubbleState();
}

class _AudioClipBubbleState extends State<AudioClipBubble> {
  final GlobalKey<PopupMenuButtonState<_ClipAction>> _menu = GlobalKey();

  void _run(_ClipAction action) {
    switch (action) {
      case _ClipAction.title:
        widget.onEditTitle();
      case _ClipAction.description:
        widget.onEditDescription();
      case _ClipAction.rename:
        widget.onRename?.call();
      case _ClipAction.delete:
        widget.onDelete();
    }
  }

  PopupMenuItem<_ClipAction> _item(
    _ClipAction action,
    String key,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<_ClipAction>(
      key: ValueKey('audio-$key-${widget.suffix}'),
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: color == null ? null : TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<_ClipAction>> _items(BuildContext context) {
    final theme = Theme.of(context);
    return [
      PopupMenuItem<_ClipAction>(
        enabled: false,
        height: 32,
        child: Text(
          widget.fileName,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const PopupMenuDivider(),
      _item(_ClipAction.title, 'title', Icons.title, AppStrings.audioEditTitle),
      _item(
        _ClipAction.description,
        'description',
        Icons.notes,
        AppStrings.audioEditDescription,
      ),
      if (widget.onRename != null)
        _item(
          _ClipAction.rename,
          'rename',
          Icons.drive_file_rename_outline,
          AppStrings.audioRename,
        ),
      _item(
        _ClipAction.delete,
        'delete',
        Icons.delete_outline,
        AppStrings.audioDelete,
        color: theme.colorScheme.error,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final length = widget.length;
    final hasTitle = widget.title.trim().isNotEmpty;
    final progress = widget.active && length != null && length > Duration.zero
        ? widget.position.inMicroseconds / length.inMicroseconds
        : 0.0;
    final timeStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.85).clamp(0.0, 380.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: () => _menu.currentState?.showButtonMenu(),
            onSecondaryTap: () => _menu.currentState?.showButtonMenu(),
            child: Container(
              width: width,
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasTitle ? widget.title : widget.fallbackTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: hasTitle
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                        ),
                      ),
                      PopupMenuButton<_ClipAction>(
                        key: _menu,
                        tooltip: AppStrings.audioMoreActions,
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                          key: ValueKey('audio-menu-${widget.suffix}'),
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onSelected: _run,
                        itemBuilder: _items,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        IconButton.filled(
                          key: ValueKey('audio-play-${widget.suffix}'),
                          iconSize: 26,
                          style: IconButton.styleFrom(
                            fixedSize: const Size(44, 44),
                            minimumSize: const Size(44, 44),
                          ),
                          tooltip: widget.playing
                              ? AppStrings.audioPause
                              : AppStrings.audioPlay,
                          onPressed: widget.onPlay,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              widget.playing ? Icons.pause : Icons.play_arrow,
                              key: ValueKey(widget.playing),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AudioProgressBar(
                                key: ValueKey(
                                  'audio-progress-${widget.suffix}',
                                ),
                                value: progress,
                                active: widget.active,
                                onSeek: widget.active && length != null
                                    ? widget.onSeek
                                    : null,
                              ),
                              Row(
                                children: [
                                  Text(
                                    formatClipTime(
                                      widget.active
                                          ? widget.position
                                          : Duration.zero,
                                    ),
                                    style: timeStyle,
                                  ),
                                  const Spacer(),
                                  Text(
                                    length == null
                                        ? '--:--'
                                        : formatClipTime(length),
                                    key: ValueKey(
                                      'audio-length-${widget.suffix}',
                                    ),
                                    style: timeStyle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.description.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                      child: Text(
                        widget.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
