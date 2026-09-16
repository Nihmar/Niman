import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// What the menu of a clip bubble can do.
enum _ClipAction { transcribe, title, description, rename, delete }

/// The ⋮ menu of a clip bubble: transcribe, title, description, rename,
/// delete, under the file name.
///
/// [AudioClipMenuState.show] opens it from elsewhere (the bubble's long
/// press and right click). Item keys end with [suffix]: `audio-title-0`,
/// `audio-transcribe-0`, …
final class AudioClipMenu extends StatefulWidget {
  /// Creates the menu of the clip [fileName].
  const new({
    required this.suffix,
    required this.fileName,
    required this.onEditTitle,
    required this.onEditDescription,
    required this.onDelete,
    this.onRename,
    this.onTranscribe,
    this.transcribeHint,
    super.key,
  });

  /// The key suffix naming this clip among the note's clips.
  final String suffix;

  /// The audio file name, shown atop the menu.
  final String fileName;

  /// Opens the title editor.
  final VoidCallback onEditTitle;

  /// Opens the description editor.
  final VoidCallback onEditDescription;

  /// Deletes the clip from the note.
  final VoidCallback onDelete;

  /// Renames the audio file; null hides the action.
  final VoidCallback? onRename;

  /// Transcribes the clip; null greys the action out when
  /// [transcribeHint] is set.
  final VoidCallback? onTranscribe;

  /// The line under "Transcribe" (model and language, or why it cannot);
  /// null hides the action.
  final String? transcribeHint;

  @override
  State<AudioClipMenu> createState() => AudioClipMenuState();
}

/// The state behind [AudioClipMenu], which can open it.
final class AudioClipMenuState extends State<AudioClipMenu> {
  final GlobalKey<PopupMenuButtonState<_ClipAction>> _button = GlobalKey();

  /// Opens the menu.
  void show() => _button.currentState?.showButtonMenu();

  void _run(_ClipAction action) {
    switch (action) {
      case _ClipAction.transcribe:
        widget.onTranscribe?.call();
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
    String? subtitle,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    return PopupMenuItem<_ClipAction>(
      key: ValueKey('audio-$key-${widget.suffix}'),
      value: action,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: color == null ? null : TextStyle(color: color),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<_ClipAction>> _items(BuildContext context) {
    final theme = Theme.of(context);
    final hint = widget.transcribeHint;
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
      if (hint != null)
        _item(
          _ClipAction.transcribe,
          'transcribe',
          Icons.subtitles_outlined,
          AppStrings.audioTranscribe,
          subtitle: hint,
          enabled: widget.onTranscribe != null,
        ),
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
    return PopupMenuButton<_ClipAction>(
      key: _button,
      tooltip: AppStrings.audioMoreActions,
      icon: Icon(
        Icons.more_vert,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        key: ValueKey('audio-menu-${widget.suffix}'),
      ),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onSelected: _run,
      itemBuilder: _items,
    );
  }
}
