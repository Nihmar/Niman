/// The open note's header in the detail pane (issue #100, split out of
/// `shell.dart`; T-PP-22): the file name and its folder, then the note
/// controls that used to sit in the wide app bar.
library;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// The bar above the open note. Only mounted while a note is open.
final class EditorHeaderBar extends StatelessWidget {
  /// Creates the header for the note at [path] (library-relative).
  const new({required this.path, required this.actions, super.key});

  /// The open note's path: its base name titles the header, its folder
  /// follows in a lighter hand.
  final String path;

  /// The note's own controls, right-aligned — the kind actions and the
  /// ⋮ menu the shell builds.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final folder = p.dirname(path);
    final theme = Theme.of(context);
    return Container(
      key: const Key('editor-header'),
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // The title takes the whole free width so the actions sit at
          // the right edge. A `Spacer` beside the flexible texts used to
          // split that width with them, which left the ⋮ stranded in the
          // middle of the header whenever the name was short.
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    p.basename(path),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (folder.isNotEmpty && folder != '.') ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      folder,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
