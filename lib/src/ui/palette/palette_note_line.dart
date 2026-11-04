import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:path/path.dart' as p;

/// One note in the palette: its name, and the folder it is in.
final class PaletteNoteLine extends StatelessWidget {
  /// The line of the note at library-relative [path].
  const new({required this.path, super.key});

  /// The note.
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = p.posix.basename(path);
    final folder = p.posix.dirname(path);
    return Row(
      children: [
        Icon(
          Icons.description_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            isMarkdownNote(name) ? name.substring(0, name.length - 3) : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (folder != '.') ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              folder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
