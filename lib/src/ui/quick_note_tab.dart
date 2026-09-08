import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/name_dialog.dart';
import 'package:copist/src/ui/quick_note_picker.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The Quick note tab: the setup screen shown while no quick note is set.
///
/// Nothing is opened or created by default: the user either picks an
/// existing note from the tree dialog or creates a new one (named as they
/// like). Both set the quick note and open it through [onOpen]. Once a
/// quick note is set, the bottom-nav tile opens it directly — this body is
/// not shown anymore.
final class QuickNoteTab extends StatefulWidget {
  /// Creates the quick note tab.
  const QuickNoteTab({
    required this.controller,
    required this.onOpen,
    super.key,
  });

  /// The session providing the ops.
  final LibrarySession controller;

  /// Called with the note path once the user opens the quick note.
  final ValueChanged<String> onOpen;

  @override
  State<QuickNoteTab> createState() => _QuickNoteTabState();
}

final class _QuickNoteTabState extends State<QuickNoteTab> {
  /// Choose an existing note in the tree dialog.
  Future<void> _choose() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final current = await ops.quickNotePath;
    if (!mounted) return;
    final changed = await showQuickNotePicker(
      context,
      controller: widget.controller,
      currentPath: current,
    );
    if (!mounted || !changed) return;
    final path = await ops.quickNotePath;
    if (path != null) widget.onOpen(path);
  }

  /// Create a new note (named by the user) at the library root and use it.
  Future<void> _create() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final name = await showNameDialog(
      context,
      title: AppStrings.quickNoteNewTitle,
      initial: AppStrings.quickNoteTitle,
    );
    if (name == null || name.isEmpty || !mounted) return;
    final row = await ops.createNote(parentPath: '', name: name);
    await ops.setQuickNotePath(path: row.path);
    if (!mounted) return;
    widget.onOpen(row.path);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              AppStrings.quickNoteTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.quickNoteEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('quick-note-choose'),
              onPressed: _choose,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(AppStrings.quickNoteChooseAction),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('quick-note-create'),
              onPressed: _create,
              icon: const Icon(Icons.note_add_outlined),
              label: Text(AppStrings.quickNoteCreateAction),
            ),
          ],
        ),
      ),
    );
  }
}
