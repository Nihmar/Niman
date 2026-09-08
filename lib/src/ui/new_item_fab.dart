import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The expandable "+" FAB (T-UI-05): the main round button reveals three
/// mini FABs above it — New note, New list note and New folder — instead
/// of opening the note dialog directly. Controlled by the shell
/// ([expanded]) so it can cover the body with a tap-to-dismiss scrim
/// while the menu is open; tapping the main FAB again (or choosing an
/// action) collapses the menu.
final class NewItemFab extends StatelessWidget {
  /// Creates an expandable FAB wired to the shell's create handlers.
  ///
  /// [anchorKey] marks the main FAB's icon so [FabScrim]'s circular
  /// reveal can be centered on it.
  const new({
    required this.anchorKey,
    required this.expanded,
    required this.onToggle,
    required this.onNewNote,
    required this.onNewListNote,
    required this.onNewFolder,
    super.key,
  });

  /// Marks the main FAB (see [FabScrim]); lives in the shell so the
  /// scrim layer can find the icon's position.
  final GlobalKey anchorKey;

  /// Whether the mini FABs are revealed (the shell owns this state).
  final bool expanded;

  /// Toggles [expanded] (the main FAB's tap).
  final VoidCallback onToggle;

  /// Creates a new note in the FAB target folder.
  final VoidCallback onNewNote;

  /// Creates a new list note in the configured list folder.
  final VoidCallback onNewListNote;

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
          tooltip: AppStrings.newNoteTitle,
          open: expanded,
          onTap: onNewNote,
        ),
        const SizedBox(height: 12),
        _MiniFab(
          key: const Key('new-list-note-action'),
          icon: Icons.checklist_outlined,
          tooltip: AppStrings.newListNoteTitle,
          open: expanded,
          onTap: onNewListNote,
        ),
        const SizedBox(height: 12),
        _MiniFab(
          key: const Key('new-folder-action'),
          icon: Icons.create_new_folder_outlined,
          tooltip: AppStrings.newFolderTitle,
          open: expanded,
          onTap: onNewFolder,
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: anchorKey,
          child: FloatingActionButton(
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
        ),
      ],
    );
  }
}

/// A small FAB that scales/fades in when [open]; taps invoke [onTap].
/// Kept in the tree while closed (IgnorePointer + scale 0) so expanding
/// is a simple animation with no layout jump.
final class _MiniFab extends StatelessWidget {
  const new({
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

/// The tap-to-dismiss layer of the expanded FAB menu: a circle that
/// grows out of the main FAB icon (see [NewItemFab.anchorKey]) until it
/// covers the body, dims it, and closes the menu on any tap. Always
/// mounted; paints nothing and ignores taps while collapsed.
final class FabScrim extends StatelessWidget {
  /// Creates the FAB-menu scrim; [onClose] collapses the menu.
  const new({
    required this.anchorKey,
    required this.expanded,
    required this.onClose,
    super.key,
  });

  /// The main FAB's key (see [NewItemFab.anchorKey]).
  final GlobalKey anchorKey;

  /// Whether the FAB menu is expanded (drives the reveal).
  final bool expanded;

  /// Collapses the FAB menu (tap anywhere on the scrim).
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      key: const Key('fab-scrim'),
      ignoring: !expanded,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final center = _fabCenter(context, size);
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: expanded ? 1 : 0),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              builder: (context, progress, _) => CustomPaint(
                size: size,
                painter: _RevealPainter(center: center, progress: progress),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The main FAB icon's center, in the scrim's local coordinates.
  ///
  /// Resolved from [anchorKey] so it stays exact for any FAB location or
  /// size; the fallback is the default endFloat geometry (16 px margin,
  /// 56 px FAB) for the unlikely frame where the FAB is not laid out yet.
  ///
  /// The anchor can be defunct rather than merely absent. The shell now
  /// reuses one FAB slot across the Files and the todo tabs, so leaving
  /// Files tears this FAB down while the scrim is still laid out, and a
  /// `currentContext` that is non-null but unmounted makes
  /// `findRenderObject` assert. Hence the [BuildContext.mounted] check:
  /// the fallback is right for that frame, and the next one has no scrim.
  Offset _fabCenter(BuildContext context, Size size) {
    final anchor = anchorKey.currentContext;
    final fabBox = anchor != null && anchor.mounted
        ? anchor.findRenderObject() as RenderBox?
        : null;
    if (fabBox == null || !fabBox.hasSize) {
      return Offset(size.width - 44, size.height - 44);
    }
    final scrimBox = context.findRenderObject()! as RenderBox;
    return scrimBox.globalToLocal(
      fabBox.localToGlobal(fabBox.size.center(Offset.zero)),
    );
  }
}

/// Paints the FAB-menu scrim: a translucent circle, centered on the main
/// FAB icon, growing with [progress] (0-1) until it covers the body.
final class _RevealPainter extends CustomPainter {
  new({required this.center, required this.progress});

  final Offset center;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final maxRadius = <double>[
      center.distance,
      (center - Offset(size.width, 0)).distance,
      (center - Offset(0, size.height)).distance,
      (center - Offset(size.width, size.height)).distance,
    ].reduce((a, b) => a > b ? a : b);
    canvas.drawCircle(
      center,
      maxRadius * progress,
      Paint()..color = Colors.black26,
    );
  }

  @override
  bool shouldRepaint(_RevealPainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.progress != progress;
}
