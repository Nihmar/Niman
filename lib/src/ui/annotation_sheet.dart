/// What the reader says about a place of a PDF or a book (#284), asked
/// over the file without leaving it: a sheet above the keyboard on a
/// phone, a dialog on a wide window, as the app asks for a name.
///
/// It shows what is annotated — the place, and the passage when there is
/// one — and takes a comment, which may stay empty: a passage marked is
/// an annotation already.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show wideBreakpoint;
import 'package:niman/src/ui/strings.dart';

/// Asks for the comment on the place [label] names, [quote] its passage;
/// the comment, or null when the reader cancels.
Future<String?> showAnnotationSheet(
  BuildContext context, {
  required String label,
  String quote = '',
}) {
  final body = _AnnotationForm(label: label, quote: quote);
  if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: body,
        ),
      ),
    );
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      // Above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(child: body),
    ),
  );
}

/// The form: what is annotated, the comment, Cancel and Save. Owns the
/// [TextEditingController], so it lives as long as the route.
final class _AnnotationForm extends StatefulWidget {
  const new({required this.label, required this.quote});

  final String label;
  final String quote;

  @override
  State<_AnnotationForm> createState() => _AnnotationFormState();
}

final class _AnnotationFormState extends State<_AnnotationForm> {
  final TextEditingController _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const Key('annotation-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${AppStrings.annotateAction} · ${widget.label}',
            style: theme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.quote.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  widget.quote,
                  key: const Key('annotation-quote'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('annotation-comment'),
            controller: _comment,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: AppStrings.annotationCommentHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('annotation-cancel'),
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.actionCancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('annotation-save'),
                onPressed: () => Navigator.pop(context, _comment.text.trim()),
                child: Text(AppStrings.actionSave),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
