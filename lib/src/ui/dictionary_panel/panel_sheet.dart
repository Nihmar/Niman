import 'package:flutter/material.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/ui/dictionary_panel.dart';
import 'package:niman/src/ui/dictionary_panel/lookup_session.dart';

/// The phone's panel (screen B): a modal sheet at half the window's height,
/// dragged higher to read more. Completes when it is closed.
Future<void> showDictionarySheet(
  BuildContext context, {
  required DictionaryLookupSession session,
  required DictionaryInstallation installation,
  required VoidCallback onOpenSettings,
  DictionaryAnnotate? annotate,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => DraggableScrollableSheet(
    expand: false,
    minChildSize: 0.3,
    maxChildSize: 0.92,
    builder: (context, scroll) => Column(
      key: const Key('lookup-sheet'),
      children: [
        // The grab handle; the sheet is dragged by its body.
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: DictionaryPanel(
            session: session,
            installation: installation,
            annotate: annotate,
            onClose: () => Navigator.pop(sheetContext),
            onOpenSettings: () {
              Navigator.pop(sheetContext);
              onOpenSettings();
            },
            fill: true,
            scroll: scroll,
          ),
        ),
      ],
    ),
  ),
);
