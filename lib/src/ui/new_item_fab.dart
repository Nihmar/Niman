import 'package:flutter/material.dart';

/// The expandable "+" FAB (T-UI-05): the main round button reveals two
/// mini FABs above it — New note and New folder — instead of opening the
/// note dialog directly. Controlled by the shell ([expanded]) so it can
/// cover the body with a tap-to-dismiss scrim while the menu is open;
/// tapping the main FAB again (or choosing an action) collapses the menu.
final class NewItemFab extends StatelessWidget {
  /// Creates an expandable FAB wired to the shell's create handlers.
  const NewItemFab({
    required this.expanded,
    required this.onToggle,
    required this.onNewNote,
    required this.onNewFolder,
    super.key,
  });

  /// Whether the mini FABs are revealed (the shell owns this state).
  final bool expanded;

  /// Toggles [expanded] (the main FAB's tap).
  final VoidCallback onToggle;

  /// Creates a new note in the FAB target folder.
  final VoidCallback onNewNote;

  /// Creates a new folder in the FAB target folder.
  final VoidCallback onNewFolder;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MiniFab(
          key: const Key('new-note-action'),
          icon: Icons.note_add_outlined,
          tooltip: 'New note',
          open: expanded,
          onTap: onNewNote,
        ),
        const SizedBox(height: 12),
        _MiniFab(
          key: const Key('new-folder-action'),
          icon: Icons.create_new_folder_outlined,
          tooltip: 'New folder',
          open: expanded,
          onTap: onNewFolder,
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          key: const Key('new-note-fab'),
          tooltip: expanded ? 'Close' : 'New',
          onPressed: onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              expanded ? Icons.close : Icons.add,
              key: ValueKey(expanded),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small FAB that scales/fades in when [open]; taps invoke [onTap].
/// Kept in the tree while closed (IgnorePointer + scale 0) so expanding
/// is a simple animation with no layout jump.
final class _MiniFab extends StatelessWidget {
  const _MiniFab({
    required this.icon,
    required this.tooltip,
    required this.open,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !open,
      child: AnimatedScale(
        scale: open ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: open ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          // No hero: three FABs share the widget's default hero tag when
          // this route participates in a transition.
          child: FloatingActionButton.small(
            heroTag: null,
            tooltip: tooltip,
            onPressed: onTap,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}
