/// A captured note's tags (#531), in the desktop's dialog and the phone's
/// sheet alike: one chip each, and a field for another.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The tags, changed in place.
final class CaptureTags extends StatelessWidget {
  /// Chips for [tags]; [onChanged] after one is added or removed.
  const new({required this.tags, required this.onChanged, super.key});

  /// The note's tags, without their `#`.
  final List<String> tags;

  /// Called after [tags] changed, to draw them.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final tag in tags)
        InputChip(
          label: Text('#$tag'),
          onDeleted: () {
            tags.remove(tag);
            onChanged();
          },
        ),
      SizedBox(
        width: 160,
        child: TextField(
          key: const Key('capture-add-tag'),
          decoration: InputDecoration(
            hintText: AppStrings.captureAddTag,
            isDense: true,
          ),
          onSubmitted: (text) {
            final tag = text.trim().replaceFirst(RegExp('^#'), '');
            if (tag.isEmpty || tags.contains(tag)) return;
            tags.add(tag);
            onChanged();
          },
        ),
      ),
    ],
  );
}
