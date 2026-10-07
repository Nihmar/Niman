import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/strings.dart';

/// A picture's text, as soon as it is read, on a phone (#595): the words
/// counted, where they were saved, the text itself, and Copy or Open
/// text — a receipt or a whiteboard is usually wanted right away.
Future<void> showOcrResultSheet(
  BuildContext context, {
  required int words,
  required String savedAs,
  required String text,
  required VoidCallback onOpen,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        key: const Key('ocr-result-sheet'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.ocrRecognized(words),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(text),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.ocrSavedAs} $savedAs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('ocr-result-copy'),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(AppStrings.ocrCopyText),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const Key('ocr-result-open'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOpen();
                    },
                    child: Text(AppStrings.ocrOpenText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
