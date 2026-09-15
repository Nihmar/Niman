import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// What the menu of a written-note bubble can do.
enum _NoteAction { edit, delete }

/// A written note on the right of the chat, as tall as its text.
///
/// A tap edits the note; a long press or a right click opens its menu
/// (edit, delete). Keys end with [suffix]: `audio-note-edit-0`,
/// `audio-note-delete-0`.
class AudioTextBubble extends StatefulWidget {
  /// Creates the bubble.
  const new({
    required this.suffix,
    required this.text,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// The key suffix naming this note among the note's written notes.
  final String suffix;

  /// The note text as written.
  final String text;

  /// Opens the note editor.
  final VoidCallback onEdit;

  /// Deletes the note.
  final VoidCallback onDelete;

  @override
  State<AudioTextBubble> createState() => _AudioTextBubbleState();
}

class _AudioTextBubbleState extends State<AudioTextBubble> {
  Offset _pressedAt = Offset.zero;

  Future<void> _openMenu() async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final theme = Theme.of(context);
    final action = await showMenu<_NoteAction>(
      context: context,
      position: RelativeRect.fromRect(
        _pressedAt & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          key: ValueKey('audio-note-edit-${widget.suffix}'),
          value: _NoteAction.edit,
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  AppStrings.audioEditNote,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          key: ValueKey('audio-note-delete-${widget.suffix}'),
          value: _NoteAction.delete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  AppStrings.audioDeleteNote,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case _NoteAction.edit:
        widget.onEdit();
      case _NoteAction.delete:
        widget.onDelete();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // A tint of the accent over the ground: the written notes are the
    // person's own voice in the chat, set apart from the recordings.
    final tint = Color.alphaBlend(
      colorScheme.primary.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.28 : 0.16,
      ),
      colorScheme.surface,
    );
    const radius = BorderRadius.only(
      topLeft: Radius.circular(18),
      topRight: Radius.circular(18),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(6),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = (constraints.maxWidth * 0.8).clamp(0.0, 420.0);
        return Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: tint,
                borderRadius: radius,
                child: InkWell(
                  borderRadius: radius,
                  onTap: widget.onEdit,
                  onTapDown: (details) => _pressedAt = details.globalPosition,
                  onLongPress: () => unawaited(_openMenu()),
                  onSecondaryTapDown: (details) {
                    _pressedAt = details.globalPosition;
                    unawaited(_openMenu());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      widget.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
