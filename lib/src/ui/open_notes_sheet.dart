/// The phone's open-notes switcher (issue #23, PR 4): the notes left
/// open, reached from a count badge on the note bar.
///
/// Tabs are the desktop's shape for a model that is not desktop-only:
/// more than one note open at once. A phone has room for one on screen,
/// so the others wait in a sheet — each with its folder, the unsaved dot,
/// and a close — and 0.0.7's tab bar stays gone. Same capability, not the
/// same UI.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

/// The badge: how many notes are open, opening the switcher.
final class OpenNotesButton extends StatelessWidget {
  /// A button showing [count], running [onPressed].
  const new({required this.count, required this.onPressed, super.key});

  /// How many notes are open.
  final int count;

  /// Opens the switcher.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('open-notes'),
    tooltip: AppStrings.openNotesTooltip,
    onPressed: onPressed,
    icon: Badge.count(
      count: count,
      child: const Icon(Icons.filter_none_outlined),
    ),
  );
}

/// Shows the switcher over [context]. [workspace] is read again on every
/// one of [changes], so a close redraws the list in place.
Future<void> showOpenNotesSheet(
  BuildContext context, {
  required Workspace Function() workspace,
  required Listenable changes,
  required Set<String> Function() unsaved,
  required String? Function() shown,
  required ValueChanged<String> onOpen,
  required ValueChanged<String> onClose,
  required VoidCallback onCloseAll,
  required VoidCallback onNewNote,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => ListenableBuilder(
      listenable: changes,
      builder: (sheet, _) {
        final theme = Theme.of(sheet);
        final tabs = workspace().tabs.toList();
        final dirty = unsaved();
        final current = shown();
        void done(VoidCallback action) {
          Navigator.pop(sheet);
          action();
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheet).height * 0.7,
            ),
            child: Column(
              key: const Key('open-notes-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.openNotesTooltip,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tabs.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (tabs.isNotEmpty)
                        TextButton(
                          key: const Key('open-notes-close-all'),
                          onPressed: () => done(onCloseAll),
                          child: Text(AppStrings.closeAllNotes),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final (i, tab) in tabs.indexed)
                        _OpenNoteRow(
                          key: Key('open-note-$i'),
                          index: i,
                          path: tab.path,
                          current: tab.path == current,
                          unsaved: dirty.contains(tab.path),
                          onOpen: () => done(() => onOpen(tab.path)),
                          onClose: () {
                            onClose(tab.path);
                            // Nothing left to switch between.
                            if (tabs.length == 1) Navigator.pop(sheet);
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  key: const Key('open-notes-new'),
                  leading: Icon(Icons.add, color: theme.colorScheme.primary),
                  title: Text(
                    AppStrings.newNoteTitle,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  onTap: () => done(onNewNote),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// One open note in the switcher.
final class _OpenNoteRow extends StatelessWidget {
  const new({
    required this.index,
    required this.path,
    required this.current,
    required this.unsaved,
    required this.onOpen,
    required this.onClose,
    super.key,
  });

  final int index;
  final String path;
  final bool current;
  final bool unsaved;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folder = p.posix.dirname(path);
    return Material(
      color: current ? scheme.surfaceContainerHighest : Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: current ? scheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(17, 6, 8, 6),
          child: Row(
            children: [
              Icon(
                current ? Icons.description : Icons.description_outlined,
                color: current ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noteTabLabel(path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      folder == '.' ? AppStrings.libraryRoot : folder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (unsaved)
                Container(
                  key: Key('open-note-dot-$index'),
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: scheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              IconButton(
                key: Key('open-note-close-$index'),
                tooltip: AppStrings.closeTabTooltip,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
