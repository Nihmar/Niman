import 'package:flutter/material.dart';

/// The Quick note tab: a scratch note at the library root, opened through
/// [onOpen] (find-or-create happens in the shell).
final class QuickNoteTab extends StatelessWidget {
  /// Creates the quick note tab.
  const QuickNoteTab({required this.onOpen, super.key});

  /// Called when the user taps "Open quick note".
  final VoidCallback onOpen;

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
              'Quick note',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'A scratch note at the library root for things to jot down '
              'without deciding where they belong. It is created the first '
              'time you open it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('quick-note-open'),
              onPressed: onOpen,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Open quick note'),
            ),
          ],
        ),
      ),
    );
  }
}
