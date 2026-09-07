import 'dart:async';

import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/name_dialog.dart';
import 'package:copist/src/ui/quick_note_picker.dart';
import 'package:flutter/material.dart';

/// The Quick note tab.
///
/// No note is opened by default: the user either picks an existing note
/// from the tree dialog or creates a new one (named as they like). Both
/// actions set the quick note and open it through [onOpen].
final class QuickNoteTab extends StatefulWidget {
  /// Creates the quick note tab.
  const QuickNoteTab({
    required this.controller,
    required this.onOpen,
    super.key,
  });

  /// The session providing the current quick-note path and the ops.
  final LibrarySession controller;

  /// Called with the note path once the user opens the quick note.
  final ValueChanged<String> onOpen;

  @override
  State<QuickNoteTab> createState() => _QuickNoteTabState();
}

final class _QuickNoteTabState extends State<QuickNoteTab> {
  Future<String?>? _path;
  int? _pathRevision;

  /// The quick-note path for [revision], only re-queried when the index
  /// revision moved.
  Future<String?> _pathFor(int revision) {
    final cached = _path;
    if (cached != null && revision == _pathRevision) return cached;
    _pathRevision = revision;
    return _path = _read();
  }

  Future<String?> _read() async => widget.controller.ops?.quickNotePath;

  /// Choose an existing note in the tree dialog (T-UI-10 follow-up).
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
      title: 'New quick note',
      initial: 'Quick note',
    );
    if (name == null || name.isEmpty || !mounted) return;
    final row = await ops.createNote(parentPath: '', name: name);
    await ops.setQuickNotePath(path: row.path);
    if (!mounted) return;
    widget.onOpen(row.path);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: widget.controller.events,
      initialData: widget.controller.revision,
      builder: (context, snapshot) => FutureBuilder<String?>(
        future: _pathFor(snapshot.data ?? widget.controller.revision),
        builder: (context, snap) {
          final path = snap.data;
          if (path == null) return _empty(context);
          return _withNote(context, path);
        },
      ),
    );
  }

  /// Nothing set yet: the user must choose or create the quick note.
  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Quick note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No quick note yet. Choose an existing note, or create a new '
              'one — the quick note opens here.',
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
              label: const Text('Choose a note…'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('quick-note-create'),
              onPressed: _create,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Create a new note…'),
            ),
          ],
        ),
      ),
    );
  }

  /// A quick note is set: show its path, offer open/change/create.
  Widget _withNote(BuildContext context, String path) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Quick note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              path,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('quick-note-open'),
              onPressed: () => widget.onOpen(path),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Open quick note'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('quick-note-choose'),
              onPressed: _choose,
              child: const Text('Choose a different note…'),
            ),
            TextButton(
              key: const Key('quick-note-create'),
              onPressed: _create,
              child: const Text('Create a new note…'),
            ),
          ],
        ),
      ),
    );
  }
}
